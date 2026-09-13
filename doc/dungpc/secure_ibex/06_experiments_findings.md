# S7 — Thực nghiệm, findings và đối chiếu kế hoạch

Kết quả: **40 directed top runs PASS**, cộng **31 analysis checks PASS** và một
negative control cho checker. Tất cả dùng production RTL của checkout, không
patch implementation. [Kết quả máy đọc](evidence/results.json),
[analysis checks](evidence/analysis_checks.json),
[số đo](07_measured_tables.md), [validation](evidence/validation_report.json).
Đây là hoàn tất phạm vi phân tích S1–S7, không phải chứng nhận phần cứng an toàn.

## Ma trận cấu hình và kích thích

Tất cả WB1, BTALU1, MSingleCycle, BFull, FF RF, Zca, predictor0. Bộ nhớ D1 có
response latency1/grant luôn; event/reset/sleep dùng D4, latency4/grant mỗi3 cycle.
Instruction/data responses in-order; tags và bitmap được model riêng. Clock gate
và RAM primitives thật của checkout, không stub module security.

| Config | Số runs | Điểm khác biệt | Cases |
|---|---:|---|---|
| secure | 21 | RV32I, cache0, L1 | Arithmetic, reset, sleep, DRET/debug+IRQ/NMI-return,4 DIV,4branch,dummy,7fault/response cases |
| secure_offset2 | 6 | L2 | Arithmetic, sleep, reset, DRET, RF/EX faults |
| secure_dual | 6 | CHERIoT On, L1 | Cap live/revoked/trap, invalid mode, cap RF fault, bitmap ECC fault |
| secure_cache | 3 | Cache+ECC+scramble+tweak | Enabled loop/FENCE.I, cache read fault, reset |
| secure_combo | 4 | Dual+cache/ECC/scramble+tweak+PMP | Cap live, cap với cache runtime enabled, revoked và trap |

Secure combo bật PMP trong elaboration nhưng CHERIoT On chọn capability
protection; không gọi đây là bằng chứng PMP region check active trong mode đó.
`secure_combo.cap_cache` có930 cache hits,2 data grants và1 bitmap; các ca cap khác
trong config này dùng cache runtime off. `secure_cache.reset` cũng chưa bật
runtime cache, nên không chứng minh reset giữa pending cache fill.

## Fault matrix và containment

| Case | Điểm / thời gian inject | Detector quan sát | Kết quả kiến trúc / giới hạn |
|---|---|---|---|
| fault1 | XOR bit0 instruction response data mỗi khi valid, giữ ECC cũ | major_bus từ sample5 | Fetch luôn lỗi; không yêu cầu program marker; không suy ra recovery |
| fault2 | XOR bit0 load response, giữ ECC | major_bus sample8, internal ECC NMI | Không ghi x2; mcauseffffffe0, MTVAL208h, handler marker119 |
| fault3 L1/L2 | Force main RF read-A=deadbeef cycles100..109 | Shadow RF ECC samples103/104 | Phát hiện read-data lỗi dù input data được share/delay; không đòi final workload đúng |
| fault4 L1/L2 | Force main result_ex=cafef00d cycles100..109 | Output mismatch samples105/106 | Main đã có thể tạo sai state trước detector; không rollback |
| fault5 dual | cheriot_enable=0 (invalid MuBi) từ100 | Main invalid-mode sample100 | Encoding alarm, không kiểm valid-but-wrong mode transition |
| fault6 | Force main IF PC=deadbeee cycles100..109 | PC checker sample100 | Sequential consistency phát hiện; redirect target authority là đường khác |
| fault7 | Unsolicited data_rvalid ở100, payload/ECC hợp lệ, không pending | Không alert; owner guard | Một legitimate load write, không ghi register ngoài workload, marker123 |
| fault8 dual | Force RF read capability metadata-A=0 cycles100..109 khi loop CGetTag | Shadow RF ECC sample102 | Kiểm cap ECC qualifier, không phải physical SRAM bit campaign |
| fault9 dual | XOR bit0 bitmap data khi response, giữ ECC | Top major_bus sample16 | c2 address1000h, tag0, program marker123; không core internal-NMI như payload ECC |
| fault10 cache | Chụp RAM read-way0 ở350, XOR bit0 rồi force giữ tới354 | Minor từ350, không major | Cache refetch, marker123; một saved codeword giữ4 cycles cũng có thể stale khi addr đổi |

Các mẫu SAMPLE lấy ở negedge+1ns để tránh race giữa counter root và gated clock.
ALERT/C/W/R là các mốc khác nhau. Không lấy `L+1` làm universal detection bound.
Log COUNTS đếm cycles signal high; ví dụ5 minor cycles không phải5 independent faults.
FINISH chỉ là simulator đã tới giới hạn1200 root cycles; program completion phải
có marker/final-register oracle. Những fault phá execution không yêu cầu marker.

## Timing và dummy

DIV123/0: DIT off2 IDcycles, on37. DIV123/7: off/on đều37. Cả hai giữ kết quả đúng
(-1 cho divide-zero,17 cho divide-nonzero). Branch với BTALU: DIT off1 IDcycle,
on2 cho cả taken/not-taken. Đây là execution residence, không chứng minh total
program/cache/memory/power independent of secrets.

Dummy test bật mask000, loop100: có269 accepted dummy instructions trong toàn
run1200 cycles, bao gồm cả terminal loop. Register writes chỉ tới các destinations
của real program (x1,x2,x15), final x2=0/marker123, không alert. Đây không phải
269 dummy trong riêng đoạn benchmark và không phải entropy-quality measurement.

## Findings thiết kế cần giữ khi sử dụng fork này

| ID | Kết luận | Bằng chứng / tác động |
|---|---|---|
| SEC-01 | SecureIbex không tự bật mọi tùy chọn cache/PMP hoặc runtime DIT/dummy | Parameter/CSR map + elaboration; cần kiểm effective configuration |
| SEC-02 | Main RF không giữ ECC; shadow giữ7 bit parity riêng và independently computed | SOURCE + data/cap RF fault SIM; đọc main RegFileECC=0 riêng lẻ sẽ kết luận sai |
| SEC-03 | Scalar RF tuple không compare trực tiếp trong output bundle; complemented ShadowCSR=0 | SOURCE; detection có thể latent tới khi state ảnh hưởng checked path |
| SEC-04 | Lockstep và major alert không tự rollback/halt main side effects | SOURCE + fault cases; alert handling thuộc SoC |
| SEC-05 | Load ECC fault khác synchronous load bus error | SOURCE + fault2: suppress rd, internal NMI, MEPC có thể qua offending instruction |
| SEC-06 | Bus codeword39 không chứa memory capability tag | SOURCE; shared wrong-but-consistent tag cần protection ngoài core |
| SEC-07 | Bitmap fault clear tag + top bus alert, không tự đi vào core data_err | SOURCE + fault9; policy phải đọc đúng loại signal |
| SEC-08 | Cache ECC recovery invalidate/refetch; không dùng corrected decoder data | SOURCE + fault10 clean major outputs, successful marker |
| SEC-09 | DIT chỉ làm phẳng các execution paths đã cài; dummy là LFSR deterministic nếu seed known | SOURCE + DIV/branch/dummy SIM; chưa có power/security measurement |
| SEC-10 | Generic functional simulation không chứng minh physical independence của hai cores | Primitive/source review; layout/clock/reset/test assumptions vẫn còn |

Các findings trên là semantics/limits đã xác định, không tự gắn severity hoặc gọi
mọi giới hạn là vulnerability exploitable. Không phát hiện production RTL defect
được xác nhận bởi bộ directed tests này; điều đó không chứng minh không có defect.

## Một failure của instrumentation đã được cách ly

Verilator5.020 tạo C++ không compile khi `force` trực tiếp một element của
unpacked `ic_data_rdata` array. Thử chuyển force sang `hit_data_ecc_ic1` (biến
được tính bằng `|=` trong always_comb) làm **no-fault run** lỗi. Waveform tại
2765ns cho thấy raw RAM output/tweak đúng nhưng hit mux output bằng OR của
codeword trước và codeword hiện tại:

```text
previous = 3bfff88089950b400113
current  = 3180000807d0fe011ee3
observed = 3bfff8888fd5ff411ff3 = previous | current
```

Bằng chứng thử thất bại được giữ ở [instrumentation_issue](evidence/instrumentation_issue/).
Không tính run có no-fault baseline lỗi đó vào fault coverage. Harness cuối inject
ở packed `data_bank.rdata_o`, tránh array-force và read-modify-write mux variable;
no-fault cache/combo sạch alert, fault10 có minor/refetch như dự đoán. Đây là
kết luận cục bộ về instrumentation/simulator interaction, chưa là upstream bug
report với reproducer tối giản độc lập. Production RTL không được sửa.

## Closure S1–S7

| Plan | Hoàn tất bằng gì | Giới hạn kiểm chứng còn công khai |
|---|---|---|
| S1 | 01 +5 actual elaborated configs và source hashes | Không chạy toàn preset OpenTitan / mọi param combination |
| S2 | 02 +no-fault L1/L2 reset/sleep/debug, RF/EX injection | Không physical separation/counter/comparator exhaustive injection |
| S3 | 03 +IF/load/RF/cap/PC/MuBi/bitmap/unsolicited response cases | Không exhaustive multi-bit/replay/common-mode campaign |
| S4 | 04 +8 timing cases,dummy isolation | Slow M DIT đọc source; không đo entropy/power/leakage |
| S5 | 05 +cache enabled/FENCE.I/key response/refetch fault | Không đánh giá cryptanalysis/key-fault/address-relocation campaign |
| S6 | 05 +secure dual/combo tagged memory & bitmap | Không sweep dynamic valid mode switches/all debug-capability interactions |
| S7 | 06/07 + 31 analysis checks, negative control, links/hashes | Không formal proof, PPA/STA/CDC hoặc silicon validation |

Các giới hạn này là ranh giới validation, không phải chủ đề bị bỏ chưa phân tích.
Plan yêu cầu hiểu cơ chế và kiểm các đường chính bằng directed evidence; không
cam kết exhaustive verification hoặc tapeout readiness.

## Tái lập

```sh
python3 doc/dungpc/secure_ibex/scripts/run_all.py
python3 doc/dungpc/secure_ibex/scripts/summarize_experiments.py
python3 doc/dungpc/secure_ibex/scripts/capture_evidence.py
python3 doc/dungpc/secure_ibex/scripts/validate_evidence.py
```

Runner lưu command JSON, hex, full logs, gzipVCD; build lưu snapshot harness và
runner theo config. Binary C++ ở `/tmp/ibex-extended/`. `--skip-build` chỉ dùng nếu
binary khớp harness/config/source. Macro `prim_assert` bị dummy dưới VERILATOR;
`--assert` không làm chúng tự active. Procedural/Python oracles ở đây hoạt động,
nhưng không phải SVA/formal coverage. Warnings trong build logs được giữ nguyên,
không báo lint-clean. Hashes xác nhận nội dung/dependencies, không chứng minh
semantic correctness độc lập với simulator và checker.
