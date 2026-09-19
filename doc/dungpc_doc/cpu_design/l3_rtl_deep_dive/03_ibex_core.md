# 03 — Deep dive `ibex_core`

## 1. Contract và ownership

Core nhận instruction/data/RF/cache-RAM interfaces và trả side effects ra top.
Nó instantiate IF, ID, EX, optional CHERIoT EX, LSU, WB, CSR và PMP. Nó sở hữu
pipeline interconnect, RF ECC encode/decode khi requested, RVFI state và alert
classification.

## 2. Stage ownership

| State/result | Owner |
|---|---|
| Current fetch address/data buffering | IF |
| Instruction decode và ID multi-cycle state | ID |
| Global trap/debug/sleep state | controller trong ID |
| ALU/MUL/DIV intermediate values | flops trong ID, producers ở EX |
| Memory protocol state | LSU |
| Post-ID instruction ownership | WB |
| Privilege/trap/counter/PCC state | CSR block |
| Physical GPR/cap storage | ngoài core, ở top |

## 3. Pipeline interfaces

IF→ID mang valid/new, decompressed instruction, compressed original, PC, fetch
fault, Zcmp expansion và dummy marker. ID→EX mang operators/operands. EX→ID mang
result/valid/branch. ID→WB mang write metadata/type/PC. WB→ID mang readiness,
destination, forwarding và outstanding memory state.

Không có một register “ID/EX payload” đầy đủ riêng: instruction được giữ trong
IF/ID register khi ID multi-cycle, còn intermediate values có flops riêng.

## 4. Busy computation

```text
busy_inputs = ctrl_busy, if_busy, lsu_busy
```

Non-secure branch OR trực tiếp. Secure branch replicate/buffer và tạo từng bit
MuBi theo polarity của `IbexMuBiOn`, hạn chế synthesis tối ưu tất cả bits từ một
logic cone chung.

## 5. Fetch enable gating

`instr_req_gated` dùng strict MuBi equality khi secure; non-secure chỉ xét bit
thấp. Assertions chụp PC tại disable và yêu cầu ID không nhận instruction mới
sau fetch disable.

**Invariant I-CORE-01:** Fetch disable ngăn instruction mới nhưng không được làm
mất outstanding response hoặc architectural completion đang có.

## 6. Branch target selection

RV32 target từ `ibex_ex_block`, CHERIoT target từ `ibex_cheriot_ex`:

```text
target = valid_id && instr_is_cheriot ? cheriot_target : rv32_target
```

CHERIoT branch request và target còn đi vào CSR/PCC update. Runtime-off branch
ties CHERIoT outputs về zero/default.

## 7. LSU source arbitration

`ibex_cheriot_ex` nhận RV32 LSU intent và phát interface thống nhất:

- ở RV32 mode, chuyển tiếp address/type/data;
- ở CHERIoT mode, thêm authority checks, cap tag/data và fault;
- core chỉ instantiate một LSU.

Điều này làm CHERIoT EX nằm trên critical/control path ngay cả với RV32 signal
wiring trong dual-ISA build; synthesis/runtime gating cần được xem ở timing.

## 8. WB and response checks

Secure branch kiểm response chỉ xuất hiện khi ID/WB đang mong đợi tương ứng.
WB stage choice thay đổi nơi LSU errors được gắn với instruction và nguồn EPC.

`rf_we_wb` cuối cùng có thể đến từ ID result hoặc LSU result. Core đưa encoded
data/cap ra top nếu `RegFileECC=1`; main instance đặt 0, shadow instance đặt 1.

## 9. CSR/PMP integration

CSR write data lấy từ `alu_operand_a_ex`; decoder/controller phát op/address/
save/restore. PMP có ba addresses: PC, PC+2 và D-side. Trong runtime CHERIoT,
addresses bị gate và errors forced zero.

## 10. Alerts

Core internal alert sources gồm PC mismatch, RF ECC, CSR fatal/shadow state,
CHERIoT MuBi/fatal và double-fault related logic. Bus alert bao phủ instruction/
data integrity và unexpected memory response. Exact OR tree cần được giữ nhất
quán với assertions ở top.

## 11. RVFI capture

Với WB stage, RVFI phải capture source operands/PC/insn ở ID rồi delay tới
retirement. Memory masks/data và capability fields lấy ở đúng response. RVFI
valid không phải `instr_valid_id`; nó là architectural completion.

**Invariant I-CORE-02:** Một instruction kiến trúc tạo tối đa một `rvfi_valid`,
Zcmp micro-ops phải được biểu diễn theo contract expansion/RVFI của environment.

## 12. Reset and configuration variants

- `WritebackStage=1`: RVFI và exception PC cần WB-aligned state.
- `PMPEnable=0`: errors tie zero.
- `BaseIsa` không CHERIoT: capability paths tie default.
- `RegFileECC=0`: main core pass data/cap raw.
- `ResetAll=0`: nhiều payload flops giữ X đến first enable, control/valid reset.

## 13. Cross-module critical candidates

- RF read → ID forwarding → ALU → WB enable.
- ALU address → CHERIoT check → LSU request/PMP.
- IRQ pin → `mip`/pending → clock enable/controller.
- memory response → LSU error/data → WB done → ID ready.
- branch compare/CHERIoT branch → controller PC set → IF redirect.

Đây là candidates từ structure, chưa phải timing report.

## 14. L4 handoff

Golden traces phải quan sát `pc_if/id/wb`, valid/ready, all `stall_*`, EX valid,
LSU req/done/resp, WB valid/done, RF write, CSR save và RVFI. Cần một trace cho
mỗi feedback loop ở mục 13.

## 15. Source anchors

- [`rtl/ibex_core.sv`](../../../../rtl/ibex_core.sv)
- [`rtl/ibex_pkg.sv`](../../../../rtl/ibex_pkg.sv)
- [`rtl/ibex_top.sv`](../../../../rtl/ibex_top.sv)

