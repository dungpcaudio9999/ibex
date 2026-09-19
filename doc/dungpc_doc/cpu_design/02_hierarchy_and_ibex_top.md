# 02 — Cây phân cấp và `ibex_top`

## 1. Trách nhiệm của `ibex_top`

`ibex_top` không chỉ là wrapper đổi tên cổng. Nó sở hữu những phần cứng nằm
ngoài pipeline logic của `ibex_core`:

- clock gating và `core_sleep_o`;
- register file vật lý;
- RAM tag/data của I-cache;
- ghép/tách integrity bits trên bus;
- shadow core lockstep;
- khối CHERIoT tag revocation (`ibex_trvk`);
- tổng hợp các alert;
- assertion theo dõi protocol ở biên SoC.

Do đó khi debug tín hiệu tới chân chip, phải bắt đầu ở `ibex_top`; chỉ đọc
`ibex_core` sẽ bỏ sót TRVK, RAM, ECC và lockstep.

## 2. Cây phần cứng mức top

```text
ibex_top
├── core clock gate
├── u_ibex_core                    lõi chức năng chính
├── register_file_i                storage GPR/capability
├── tag_bank[2] + data_bank[2]     khi ICache=1
├── u_ibex_lockstep                khi SecureIbex=1
│   ├── u_shadow_core
│   └── register_file_shadow_i
└── i_ibex_trvk                    khi hỗ trợ CHERIoT
```

`ibex_core` được nối với register file qua interface đọc/ghi, chứ không sở hữu
storage RF. Cách tách này cho phép `ibex_top` chọn implementation FF/FPGA/latch
và tổ chức ECC main/shadow.

## 3. Các miền interface bên ngoài

### 3.1 Instruction side

Interface request/response gồm:

- `instr_req_o`, `instr_gnt_i` cho address phase;
- `instr_addr_o`;
- `instr_rvalid_i`, `instr_rdata_i`, `instr_err_i` cho response phase;
- `instr_rdata_intg_i[6:0]` khi memory integrity được dùng.

Grant và response có thể ở các chu kỳ khác nhau. Không được suy luận
`instr_gnt_i` đồng nghĩa instruction đã sẵn sàng cho decode.

### 3.2 Data side

Ngoài handshake tương tự instruction side, data side có:

- `data_we_o`, `data_be_o[3:0]`;
- `data_wdata_o` và `data_wdata_intg_o`;
- `data_tag_o`/`data_tag_i` cho capability;
- tối đa hai request outstanding để xử lý access lệch hàng.

Khi CHERIoT được elaborate, LSU không nối thẳng ra data port. Luồng là:

```text
ibex_core/LSU -> trvk upstream -> ibex_trvk -> data port SoC
```

### 3.3 Revocation bitmap

`trvk_revbm_*` là port đọc riêng tới bitmap thu hồi capability. Port này chỉ có
ý nghĩa khi `BaseIsa == BaseIsaRV32IorCHERIoT`; nếu không, request/address được
tie-off.

### 3.4 Interrupt và debug

- software, timer, external và 15 fast interrupts;
- NMI riêng `irq_nm_i`;
- `debug_req_i` bất đồng bộ theo góc nhìn phần mềm nhưng được xử lý đồng bộ bởi
  controller;
- `crash_dump_o` và `double_fault_seen_o` phục vụ fault handling.

### 3.5 Control/security

Các tín hiệu MuBi như `fetch_enable_i`, `mcounteren_writable_i` và
`cheriot_enable_i` không phải boolean thông thường. Với secure configuration,
chỉ encoding hợp lệ mới được coi là On/Off; encoding lỗi có thể gây alert.

## 4. Clock gating và sleep

`ibex_core` tạo `core_busy_o` từ ba nguồn:

```text
ctrl_busy || if_busy || lsu_busy
```

Với `SecureIbex=1`, các bit MuBi của `core_busy_o` được tạo từ các bản sao đã
buffer để giảm nguy cơ common-mode optimization. `ibex_top` lưu trạng thái busy
và tạo `clock_en`; clock gate mở khi core đang bận, có interrupt pending, có
debug request hoặc test enable.

Hệ quả review:

- WFI chỉ ngủ khi IF và LSU đã hết giao dịch;
- `mip`/interrupt pending phải có đường tổ hợp có thể đánh thức clock;
- không được thêm stateful logic cần chạy khi clock đã bị gate mà không bổ sung
  wakeup condition.

## 5. Register file vật lý

Parameter `RegFile` chọn một trong ba implementation:

- `ibex_register_file_ff`;
- `ibex_register_file_fpga`;
- `ibex_register_file_latch`.

Các profile đang xét dùng `RegFileFF`.

Với `BaseIsaRV32IorCHERIoT`, RF có cấu trúc dùng chung:

```text
rf_data[0..15]    : data 32 bit của x0..x15
rf_shared[0..15]  :
  RV32I mode      -> data của x16..x31
  CHERIoT mode    -> metadata capability của x0..x15
```

Điều này giải thích vì sao CHERIoT mode chỉ có 16 architectural registers và vì
sao mode enable là chuyển đổi một chiều tới reset.

## 6. I-cache RAM ownership

`ibex_icache` nằm trong IF stage nhưng các RAM vật lý nằm ở `ibex_top`.
IF stage phát `ic_tag_*` và `ic_data_*`; top chọn:

- `prim_ram_1p_scr` nếu `ICacheScramble=1`;
- `prim_ram_1p` nếu I-cache bật nhưng không scramble;
- tie-off nếu `ICache=0`.

Ở cấu hình OpenTitan:

- hai ways;
- tag và data có ECC;
- RAM dùng key/nonce scramble;
- `scramble_req_o` yêu cầu key mới;
- invalidate được phối hợp với trạng thái key.

Ở các profile FX1 hiện tại, I-cache tắt nên cây RAM này bị loại khi elaboration.

## 7. Memory integrity adaptation

Khi `MemECC=1`, top ghép bus thành 39 bit:

```text
{integrity[6:0], data[31:0]}
```

LSU/IF giải mã integrity ở trong core; write data integrity được tạo từ core và
tách ra tại top. Khi `MemECC=0`, `MemDataWidth=32`, integrity output được tie-off
hoặc không có ý nghĩa chức năng.

Assertion ở top theo dõi:

- request không thay đổi payload trước grant;
- số response không vượt request;
- không quá hai D-side transactions outstanding;
- integrity error không bị bỏ qua ở secure profile.

## 8. Lockstep placement

Lockstep nằm song song với main core nhưng trễ `LockstepOffset` chu kỳ. Top
buffer input/output của main core để tạo rào vật lý/tổng hợp, sau đó:

1. delay input cho shadow core;
2. chạy shadow core cùng parameter chức năng;
3. delay output main tương ứng;
4. so sánh toàn bộ bundle output;
5. đưa mismatch vào `alert_major_internal_o`.

Shadow core không điều khiển bus hệ thống; top chỉ xuất một số shadow request để
SoC có thể kiểm tra thêm. Kết quả chính thức vẫn đến từ main core.

## 9. Tổng hợp alert

Ba mức đầu ra:

- `alert_minor_o`: lỗi có thể phục hồi/được phân loại minor;
- `alert_major_internal_o`: lỗi trạng thái nội bộ, ECC RF, PC mismatch,
  lockstep mismatch hoặc MuBi;
- `alert_major_bus_o`: lỗi integrity/protocol trên đường bus.

Khi debug một alert, cần tách nguồn main core, shadow core, TRVK và top-level
integrity trước khi truy ngược vào pipeline.

## 10. Checklist đọc `ibex_top`

- [ ] Xác nhận parameter thực tế từ profile.
- [ ] Xác nhận main core được truyền đúng tất cả parameter override.
- [ ] Xác nhận implementation RF và chiều rộng data/capability.
- [ ] Xác nhận RAM I-cache có thực sự được elaborate.
- [ ] Xác nhận đường data có đi qua TRVK.
- [ ] Xác nhận lockstep enable/offset và thời điểm compare bắt đầu.
- [ ] Xác nhận cách ghép/tách 32+7 bit.
- [ ] Xác nhận mọi alert source đã được nối.
- [ ] Xác nhận các port vô hiệu được tie-off xác định, không để X.

## 11. Điểm vào source

- [`rtl/ibex_top.sv`](../../../rtl/ibex_top.sv)
- [`rtl/ibex_top_tracing.sv`](../../../rtl/ibex_top_tracing.sv)
- [`rtl/ibex_register_file_ff.sv`](../../../rtl/ibex_register_file_ff.sv)
- [`rtl/ibex_lockstep.sv`](../../../rtl/ibex_lockstep.sv)
- [`rtl/ibex_trvk.sv`](../../../rtl/ibex_trvk.sv)

