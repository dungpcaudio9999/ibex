# Hoàn tất phạm vi phân tích microarchitecture

Đợt bổ sung thực hiện sau [kế hoạch còn lại](12_completion_plan.md).
Baseline production RTL vẫn là `fc3b3dd6`; không sửa RTL để chạy test.
21 top-level directed runs PASS, bổ sung cho 160 core runs và 20 module checks
của đợt đầu. Có thêm 6 checker về ordering/transaction, 10 cửa sổ throughput.
PASS chỉ áp dụng oracle và stimulus đã lưu, không phải exhaustive verification.

## Đối chiếu kế hoạch A–H

| Plan | Nội dung hoàn tất | Tài liệu / bằng chứng |
|---|---|---|
| A | Pipeline, register, valid/ready, side effects | 02, 05, 10; baseline WB0/WB1 |
| B | Prefetch/FIFO/aligner, redirect/discard, fetch fault, reset | 03; top.iferror, iferror_second, reset |
| C | Decode/RF/ALU/multdiv, slow/fast/single variants | 04; arithmetic trên 5 cấu hình |
| D | Hazard/forwarding/ownership | 05, 10; memory và delayed response |
| E | LSU BE/split/errors | 06, 10; 160 runs gồm split fault từng beat |
| F | CSR, trap/IRQ/debug/return, WFI clock gate | 07; top.sleep/dret/debug_irq/nmi/nmi_return |
| G | Cache/predictor, Zcb/Zcmp; throughput | 08; cache.cache, predict.loop, zc.zc; 14 |
| H | CHERIoT EX/PCC/LSU/TRVK end-to-end, PMP; secure path map | 09; cheriot.cap/cap_revoked/cap_fault, pmp.pmp_deny; Secure plan riêng |

## Cấu hình và hợp đồng mô phỏng

[Harness](scripts/top_tb.sv) instantiate `ibex_top` với RF và primitive RAM thật
trong checkout; WB=1, BTALU=1, M=SingleCycle, B=Full. Mỗi config bật riêng
predictor, Zcb/Zcmp, cache, dual CHERIoT hoặc PMP. Đây là cấu hình phân tích,
không tự coi là một preset sản phẩm. [Lệnh build](evidence/extended/top.command.json)
và các `*.command.json` lưu parameter; log đầu mỗi run in config thực tế.

Instruction/data memory có queue response in-order. Test event/reset dùng latency4,
grant mỗi3 cycle; test khác latency1/grant luôn. Tagged memory giữ tag theo word;
bitmap response chậm7 cycle. Reset dùng memory epoch: hủy queue khi reset toàn
hệ thống; không chứng minh core tự phân biệt response cũ nếu interconnect vẫn trả.
Clock của core lấy từ clock gate thật; counter chu kỳ lấy root clock.

Hai sửa chữa harness quan trọng: tạo cạnh reset 1→0 trước deassert để state dưới
clock gate nhận async reset; trap handler CHERIoT đọc MEPCC bằng CSpecialRW,
vì CSR MEPC là illegal trong mode này. Chúng là lỗi môi trường thử ban đầu,
không phải lỗi production RTL. `CSRDBG` trong log giữ được privilege/decode evidence.

## Cycle-level kết quả bổ sung

| Kịch bản | Các mốc root cycle đo được | Ý nghĩa |
|---|---|---|
| DRET | load grant27, debug request28, RF load31, RVFI load32, debug PC40h tại40, DRET43, resume98h tại52 | Older load hoàn tất rồi mới vào debug; resume đúng next PC |
| Debug + timer IRQ | load32, debug entry40, DRET43, IRQ vector1ch tại52; không retire98h | Debug ưu tiên, pending IRQ được xử lý sau return |
| NMI + MRET | load32, NMI vector7ch tại40, cause8000001f, MRET55, resume98h tại64 | NMI entry và khôi phục PC qua MRET |
| WFI wake | 58 root cycles sleep; marker123 cuối run | MIE global=0, mie.MTIE=1: pending IRQ wake nhưng không trap |
| Capability live | grants8/9 tại200h/204h, bitmap10, RF c2 tại16 tag1, CGetTag=1 | Decoder→EX→LSU→TRVK→RF chạy với memory và bitmap |
| Capability revoked | cùng các mốc; RF c2 tại16 tag0, CGetTag=0 | Address vẫn1000h, tag bị thu hồi |
| Capability untagged base | mcause28, MEPCC84h, không data request | Exception trước memory side effect |
| Zcmp | store ra tại2fch cycle8, SP→2f0h cycle10; load cycle10, ra cycle11, SP→300h cycle12 | Expansion push/pop rlist4 có4 internal steps; Zcb zext.b trảffh |
| Fetch fault | MEPC84h/MTVAL84h; straddling MEPC82h/MTVAL84h | Instruction fault PC khác failing word khi straddle |
| PMP | locked NAPOT200h..207h, load fault5, MEPC94h, MTVAL200h; zero data grants | Protection chặn request trước bus |

Cache test bật cpuctrl.icache_enable, loop180 lần rồi FENCE.I; có656 hit,
12miss trong toàn run1200 cycles và marker123. Các ca `cache.control/iferror`
không bật runtime cache, nên chỉ chứng minh bypass path khi cache đã elaborate.
Reset invalidation và FENCE.I được đọc trong FSM; không coi hit counter là coverage
của mọi fill-buffer race. Predictor loop3 lần có đúng1 not-taken mispredict;
counter predict toàn run còn đếm JAL tự lặp cuối chương trình.
Zcmp RVFI trong checkout có nhiều internal instructions cùng PC gốc; không lấy
số RVFI đó làm số architectural compressed instructions của benchmark.

## Evidence và tái lập

[21 kết quả](evidence/extended/results.json),
[6 ordering checks](evidence/extended/ordering_checks.json),
[throughput hữu hạn](14_throughput.md). Mỗi run có `.log`, `.vcd.gz`, `.hex`;
lệnh chạy đầy đủ nằm trong JSON, build binary ở `/tmp/ibex-extended/`.

```sh
python3 doc/dungpc/microarchitecture/scripts/run_extended.py
python3 doc/dungpc/microarchitecture/scripts/run_extended.py --configs top --cases nmi_return --skip-build
python3 doc/dungpc/microarchitecture/scripts/summarize_extended.py
python3 doc/dungpc/microarchitecture/scripts/validate_artifacts.py
```

Các macro `prim_assert` dưới Verilator bị dummy theo header của repository;
`--assert` không tự kích hoạt chúng. Oracle Python, `$fatal` harness và logging
đang chạy; không báo formal/SVA coverage. Chưa đo PPA/STA/CDC hay silicon.
Các tổ hợp tính năng và chuỗi instruction chưa thử vẫn là giới hạn validation,
nhưng mọi chủ đề A–H đã có phân tích; chuyên sâu cơ chế bảo vệ tiếp tục theo
[Secure Ibex plan](../secure_ibex/PLAN.md).
