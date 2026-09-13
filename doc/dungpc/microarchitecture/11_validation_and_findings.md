> Cập nhật đợt 2: các giới hạn mô phỏng dưới đây mô tả đợt đầu. Phần bổ sung và
> đối chiếu toàn bộ plan nằm ở [13_completion_results.md](13_completion_results.md).

# 11 — Kết quả, giới hạn và hướng sử dụng

## Kết quả thực thi

Đã build và chạy unchanged core RTL ở 5 cấu hình, 16 chương trình/cấu hình,
2 chế độ bus: **160 runs**. Expected-register checks và trace checks là hai lớp
kiểm khác nhau trên cùng 160 runs, không cộng thành 320 simulations.

| Nhóm | Nội dung kiểm | Bằng chứng |
|---|---|---|
| arithmetic | ADD/ADDI dependency, MUL/DIV/REM/MULH, divide-zero, signed overflow | core_results + logs |
| memory | Load-use, store/load liên tiếp, split store/load, LBU | 7 transaction addresses/BE; RF và memory contents |
| control | Not-taken/taken BEQ, JAL, JALR, link registers | RVFI PC sequence; wrong-path writes bị cấm |
| compressed | c.nop, ADDI 32-bit tại PC+2, c.addi | Instruction-PC mapping và final x1 |
| 6 error programs | Load/store aligned và split first/second response errors | mepc/mcause/mtval, suppress load/younger writes |
| event1..4 | IRQ/debug khi load hoặc divider pending | Event thực sự fire, completion trước handler, timer cause |
| mret | Ghi mepc, MRET tới target | Target signature, skipped x20 không ghi |
| wfi_pending | Timer pending, mie.MTIE=1, global MIE=0 | WFI tiếp tục mà không vào timer handler |

Ba module tests CHERIoT: **20 directed checks** (EX 8, LSU 6, TRVK 6), lưu
[unit_results](evidence/unit_results.json). Không gộp chúng thành 20 full-core
CHERIoT simulations.

[core_results](evidence/core_results.json) lưu expected registers, command và status.
[trace_checks](evidence/trace_checks.json) kiểm PC/instruction, RVFI order,
transaction/BE và side effects theo test. Negative control cố ý đổi instruction
trong bản copy trace; checker phải từ chối. [Kết quả](evidence/negative_control.json).
Control đó kiểm parser/checker thực sự phát hiện sai khác, không chứng minh tất
cả assertions của RTL hoạt động.

## Những kết luận microarchitecture quan trọng

| ID | Kết luận | Căn cứ / giới hạn |
|---|---|---|
| MA-01 | ID/EX là một stage; EX module không tự tạo stage riêng | SOURCE pipeline registers; active harness |
| MA-02 | WB1 chặn younger execution trong lúc memory cũ chưa resolve | SOURCE `outstanding_memory`; SIM delayed memory/errors |
| MA-03 | Load-use vẫn stall ở response cycle; load data không vào arithmetic forwarding mux | SOURCE hazard/forwarding; SIM WB cycle 7→8 |
| MA-04 | LSU IDLE/busy không đại diện toàn bộ outstanding response | SOURCE request/response ownership; SIM WB waiting |
| MA-05 | Fault phần đầu split báo byte address gốc, phần sau báo word address phần sau | SOURCE addr_last + SIM mepc/mtval |
| MA-06 | Fast MUL/MULH là 3/4 ID cycles; SingleCycle là 1/2; DIV test là 37 | SOURCE FSM + SIM; không áp số đo Slow MUL cho mọi operand |
| MA-07 | Redirect phải giữ/drain bus requests cũ; clear instruction không cancel external transaction | SOURCE FIFO/prefetch; SIM branch tests hỗ trợ, chưa exhaustive |
| MA-08 | TRVK clear tag khi revoked/bitmap error; metadata tag riêng chưa là validity của cả cap | SOURCE join/tag; SIM TRVK và LSU riêng |
| MA-09 | PMP errors bị mask khi local dual ISA ở CHERIoT On | SOURCE only; không phải security sign-off |
| MA-10 | Verilator flag `--assert` không phục hồi `prim_assert` macro bị header loại | SOURCE header + actual dependency list; explicit checker thay thế có scope nhỏ |

## Hiệu năng: cách dùng các số đo

Tách execution latency, thời gian chiếm ID, retirement interval, memory transaction
latency và thời điểm đạt signature. Bảng timing ghi đúng metric; không dùng cycle
ghi x31 làm latency riêng của instruction cuối.

Một CPI decomposition hữu ích để đọc trace là baseline issue cost + thời gian
không retire do fetch, execution, data wait và control recovery. Nhưng không cộng
thẳng các stall counters nếu chúng chồng nhau (ví dụ `stall_mem` và `stall_ld_hz`).
Muốn đo CPI workload cần chọn một cửa sổ retired instructions xác định, loại
boot/termination loop hoặc ghi rõ đã bao gồm, và hiểu semantics counters/RVFI.

| Thay đổi | Lợi ích cấu trúc | Chi phí/ràng buộc có thể tăng |
|---|---|---|
| WB1 | Cho stage tiếp nhận result/control và overlap một số response/ID work | State, hazard/forwarding logic, load-use bubble |
| BTALU | Tính target song song compare/link | Adder + operand mux/wiring |
| SingleCycle MUL | Nhiều partial products tính song song | Multiplier/combinational resources |
| I-cache | Tránh một phần external fetch latency khi hit | RAM + tag/ECC + fill tracking; invalidation/key startup |
| Predictor | Redirect sớm cho các branch/jump được dự đoán | Recovery/skid logic, wrong-path fetches |
| CHERIoT | Check và vận chuyển authority metadata trong pipeline | RF metadata, bounds/permission paths, two-word access, bitmap wait |
| Lockstep/ECC | Phát hiện sai khác/integrity errors | Redundancy và checking logic; recovery cần system policy |

Đây là trade-off từ cấu trúc, **chưa có area/Fmax/power đo được**. Đường RF→mux→EX,
LSU error→ID permission-to-execute, bounds→request gate, tag compare/ECC→cache
output là ứng viên cần timing analysis. Không xếp hạng critical path bằng phỏng đoán.

## Giới hạn còn lại và điều kiện đóng

| Nội dung | Trạng thái hiện tại | Để đóng phần thực nghiệm |
|---|---|---|
| Named config qua FuseSoC/UVM/Simple System | Chỉ đối chiếu source; harness riêng active | Build target thật, expanded parameters/filelist |
| Cache/predictor/Zcb/Zcmp | Phân tích state/datapath, SOURCE | Cache RAM model; hit/miss/error/invalidate; branch prediction/expansion tests |
| Full-core CHERIoT | EX/LSU/TRVK unit tests, chưa tích hợp end-to-end | Tagged memory/bitmap + program + decoder/trap/CSR checker |
| Capability ISA conformance | Một số direct load checks | Model/spec revision và independent arithmetic/permission oracle |
| PMP/ECC/lockstep | Phân tích SOURCE | Enabled configuration và directed fault injections |
| WFI clock gating | Pending-interrupt WFI ở core | Top gate + wake-after-sleep/CDC/reset tests |
| MRET/DRET/debug/IRQ priority | MRET cơ bản, IRQ/debug pending-operation | DRET, simultaneous causes, nested NMI, single step |
| Instruction bus error, reset giữa giao dịch | Chưa inject | Boundary monitors, late-response/reset epoch tests |
| Formal, coverage closure, STA/PPA | NOT-RUN | Tool/backend/constraints và reports tương ứng |

Các nội dung SOURCE đã có trong bộ phân tích; phần dynamic còn thiếu không được
gọi PASS. Lượt này hoàn thành khảo sát chuyên sâu theo các phần A–H và bổ sung
directed simulation, không hoàn thành verification toàn thiết kế.

## Development observations và warnings

Run thử đầu tiên gặp race trong **harness** khi đổi cycle counter làm cửa grant
thay ngay ở sampling edge. Cửa grant được chuyển sang falling edge và tất cả
core cases được chạy lại sau sửa. Expected mtval phần đầu split được sửa từ
aligned address sang byte address gốc theo RTL. [First-run diagnostic](evidence/development_first_run.json)
chỉ giữ lịch sử, không thuộc kết quả final.

Cap EX harness được đổi sang drive toàn packed operator bằng continuous assignment
để control chuyển mode test ổn định trong simulator; final run kiểm đủ các ca.
Không sửa production RTL để làm test pass.

Build dùng `-Wno-fatal`; logs có TIMESCALEMOD và UNOPTFLAT (các dependency vòng
combinational như ID control hoặc CSR addr). Simulation đã settle ở các cases
đã chạy, nhưng đó **không phải clean lint** hay chứng minh không có combinational
timing problem. Không bật SYNTHESIS để loại logic cần phân tích.

## Tái lập

Từ root repository, cần Python 3, Verilator 5.020 tương thích và C++ build tools:

```bash
python3 doc/dungpc/microarchitecture/scripts/run_core.py
python3 doc/dungpc/microarchitecture/scripts/run_units.py
python3 doc/dungpc/microarchitecture/scripts/analyze_traces.py
python3 doc/dungpc/microarchitecture/scripts/capture_elaboration.py
python3 doc/dungpc/microarchitecture/scripts/validate_artifacts.py
```

Không cần RISC-V cross compiler: các chương trình nhỏ được encode trong runner,
có expected values rõ ràng. Không cần cài dependency mạng cho những run đã làm.
Binaries/object files ở `/tmp/ibex-microarchitecture`; evidence bền vững chứa
commands, logs, hex programs, gzipped core waveforms, hierarchy và hashes.
`--skip-build` chỉ dùng khi harness/RTL/config và toolchain chưa đổi; runner có
`--cases` để thêm subset results trong cùng baseline.

Phần đọc nhanh để review kỹ thuật: pipeline→hazards→timing→LSU→CHERIoT, sau đó
đối chiếu assumptions với hệ thống định tích hợp. Nếu sửa một module, dùng
ownership/handshake trong các chương để chọn thêm tests có liên quan.
