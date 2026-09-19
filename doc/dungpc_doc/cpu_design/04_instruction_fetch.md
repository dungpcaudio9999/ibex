# 04 — Instruction Fetch: PC, fetch và IF/ID register

## 1. Trách nhiệm của `ibex_if_stage`

IF stage thực hiện sáu việc:

1. chọn next PC;
2. phát/nhận instruction-memory transaction qua I-cache hoặc prefetch buffer;
3. kiểm tra bus error, integrity, PMP và CHERIoT PCC;
4. giải nén instruction 16-bit thành 32-bit;
5. tùy chọn chèn dummy instruction và branch prediction;
6. giữ instruction/PC/metadata trong IF/ID register đến khi ID nhận.

Điểm quan trọng: PC request, PC của instruction đang ở đầu fetch, và `pc_id`
không nhất thiết giống nhau trong cùng một chu kỳ.

## 2. PC selection

`pc_mux_internal` chọn một trong:

| Selector | Nguồn địa chỉ |
|---|---|
| `PC_BOOT` | `{boot_addr_i[31:8], 8'h80}` |
| `PC_JUMP` | `branch_target_ex_i` |
| `PC_EXC` | exception/debug vector |
| `PC_ERET` | `csr_mepc_i` |
| `PC_DRET` | `csr_depc_i` |
| `PC_BP` | target dự đoán |

Khi branch predictor bật, dự đoán taken có thể override mux ngoài nếu chưa có
`pc_set_i`. Khi predictor tắt, `PC_BP` không phải đường runtime hợp lệ.

Địa chỉ redirect được ép bit 0 về 0 trước khi đưa vào prefetch/cache. Đây là
alignment tối thiểu của ISA có compressed instruction.

## 3. Exception vector

IF nhận `exc_pc_mux_i`:

- `EXC_PC_EXC`: exception vector;
- `EXC_PC_IRQ`: interrupt vector;
- `EXC_PC_DBD`: debug halt address;
- `EXC_PC_DBG_EXC`: debug exception address.

Trong RV32 mode, `mtvec` dùng layout/vectoring theo implementation Ibex. Trong
CHERIoT mode, target được ép direct `{mtvec[31:2], 2'b00}` cho cả exception và
interrupt.

## 4. I-cache hoặc prefetch buffer

### 4.1 `ICache=1`

Instantiate `ibex_icache`. Khối này:

- lookup hai way;
- quản lý fill buffer;
- giao tiếp RAM tag/data ở `ibex_top`;
- kiểm ECC nếu bật;
- xử lý invalidate và scramble-key lifecycle.

`icache_enable_i` là enable runtime; parameter `ICache` mới quyết định phần cứng
có tồn tại hay không.

### 4.2 `ICache=0`

Instantiate `ibex_prefetch_buffer`. Nó không phải cache kiến trúc; nó buffer
fetch và ghép hai word khi instruction 32-bit bắt đầu ở địa chỉ `...2`.

Các profile FX1 hiện dùng nhánh này. Các port RAM/cache được tie-off, nhưng DPI
stub scramble vẫn được khai báo trong simulation để tránh lỗi link testbench.

## 5. Fetch handshake

Chuỗi khái niệm:

```text
controller instr_req
  -> prefetch/cache request
  -> instr_req_o/address
  -> grant
  -> response data/error
  -> fetch_valid_raw
  -> fetch_valid sau squash
  -> IF/ID write
```

`fetch_ready` phụ thuộc `id_in_ready_i`, dummy insertion và redirect. Nếu ID
stall, IF phải giữ instruction hợp lệ hoặc giữ nó trong buffer mà không làm mất
response.

## 6. Compressed và Zcmp expansion

`ibex_compressed_decoder` luôn tạo instruction 32-bit cho decoder chính. Với
`RV32ZC` có Zcmp, một instruction như `cm.push`/`cm.pop` có thể bung thành nhiều
micro-op qua FSM:

```text
CmIdle
 -> CmPushStoreReg / CmPushDecrSp
 -> ...
 -> CmIdle
```

Metadata `instr_gets_expanded` phân biệt:

- không expansion;
- micro-op trung gian;
- micro-op cần commit nguyên tử;
- micro-op cuối.

Khi exception redirect xảy ra, `flush_expanded` đưa FSM expansion về idle để
không phát nốt micro-op của instruction đã bị hủy.

Với các profile FX1 chỉ có `RV32Zca`, đường Zcmp không hoạt động.

## 7. Kiểm tra lỗi fetch

`if_instr_err` là hợp của:

```text
bus error
| instruction integrity error
| PMP error tại PC
| PMP error tại PC+2 cho instruction 32-bit lệch word
| CHERIoT PCC permission violation
| CHERIoT PCC bounds violation
```

`instr_fetch_err_plus2` ghi nhận lỗi ở nửa sau của instruction 32-bit để
controller đặt `mtval` đúng địa chỉ.

## 8. CHERIoT PCC checks

Khi runtime CHERIoT bật và không ở debug mode, IF kiểm:

- PC không thấp hơn `PCC.base`;
- còn đủ headroom 2 byte cho compressed hoặc 4 byte cho instruction thường;
- capability hợp lệ, unsealed và có quyền execute.

Trường hợp toàn bộ không gian 32-bit được cho phép có xử lý wraparound riêng.
Khi chỉ còn quyền fetch 2 byte, fetch logic có thể bị ép xử lý uncached để giữ
timing không phụ thuộc dữ liệu/quyền.

Fault được register cùng instruction vào ID; controller sau đó đổi thành
`ExcCauseCheriFault` và mã hóa nguyên nhân vào `mtval`.

## 9. Dummy instruction

Nếu `DummyInstructions=1`, `ibex_dummy_instr` dùng LFSR và CSR controls để chèn
instruction giả. Khi chèn:

- instruction thật trong fetch bị giữ;
- dummy không mang fetch error/compressed metadata;
- PC dummy khớp instruction thật kế tiếp;
- dummy marker đi tới WB để ngăn thay đổi architectural state không mong muốn.

Các profile FX1 DEV/PROD override tính năng này về 0; OpenTitan bật theo mặc
định secure.

## 10. IF/ID register

Valid equation cốt lõi:

```text
instr_valid_id_d =
    (if_instr_valid && id_in_ready && !pc_set)
  | (instr_valid_id_q && !instr_valid_clear)
```

Nghĩa là:

- nhận instruction mới khi ID ready và không redirect;
- nếu chưa bị ID clear thì giữ instruction cũ;
- redirect không được cho instruction sai-path vào ID.

Payload chỉ cập nhật khi `if_id_pipe_reg_we`. Với `ResetAll=0`, một số payload
flop không reset; valid bit reset về 0 bảo đảm payload X không được tiêu thụ
trước khi có dữ liệu hợp lệ. Lockstep vẫn cần chứng minh main/shadow xử lý các
bit không reset nhất quán.

## 11. PC increment check

Khi `PCIncrCheck=1`, IF lưu địa chỉ dự kiến của instruction tuần tự tiếp theo
(`PC+2` hoặc `PC+4`) và so với PC thực tế. Redirect hợp lệ tắt điều kiện so sánh.
Mismatch tạo `pc_mismatch_alert_o`, đi vào major internal alert.

## 12. Tín hiệu nên xem

```text
pc_mux_i, pc_set_i, fetch_addr_n
instr_req_o, instr_gnt_i, instr_rvalid_i, instr_addr_o
fetch_valid, fetch_ready, fetch_addr
instr_decompressed, instr_is_compressed, illegal_c_insn
instr_valid_id_q, if_id_pipe_reg_we, pc_id_o
instr_fetch_err_o, instr_fetch_err_plus2_o
cheriot_acc_vio, cheriot_bound_vio
icache_inval_i, icache_ecc_error_o
```

## 13. Điểm vào source

- [`rtl/ibex_if_stage.sv`](../../../rtl/ibex_if_stage.sv)
- [`rtl/ibex_prefetch_buffer.sv`](../../../rtl/ibex_prefetch_buffer.sv)
- [`rtl/ibex_fetch_fifo.sv`](../../../rtl/ibex_fetch_fifo.sv)
- [`rtl/ibex_icache.sv`](../../../rtl/ibex_icache.sv)
- [`rtl/ibex_compressed_decoder.sv`](../../../rtl/ibex_compressed_decoder.sv)
- [`rtl/ibex_dummy_instr.sv`](../../../rtl/ibex_dummy_instr.sv)

