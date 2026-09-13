# 08 — Kết quả kiểm chứng, findings và đóng kế hoạch

Đã thực hiện O1…O7 trên đúng preset `opentitan`. Các đầu ra gồm source analysis,
actual elaboration, directed simulation, trace checks và structural timing/resource
review. Kết quả hiện tại: **19 parameter checks, 54 directed runs, 90 trace/run
checks và 1 checker negative control đạt**; lưu 23 compressed waveforms.
90 checks đã bao gồm 54 run-oracle checks, không cộng chúng thành 144 case độc lập.
[Validation report](evidence/validation_report.json).

## Ma trận thực nghiệm

| Nhóm | Run IDs | Điều kiện kiểm nổi bật |
|---|---|---|
| Baseline instruction | `rv.arithmetic`, `rv.control`, `rv.compressed`, `rv.bitmanip`, `cap.arithmetic` | Golden registers và branch/ISA behavior |
| Memory/precision | `rv.memory_d1/d4`, `rv.independent_d1/d4`, `rv.error_young`, `rv.error_split_load_first/second` | D1/D4, split BE, error PC/address, không write instruction trẻ |
| Preset-specific CSR | `rv.pmp_deny`, `rv.pmp_region15`, `rv.counters` | Locked PMP0/15; 10×32 HPM wiring |
| Zcmp | `rv.zcmp`, `rv.zcmp_debug`, `rv.zcmp_irq`, `rv.zcmp_irq_multi`, `cap.zcmp_illegal` | Expansion, debug boundary, IRQ restart PC, illegal capability mode |
| Events/debug | `rv.sleep`, `rv.dret`, `rv.debug_irq`, `rv.nmi_return`, `rv.div_debug`, `rv.debug_trigger` | Wake, drain, priority, DRET/MRET, execute trigger |
| Frontend/reset | `rv.cache`, `rv.cache_debug_key`, `rv.reset`, `rv.iferror_second` | Warm loop, key/debug progress, epoch reset, second-half fetch error |
| Runtime timing | `rv.dit_off_zero/off_nonzero/on_zero/on_nonzero`, `rv.dit_branch_taken/nt`, `rv.dummy_dit_cache` | DIT CSR thực, ID occupancy, combined activity |
| Capability | `cap.live`, `cap.revoked`, `cap.cache`, `cap.fault`, `cap.bound`, `cap.roundtrip`, `cap.debug` | Tag/revocation/bounds, six-beat roundtrip, debug during bitmap |
| Fault detection | `rv.fault1/2/3/4/6/7/10`, `cap.invalid_mode`, `cap.rf_ecc`, `cap.bitmap_ecc` | Detector classification; unsupported unsolicited-response detection point |

Slash trong bảng là viết gọn danh sách IDs; nguồn đầy đủ là
[CASES](scripts/run.py) và [results.json](evidence/results.json).

## Chuỗi bằng chứng và cách chạy lại

```bash
cd /home/dungpc/ndmoney4porche/projects/ibex
python3 doc/dungpc/opentitan/scripts/run.py
python3 doc/dungpc/opentitan/scripts/capture.py
python3 doc/dungpc/opentitan/scripts/analyze.py
python3 doc/dungpc/opentitan/scripts/validate.py --seal
```

Môi trường đã dùng Verilator 5.020, Python/PyYAML và C++ toolchain. `run.py` build
binary vào `/tmp/ibex-opentitan`, sau đó chạy tất cả cases; evidence nằm trong
repo. `--skip-build --cases rv.memory_d4,cap.roundtrip` chỉ dùng khi binary còn
đúng source/harness/params; sau khi source thay đổi phải build lại. Script import
instruction encoders/stimulus helpers từ bộ microarchitecture trước, các dependency
đó cũng có hashes. Không sửa helper cũ để tránh thay baseline evidence trước.

`capture.py` lưu resolved params/localparams, hierarchy và compressed XML; so
19 YAML overrides bằng actual constants, kiểm main/shadow RF ECC split và secure
localparams. `analyze.py` kiểm final registers, hoạt động, ordering và occupancy.
`validate.py --seal` đối chiếu hex với generator, log với oracles/results, source
hashes, links, snapshots và waveforms, rồi tạo manifest mới. Để kiểm bộ artifact
đã lưu mà không tạo manifest mới:

```bash
python3 doc/dungpc/opentitan/scripts/validate.py
```

`--seal` chỉ dùng sau khi chủ động chạy/cập nhật evidence; lỗi manifest ở chế độ
verify cần được điều tra trước khi seal lại. Không coi việc hash một kết quả là
bằng chứng kết quả đó đúng: logic/property checks nằm ở tầng riêng.

## Đọc logs và biết checker thực sự kiểm gì

| Record | Nội dung |
|---|---|
| T | root time, ID PC/valid/ready, memory/load-use/M-D/branch/jump/ALU stalls, WB readiness/outstanding-load, PC-set, new/dummy/expanded |
| W | root counter, destination, scalar payload, capability metadata |
| R | root counter, RVFI order, PC, instruction bits quan sát |
| D / B | Accepted data request / bitmap request; D có BE, write data và tag |
| EVENT / KEY | External event injection và key response |
| SAMPLE / LOCK / SECDET | Internal detector/alignment observations; chỉ các cửa sổ chọn |
| REG / COUNTS | Architectural monitor và toàn-run activity |
| PROTOCOL_CHECKS / FINISH | Immediate protocol checker đã chạy / simulator hết thời lượng |

Mỗi run dài 1200 root cycles. FINISH không thay architectural completion marker.
Faults làm execution không còn đáng tin chỉ đặt detector oracle phù hợp; không
gọi chúng là instruction-completion tests. Protocol checker kiểm giữ request
instruction/data tới grant và không trả response khi chưa có outstanding request
trong **memory model**. Fault7 chèn unsolicited valid bên dưới model chủ động;
không được diễn giải là model checker đã chứng minh DUT từ chối mọi malformed
response. Bitmap backpressure/protocol chưa được quét tương tự D1/D4.

RVFI dùng để quan sát order/PC, không nối ISS reference model hay formal RVFI
proof. Architectural monitor loại dummy writes, ghi scalar destinations và
kiểm các tag qua instruction CGETTAG/trace metadata. Chưa so toàn bộ architectural
state sau mỗi instruction.

## Những phát hiện thay đổi cách hiểu thiết kế

1. Preset có dual ISA, BOTEarlGrey, Zcmp, PMP16, debug trigger và HPM10×32. Các
   secure-combo runs trước không đủ để đại diện exact preset này.
2. WB stage có forwarding nhưng không cho independent instruction vượt pending
   load. Lỗi load được kiểm không viết destination/lệnh trẻ.
3. Zcmp debug và IRQ có điều kiện hoãn khác nhau. IRQ multi-push có thể lưu MEPC
   về instruction nguồn với một số store đã xảy ra và SP chưa cập nhật.
4. `RV32MSingleCycle` vẫn có MULH 2 và DIV 37 ID cycles trong ca đo; DIT loại
   divide-by-zero early-out ở phép thử 2→37.
5. Cache runtime disable không loại hardware/cache startup busy. Điều này ảnh
   hưởng WFI và throughput lúc initial invalidation.
6. Capability load có completion phụ thuộc bitmap; ECC bitmap làm tag=0 và bus
   alert, khác ordinary access fault. Mode migration có shared-RF context hazard.
7. Lockstep không phải một full duplicate memory/RF datapath; protection phải
   đọc cả integrity paths và selected output bundle. Alert detection khác containment.
8. Execute trigger dùng top default debug map và có programming restrictions.
   High-half HPM 32-bit và unsupported counter reads được kiểm cụ thể.

## Sai lệch stimulus đã sửa và giới hạn tool

WFI stimulus cũ phát IRQ ngay khi cache vừa hết busy và CPU mới ngủ, nên không
đủ 20 sleep cycles mà oracle yêu cầu; stimulus hiện đợi actual sleep counter.
DIT helper cũ kiểm substring `on`, vô tình khớp cả `nonzero`; runner mới phân
tách mode token và checker đối chiếu CSR setup word trong hex. Zcmp single-RA
IRQ ban đầu được dự đoán restart push; trace/source cho thấy SP update đã hoàn
tất nên MEPC đúng là pop kế tiếp. Thêm multi-register case để kiểm phần thực sự
restartable, giữ hai oracle riêng. Đây là sửa assumption/test; không sửa RTL.

Build thành công nhưng chưa lint-clean: log có TIMESCALEMOD, hai WIDTHTRUNC của
integer-as-boolean trong harness, MULTIDRIVEN liên quan force RAM output cho
fault injection, và UNOPTFLAT tại PRINCE/control paths. Các directed simulations
hội tụ và hoàn tất; không dùng việc hội tụ để khẳng định không có timing/loop
issue trong mọi elaboration/synthesis flow. [Build log](evidence/build.log).

Audit preprocessing thấy 0 expanded `assert property`, do `prim_assert` chọn
nhánh Verilator. Immediate harness checks hoạt động; chưa thực hiện full SVA
regression. Không có physical synthesis/STA, full ISA/B/CHERIoT compliance, U-mode
PMP exhaustive, CDC/RDC sign-off, exhaustive fault/leakage campaign hay valid
runtime ISA migration proof. [Assertion audit](evidence/assertion_audit.json).

## Closure O1…O7 và bước kế tiếp hợp lý

| Plan | Đầu ra hoàn tất | Cơ sở |
|---|---|---|
| O1 | [01_configuration](01_configuration.md) | 19 resolved parameter checks, hierarchy, hashes |
| O2 | [02_contracts_modes](02_contracts_modes.md) | Static/runtime split, memory/debug/bitmap/key/reset assumptions |
| O3 | [03_datapath_state](03_datapath_state.md) | Register/state ownership và update/hold/flush |
| O4 | [04_instruction_flows](04_instruction_flows.md) | Whole-instruction flow, cycle/transaction evidence |
| O5 | [05_interactions](05_interactions.md), [06_security](06_security.md) | Ordering, capability, key/debug, fault detector checks |
| O6 | [07_timing_resources](07_timing_resources.md) | Structural resource inventory/path candidates và measured cycles |
| O7 | Tài liệu này + [machine report](evidence/validation_report.json) | Reproducible commands, checks, negative control, scope closure |

Kế hoạch phân tích directed đã hoàn tất; không đánh dấu những bước sign-off
ngoài phạm vi thành “pass”. Khi cân nhắc sửa thiết kế, dùng baseline này chọn
workload/threat model/SoC contracts và target technology trước, rồi mở một change
proposal có functional, timing và security acceptance criteria cụ thể.
