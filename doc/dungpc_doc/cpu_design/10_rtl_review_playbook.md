# 10 — Playbook review RTL top-down

## 1. Mục tiêu hoàn tất hướng B

Sau khi hoàn tất hướng RTL top-down, người đọc phải trả lời được:

1. Module nào sở hữu mỗi architectural state và bus side effect?
2. Một instruction đi qua những valid/ready nào?
3. Mỗi loại stall được tạo ở đâu và xóa khi nào?
4. Redirect/flush nào thắng khi branch, fault, interrupt và debug trùng nhau?
5. Parameter nào làm thay đổi phần cứng thật?
6. RV32 và CHERIoT dùng chung/tách datapath ở đâu?
7. Lỗi nào tạo architectural exception, lỗi nào tạo alert?
8. Thay đổi RTL cần test/assertion nào để chứng minh an toàn?

## 2. Quy trình review một module

### Bước 1 — Xác định contract

Ghi rõ:

- input nào là request, input nào là payload;
- điều kiện payload hợp lệ;
- output side effect;
- latency tối thiểu/tối đa;
- back-pressure và cancellation semantics.

### Bước 2 — Tách combinational và state

Liệt kê mọi `_q`, reset value, enable và `_d`. Với payload không reset, xác định
valid bit bảo vệ nó. Không chấp nhận nhận xét chung “không sao vì valid=0” nếu
payload vẫn đi vào compare/ECC/alert logic không được gate.

### Bước 3 — Vẽ FSM

Cho mỗi transition, ghi:

```text
current state + guard -> next state + side effects
```

Đặc biệt đánh dấu transition do error, flush, reset và mode switch.

### Bước 4 — Resolve parameter branches

Không review cả hai nhánh generate như thể cùng chạy. Tạo một bản cho từng
profile cần sign-off và đánh dấu active/inactive.

### Bước 5 — Trace một giao dịch bình thường

Theo valid/ready từ input đến output, bao gồm cycle ownership và nơi dữ liệu
được register.

### Bước 6 — Trace giao dịch bất thường

Ít nhất gồm reset giữa operation, back-pressure, error response, redirect và
simultaneous event.

### Bước 7 — Kiểm assertions

Mỗi invariant quan trọng cần một trong:

- assertion RTL;
- checker UVM;
- cosim comparison;
- formal property;
- lý do rõ vì sao chỉ test directed là đủ.

## 3. Bộ golden traces tối thiểu

| Trace | Điều cần chứng minh |
|---|---|
| ADD phụ thuộc ADD trước | WB forwarding không stall |
| LW rồi dùng ngay | load-use stall đúng một khoảng response |
| Word misaligned | hai request, ghép đúng, fault address đúng |
| Taken/not-taken branch | target, flush, timing theo DIT |
| DIV zero/nonzero | result và timing policy |
| CSR write + interrupt | precise state save và priority |
| WFI + wakeup | drain bus, gate clock, wake đúng |
| PMP denied fetch/data | request bị chặn và cause/mtval đúng |
| Debug request + outstanding load | không vượt instruction cũ |
| CHERIoT CLC/CSC | hai beat, tag và permission clearing |
| CHERIoT bounds fault | không có bus side effect, fault info đúng |
| Revoked capability | data forward nhưng returned tag bị clear |
| Lockstep injected mismatch | compare enable và alert đúng |

## 4. Ma trận ảnh hưởng khi sửa RTL

| Vùng sửa | Vùng phải kiểm kèm |
|---|---|
| IF/prefetch | PMP I/I2, compressed cross-word, PC check, RVFI PC |
| Decoder | illegal instruction, RF enables, CHERIoT isolation, coverage |
| ALU adder | branch, LSU address, MUL/DIV reuse, comparisons |
| ID stall | WB readiness, precise exception, RVFI retirement |
| LSU FSM | outstanding tracker, WB, PMP error without grant, TRVK |
| WB | forwarding, load-use, retire counters, dummy marker |
| CSR | privilege legality, exception priority, debug, CHERIoT ASR |
| PMP | MPRV, debug range, TOR neighbour locking, Smepmp |
| Capability format | RF, ECC width, memory conversion, TRVK parsing |
| Lockstep | delay alignment, reset, backend anti-optimization constraints |
| Config tooling | YAML, FuseSoC opts, sim opts, TB parameters, regression names |

## 5. Lộ trình thực hành 16 buổi

1. Chốt baseline và parameter truth table.
2. Vẽ `ibex_top` interfaces và active generate tree.
3. Theo một ADD qua core.
4. IF/prefetch/compressed.
5. Decoder và operand mux.
6. Controller FSM và redirect.
7. Hazard/forwarding/WB.
8. ALU và branch target.
9. MUL/DIV và data-independent timing.
10. LSU aligned/misaligned.
11. Exception/interrupt/debug/WFI.
12. CSR/counters/PMP.
13. Capability representation và CHERIoT EX.
14. Capability LSU và TRVK.
15. Lockstep/ECC/alerts/reset.
16. So sánh OpenTitan với FX1 DEV/PROD và chốt verification gaps.

Mỗi buổi nên tạo một artifact: sơ đồ, bảng state, waveform có annotation hoặc
review checklist đã ký.

## 6. Câu hỏi review riêng cho FX1

### `ResetAll=0` với lockstep

- Compare bắt đầu chính xác ở cycle nào?
- Output payload chưa reset có nằm trong bundle compare khi valid=0 không?
- Hai simulator 2-state/4-state cho cùng kết quả không?
- Gate-level/X-prop có mismatch trước hoạt động đầu tiên không?

### `MemECC=0`

- Top/testbench có truyền width đúng không?
- Integrity outputs được tie-off giá trị nào?
- Alert expectations có còn chờ ECC event không?
- External memory có ECC riêng hay chấp nhận mất countermeasure?

### `RV32BNone`

- Toolchain flags có ngăn phát bitmanip không?
- Boot ROM/firmware library có dùng Zba/Zbb/OpenTitan custom set không?
- Illegal-instruction tests có bao phủ binary build sai ISA không?

### DEV và PROD

- Trigger CSRs read/write thế nào khi disable?
- HPM counters không implement có đọc 0 và write ignored đúng không?
- Debug module integration có bị compile-time assumptions không?

## 7. Definition of done cho một thay đổi

- [ ] Baseline/config đã ghi lại.
- [ ] Active hierarchy đã xác định.
- [ ] Interface contract và cycle timing đã mô tả.
- [ ] Normal/error/reset traces đã kiểm.
- [ ] Không tạo side effect trong stall/flush.
- [ ] RV32 và CHERIoT mode đều được xét nếu cùng elaborate.
- [ ] Lockstep main/shadow parameter khớp.
- [ ] Alert/exception classification đúng.
- [ ] Assertion liên quan pass.
- [ ] Directed test pass.
- [ ] Constrained-random/cosim pass ở số seed phù hợp.
- [ ] Coverage gap được ghi rõ.
- [ ] Tài liệu/config reference không bị dangling.

## 8. Các khoảng trống hiện tại cần xử lý tiếp

1. Reference `doc/fx1_secure_config_eval.md` trong YAML đang bị thiếu.
2. Tài liệu chi tiết hiện tại mô tả `opentitan` tốt hơn FX1; cần tạo bảng
   active/inactive cho từng chương khi profile FX1 ổn định.
3. Cần lưu một baseline regression nhỏ cho từng `fx1_secure_*`, thay vì chỉ giữ
   các thư mục output lớn không version-control.
4. Cần có test chẩn đoán rõ kết quả giữa `fx1_secure_dev` và
   `fx1_secure_dev_resetall`.
5. Cần audit firmware/toolchain ISA flags trước khi chốt `RV32BNone`.
6. Formal flow có assumptions/proof holes; không nên dùng chữ “fully proven” cho
   bus error, debug, NMI hay CSR chưa được model.

## 9. Thứ tự tài liệu/source khi root-cause

```text
failing instruction/event
 -> RVFI/log
 -> WB/retirement owner
 -> ID stall/flush owner
 -> EX/LSU/CSR producer
 -> IF PC/history
 -> ibex_top ECC/TRVK/lockstep adaptation
 -> configuration/tool propagation
```

Luồng này tránh sửa triệu chứng ở stage sau trong khi nguyên nhân nằm ở control
hoặc parameter propagation phía trước.

## 10. Tài liệu liên quan

- [mô phỏng VCS](../13_mo_phong_vcs.md)
- [flow arithmetic test](../14_flow_test_riscv_arithmetic_basic.md)
- [pipeline timing](../12_pipeline_timing.md)
- [`dv/uvm/core_ibex`](../../../dv/uvm/core_ibex)
- [`dv/formal/README.md`](../../../dv/formal/README.md)

