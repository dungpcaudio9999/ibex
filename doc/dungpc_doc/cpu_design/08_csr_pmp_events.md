# 08 — CSR, PMP và các event bất thường

## 1. `ibex_cs_registers` là architectural state hub

Khối CSR không chỉ phục vụ instruction `CSRR*`. Nó giữ và cập nhật:

- privilege state;
- interrupt enable/pending;
- trap PC/cause/value;
- debug state và trigger;
- PMP/ePMP configuration;
- cycle/retire/HPM counters;
- CPU control bits cho DIT, dummy instruction và I-cache;
- CHERIoT special capability registers (SCR);
- trạng thái NMI/double-fault hỗ trợ phục hồi.

Controller quyết định lúc nào save/restore; CSR block quyết định state mới và
enforce write policy.

## 2. CSR operation path

Decoder tạo:

- CSR address;
- `READ`, `WRITE`, `SET` hoặc `CLEAR`;
- source data từ ALU operand A;
- enable chỉ khi instruction thực sự executing.

CSR block tạo `csr_rdata`, dữ liệu này đi qua WB mux như một nguồn RF write.
Illegal CSR access được trả ngược controller để biến thành illegal-instruction
exception; không được commit write trước khi legality rõ ràng.

## 3. Privilege state

Ibex này triển khai M-mode và U-mode, không có S-mode. `mstatus` giữ tối thiểu:

- `MIE`, `MPIE`, `MPP`;
- `MPRV` cho data access;
- `TW` liên quan WFI ở U-mode.

`priv_mode_id` dùng cho instruction/PMP; `priv_mode_lsu` có thể lấy từ
`mstatus.MPP` nếu `MPRV=1`. Vì vậy cùng một instruction ở M-mode có thể tạo data
access được kiểm như U-mode.

## 4. Trap state

Các thanh ghi chính:

- `mtvec`: địa chỉ trap handler;
- `mepc`: PC trở về;
- `mcause`: interrupt/exception cause;
- `mtval`: địa chỉ, instruction hoặc CHERIoT fault detail;
- `mie`/`mip`: enable/pending interrupt;
- `mstatus`: save/restore interrupt enable và previous privilege.

Nguồn EPC được chọn theo nơi fault được phát hiện:

| Event | PC lưu |
|---|---|
| Fetch/illegal/ECALL/EBREAK ở ID | `pc_id` |
| Load/store response fault với WB | `pc_wb` |
| Interrupt trước instruction kế | `pc_if` theo controller sequencing |
| Debug request | IF hoặc ID tùy cause |

## 5. Exception entry

Trình tự logic:

1. controller nhận fault và chờ instruction cũ hơn/WB đạt điểm chính xác;
2. vào `FLUSH`;
3. chọn cause và `mtval` theo priority;
4. phát `csr_save_*` và `csr_save_cause`;
5. CSR lưu EPC/cause/value, đẩy `MIE -> MPIE`, clear `MIE`, lưu privilege;
6. IF redirect tới `mtvec` hoặc debug exception address.

Nếu exception xảy ra trong debug mode, CSR machine trap thông thường không được
cập nhật giống normal execution; control đi tới debug exception vector.

## 6. Interrupt path

`mip` được tạo tổ hợp trực tiếp từ interrupt pins để có thể đánh thức clock sau
WFI. `irqs = mip & mie`; `irq_pending` là OR của các request đã qualify.

Controller áp dụng thêm `mstatus.MIE`, debug mode, NMI state và pipeline safety.
Ưu tiên khi lấy interrupt:

1. NMI;
2. fast interrupt;
3. external;
4. software;
5. timer.

Fast interrupts dùng encoder để tạo cause 16..30. Internal NMI và external NMI
có metadata khác nhau trong `exc_cause_t`.

## 7. MRET, DRET và WFI

- `MRET`: PC lấy từ MEPC/MEPCC, restore privilege và `MIE`.
- `DRET`: PC lấy từ DPC/DEPCC, thoát debug mode.
- `WFI`: controller flush, drain IF/LSU rồi vào sleep; `mstatus.TW` và privilege
  có thể làm instruction illegal.

Trong CHERIoT mode, các PC đặc quyền tương ứng có capability state đi kèm, không
chỉ là địa chỉ 32 bit.

## 8. Debug và trigger

Debug state gồm `dcsr`, `dpc/depc`, scratch registers và tùy chọn hardware
trigger. `DbgTriggerEn` quyết định trigger logic có hoạt động; `DbgHwBreakNum`
quyết định số breakpoint được implement khi đã bật.

Các nguồn vào debug:

- external `debug_req_i`;
- single step;
- EBREAK được cấu hình cho M/U mode;
- address trigger match.

Debug ROM addresses được parameter hóa bởi `DmHaltAddr` và
`DmExceptionAddr`. PMP cho phép special handling debug module range khi đang ở
debug mode.

## 9. Performance counters

Luôn có `mcycle` và `minstret`; `MHPMCounterNum` thêm các counter từ index 3.
Các event gồm IF wait, load/store, branch/taken, jump, D-side wait, multiply và
divide wait.

`MHPMCounterWidth` có thể nhỏ hơn 64. Access high-half và inhibit logic phải được
đọc cùng parameter; không giả định tất cả counter là 64 bit.

`mcounteren_writable_i` là MuBi control bảo vệ quyền software sửa access policy
của U-mode.

## 10. CPU control/status custom CSR

Custom control cung cấp runtime bits như:

- data-independent timing;
- dummy-instruction enable/mask/seed;
- I-cache enable;
- trạng thái scramble key.

Parameter quyết định bit nào có phần cứng thật. Ví dụ `DummyInstructions=0` làm
control liên quan không thể tạo dummy datapath dù CSR address vẫn cần có behavior
xác định.

## 11. CHERIoT SCR

Khi CHERIoT được elaborate, các special capability registers gồm PCC và các
capability tương ứng trap/debug/scratch. Access đi qua interface riêng từ
`ibex_cheriot_ex`, vì operation chứa cả 32-bit data và 35-bit capability.

`misa` đổi động theo `cheriot_enable_i`: I/E/X bits phản ánh runtime ISA. M-mode
CSR access trong CHERIoT còn chịu quyền `PCC.SR`; vi phạm trở thành CHERIoT ASR
fault.

## 12. PMP/ePMP structure

Khi `PMPEnable=1`, core tạo ba checking channels:

| Channel | Address/type |
|---|---|
| `PMP_I` | PC, execute |
| `PMP_I2` | PC+2, execute cho instruction vắt qua word |
| `PMP_D` | LSU address, read hoặc write |

Mỗi region có config `R/W/X`, address mode và lock. Modes gồm OFF, TOR, NA4 và
NAPOT; `PMPGranularity` ảnh hưởng bits address hữu hiệu và khả năng chọn NA4.

Priority theo region index: entry thấp hơn thắng khi nhiều region match.

## 13. ePMP/Smepmp controls

`mseccfg` có:

- `MML`: Machine-Mode Lockdown;
- `MMWP`: Machine-Mode Whitelist Policy;
- `RLB`: Rule Locking Bypass.

Các bit này thay đổi cả default-deny policy và semantics R/W/X/lock. CSR write
logic còn ngăn tạo rule M-mode executable mới sau MML nếu RLB không cho phép.

PMP config và address lock có quan hệ giữa hai entry trong TOR: address lower
bound của entry sau cũng có thể làm entry trước không ghi được.

## 14. PMP trong CHERIoT mode

Khi CHERIoT runtime On:

- địa chỉ đưa vào PMP comparator được gate về 0 để giảm switching;
- output PMP error bị gate về 0;
- PCC/data capability bounds và permissions thay thế ePMP cho access control.

CSR PMP vẫn tồn tại về mặt phần cứng nếu profile bật, nhưng không quyết định
access trong CHERIoT runtime mode.

## 15. Double fault và NMI

Repo có machine-stack CSRs không chuẩn để hỗ trợ recoverable NMI. Khi đang xử lý
NMI mà fault lồng không thể phục hồi đúng, `double_fault_seen_o` được set và đi
vào crash/alert logic. MRET trong NMI mode restore state từ stack CSR thay vì chỉ
dùng MSTATUS/MEPC bình thường.

## 16. Tín hiệu nên xem

```text
csr_access, csr_op, csr_addr, csr_rdata, csr_wdata
priv_mode_id, priv_mode_lsu
csr_mstatus_mie, irqs, irq_pending
csr_save_if/id/wb, csr_save_cause
csr_mepc, csr_mtvec, exc_cause, csr_mtval
debug_mode, debug_mode_entering, debug_cause
csr_pmp_cfg, csr_pmp_addr, pmp_req_err
instr_ret, perf_* events
pcc_cap_r, cheriot_csr_access, cheriot_fatal_err
```

## 17. Điểm vào source

- [`rtl/ibex_cs_registers.sv`](../../../rtl/ibex_cs_registers.sv)
- [`rtl/ibex_csr.sv`](../../../rtl/ibex_csr.sv)
- [`rtl/ibex_counter.sv`](../../../rtl/ibex_counter.sv)
- [`rtl/ibex_pmp.sv`](../../../rtl/ibex_pmp.sv)
- [`rtl/ibex_controller.sv`](../../../rtl/ibex_controller.sv)

