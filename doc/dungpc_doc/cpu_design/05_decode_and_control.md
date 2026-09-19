# 05 — Decode, controller, hazard và stall

## 1. Hai module có vai trò khác nhau

Trong ID stage:

- `ibex_decoder` dịch instruction bits thành control signals;
- `ibex_controller` quyết định CPU có được chạy, giữ, flush, redirect, vào
  exception/interrupt/debug hay sleep;
- `ibex_id_stage` ghép decoder/controller với RF operands, immediate mux,
  forwarding, hazard và FSM multi-cycle.

Decoder trả lời “instruction muốn làm gì”; controller và ID logic trả lời “nó
có được làm việc đó ở chu kỳ này không”.

## 2. Decode outputs

Các nhóm output chính:

- RF read/write addresses và enables;
- ALU operator, operand selectors và immediate selectors;
- branch/jump controls;
- MUL/DIV controls;
- LSU request, width, sign extension và write data;
- CSR access/op/address;
- illegal instruction;
- CHERIoT operation one-hot và capability controls.

`instr_rdata_i` và bản sao `instr_rdata_alu_i` phải giống hệt; bản sao tồn tại để
giảm fan-out vật lý trên các bit đi tới ALU decode.

## 3. Operand generation

Operand A có thể đến từ:

- register A;
- địa chỉ LSU trước cho access lệch hàng;
- current PC;
- immediate A.

Operand B là register B hoặc immediate B. Immediate B có các dạng I/S/B/U/J,
PC increment và address increment.

Branch-target ALU có mux operand riêng để target addition không tranh ALU chính
với compare hoặc link-address calculation.

## 4. Forwarding và load-use hazard

Khi có WB stage:

```text
match_a = (rf_waddr_wb == rf_raddr_a) && rf_raddr_a != 0
match_b = (rf_waddr_wb == rf_raddr_b) && rf_raddr_b != 0
```

Nếu WB đã có data, mux dùng `rf_wdata_fwd_wb`. Nếu WB đang giữ một load chưa có
response, data chưa thể forward và ID phát:

```text
stall_ld_hz = outstanding_load_wb && (hazard_a || hazard_b)
```

Capability metadata có đường forwarding tương ứng trong `ibex_cheriot_ex`.

## 5. FSM cục bộ ID/EX

FSM chỉ có hai state:

- `FIRST_CYCLE`;
- `MULTI_CYCLE`.

Một instruction vào `MULTI_CYCLE` khi LSU request chưa xong, MUL/DIV chưa valid,
branch/jump cần chu kỳ thứ hai, hoặc ALU operation cần intermediate state.

State chỉ update khi `instr_executing`; một instruction chưa được phép bắt đầu có
thể nằm ở `FIRST_CYCLE` nhiều chu kỳ mà không bị hiểu nhầm là đang thực thi lại.

### Branch

- có BT-ALU, branch not taken thường không stall;
- taken branch thường redirect với chi phí điều khiển;
- khi data-independent timing bật, mọi branch dùng timing cố định, kể cả không
  taken.

### Jump

- BT-ALU bật: target có thể sẵn sàng ngay;
- BT-ALU tắt: target dùng ALU chính và cần multi-cycle sequencing.

### MUL/DIV

Chỉ vào multi-cycle nếu `ex_valid_i` chưa có. Vì vậy single-cycle MUL có thể
hoàn tất ở first cycle, còn MULH/divide tiếp tục giữ stage.

## 6. Công thức stall

```text
stall_id = stall_ld_hz
         | stall_mem
         | stall_multdiv
         | stall_jump
         | stall_branch
         | stall_alu
```

Ngoài ra `stall_wb = en_wb && !ready_wb` ngăn ID đẩy instruction mới vào WB.

`instr_done` chỉ lên khi instruction thực sự execute, không stall và không bị
flush. RF write enable, CSR operation và LSU request đều phải được qualify bởi
`instr_executing` để tránh side effect lặp lại trong chu kỳ stall.

## 7. Hai khái niệm execute

- `instr_executing_spec`: tín hiệu sớm, bỏ qua một số điều kiện muộn để cải
  thiện timing.
- `instr_executing`: tín hiệu đầy đủ, chỉ cho phép side effect khi mọi hazard và
  kill condition đã được xử lý.

Không được dùng nhầm tín hiệu speculative để enable architectural write.

## 8. Controller FSM

FSM toàn cục gồm:

```text
RESET -> BOOT_SET -> FIRST_FETCH -> DECODE
                         ^           |
                         |           +-> FLUSH
                         |           +-> IRQ_TAKEN
                         |           +-> DBG_TAKEN_IF/ID
                         |           +-> WAIT_SLEEP -> SLEEP
                         +-------------------------------+
```

### `RESET` và `BOOT_SET`

Đặt PC boot và khởi tạo `mtvec` từ boot base. Request fetch chỉ bắt đầu sau trình
tự reset được kiểm soát.

### `FIRST_FETCH`

Chờ instruction đầu tiên; debug/interrupt có thể được lấy trước khi vào luồng
decode bình thường.

### `DECODE`

Trạng thái chạy chính. Thứ tự tổng quát:

1. hoàn tất multi-cycle instruction và fault của nó;
2. debug request;
3. interrupt.

Controller không lấy interrupt/debug nếu instruction hoặc WB cũ hơn chưa đạt
điểm an toàn.

### `FLUSH`

Dùng chung cho exception và các special instruction như MRET, DRET, WFI. Tại
đây controller chọn PC mới, nguồn EPC, cause và `mtval`.

### `IRQ_TAKEN`

Chọn interrupt theo ưu tiên: NMI, fast, external, software, timer; lưu PC/cause
và redirect tới vector.

### `DBG_TAKEN_IF`/`DBG_TAKEN_ID`

Phân biệt debug request/single step bắt ở biên IF với EBREAK cần lưu PC của
instruction trong ID.

### `WAIT_SLEEP`/`SLEEP`

Flush pipeline, dừng fetch và hạ busy. Interrupt, NMI hoặc debug request đánh
thức core.

## 9. Exception priority

Controller lưu các yêu cầu fault và phân giải trong `FLUSH`. Các nhóm gồm:

- instruction fetch error/PMP/CHERIoT PCC;
- illegal instruction;
- ECALL/EBREAK;
- store/load error;
- CHERIoT EX/WB/ASR fault.

Với WB stage, load/store error chỉ biết sau khi instruction đã ở WB, nên EPC lấy
từ `pc_wb`; fault ở ID lấy từ `pc_id`. Đây là điều kiện cần cho precise exception.

## 10. Zcmp atomicity và interrupt

Instruction Zcmp được bung thành micro-op nhưng phải giữ semantics của một
instruction kiến trúc. Controller dùng expansion metadata để:

- không retire từng micro-op như instruction độc lập;
- chặn interrupt ở giữa chuỗi cần atomic;
- flush toàn bộ expansion đúng cách khi fault.

Profile FX1 `RV32Zca` không elaborate hành vi push/pop này, nhưng OpenTitan có.

## 11. Assertion đáng chú ý

- multi-cycle transition phải kéo theo stall;
- instruction valid nhưng không execute phải có lý do stall/kill;
- instruction done không được còn outstanding memory access;
- operand selectors phải hợp lệ khi instruction valid;
- instruction copy cho ALU phải trùng bản chính;
- khi CHERIoT runtime off, các output CHERIoT phải bằng 0;
- controller state phải thuộc tập encoding hợp lệ.

## 12. Trình tự debug một stall

1. Xem `instr_valid_i` và `controller_run`.
2. Xem `id_fsm_q` là first hay multi-cycle.
3. Tách từng bit `stall_*`, không chỉ xem `stall_id`.
4. Nếu `stall_mem`, kiểm WB outstanding và LSU handshake.
5. Nếu `stall_ld_hz`, so sánh read address với WB destination.
6. Nếu không stall mà không done, kiểm `flush_id` và exception/debug request.
7. Xác nhận side-effect enable không bị phát lặp.

## 13. Điểm vào source

- [`rtl/ibex_id_stage.sv`](../../../rtl/ibex_id_stage.sv)
- [`rtl/ibex_decoder.sv`](../../../rtl/ibex_decoder.sv)
- [`rtl/ibex_controller.sv`](../../../rtl/ibex_controller.sv)
- [`rtl/ibex_pkg.sv`](../../../rtl/ibex_pkg.sv)

