# 01 — Đóng băng thiết kế và chứng minh cấu hình

Baseline là preset **`opentitan` của checkout này**, revision
`ec501f4ce5a7e492e1becb48b31200019ec5200b`. Tên preset không chứng minh rằng đây
là netlist CPU của một release OpenTitan upstream. Phân tích bao gồm các mở rộng
CHERIoT đang có tại checkout, không suy diễn thông số từ một OpenTitan khác.
Không thay đổi production RTL hoặc `ibex_configs.yaml`.

## Chuỗi cấu hình

```text
ibex_configs.yaml : opentitan
    → util/ibex_config.py opentitan fusesoc_opts
    → parameter overrides của ibex_top
    → localparams / generate tại top
    → main core, shadow core, RF ECC, cache RAM wrappers
    → localparams / generate của mỗi core
```

Trong thí nghiệm, Python đọc chính YAML và sinh named parameter include. Verilator
elaborate `ibex_top` với include đó; không dựng một config “gần giống” bằng vài
macro SEC/CACHE. Các hằng cùng tên trong harness chỉ phục vụ instrumentation.
File XML sau elaboration được đọc lại để đối chiếu **19/19 parameter**; enum
được giải nghĩa độc lập từ `ibex_pkg.sv`. Script chính thức tạo FuseSoC options
được chạy và lưu, nhưng không có FuseSoC cài trong môi trường để chạy target đó.

| Nhóm | Giá trị YAML chính xác | Hệ quả thiết kế |
|---|---|---|
| Base ISA | `BaseIsaRV32IorCHERIoT`, `RV32E=0` | Dual ISA bằng runtime MuBi; shared RF bank |
| M/B/ZC | `RV32MSingleCycle`, `RV32BOTEarlGrey`, `RV32ZcaZcbZcmp` | Fast multiplier/divider; đúng tập B của decoder; có Zcmp expander |
| Pipeline | `RegFileFF`, `BranchTargetALU=1`, `WritebackStage=1` | RF FF, ALU tính target riêng, WB có state riêng |
| Frontend | `ICache=1`, `BranchPredictor=0` | Có cache frontend; nhánh dự đoán/skid tương ứng bị loại |
| Cache protection | `ICacheECC=1`, `ICacheScramble=1` | Tag/data codewords và scrambled RAM |
| Secure | `SecureIbex=1` | Delayed lockstep, dummy support, DIT support, kiểm PC/MuBi |
| PMP | `PMPEnable=1`, `PMPGranularity=0`, `PMPNumRegions=16` | 16 region; granularity nhỏ nhất; CSR reset vẫn cần xét riêng |
| Debug | `DbgTriggerEn=1` | Có execute trigger; số trigger lấy default |
| Counters | `MHPMCounterNum=10`, `MHPMCounterWidth=32` | Counter 3…12, mỗi counter 32 bit |

Nguồn: [YAML](../../../ibex_configs.yaml),
[config utility](../../../util/ibex_config.py),
[top parameters](../../../rtl/ibex_top.sv#L16),
[enum definitions](../../../rtl/ibex_pkg.sv#L41).

## Default và giá trị suy ra cần giữ trong design review

| Tầng | Giá trị thực tế | Điểm dễ hiểu sai |
|---|---|---|
| Top default | `LockstepOffset=1`, `MemECC=1`, `MemDataWidth=39` | Không dùng offset 2 của thí nghiệm cũ |
| Top default | `ICacheTweakInfection=1`; PRINCE half-round parameter 2 | Scramble có cả tweak path, không chỉ XOR key |
| Debug | `DbgHwBreakNum=1`; base `0x1a110000`, mask `0xfff`, halt `0x1a110800`, exception `0x1a110808` | Harness giữ nguyên địa chỉ, dùng ROM riêng |
| TRVK | Bitmap address width 11, bitmap base 0 | Heap base là input SoC, không phải YAML |
| Top local | `Lockstep=ResetAll=DummyInstructions=1` | Là hardware support, khác các CSR runtime enable |
| Main core | `RegFileECC=0` | Không có decoder RF ECC main |
| Shadow core | `RegFileECC=1` | RF parity và kiểm ECC ở đường shadow |
| Cả hai core | `DataIndTiming=1`, `PCIncrCheck=1`, `ShadowCSR=0` | Có hai bản CSR do hai core; không bật cơ chế ShadowCSR trong mỗi bản |
| RAM scrambler | Address rounds 2; diffusion rounds 0; wrapper parity 0 | ECC nằm ở cache; không được cộng một lớp parity tưởng tượng |
| RAM scrambler | ReplicateKeyStream: tag 0, data 1 | Hai loại bank không hoàn toàn giống nhau |

PRNG seed/permutation, initial key/nonce, PMP reset arrays và các identification
CSR cũng giữ default của top. Chúng được archive trong XML/hierarchy đầy đủ;
không xem các constant mặc định trong mô phỏng là chính sách provisioning cho chip.

Nguồn: [top localparams](../../../rtl/ibex_top.sv#L212),
[core localparams](../../../rtl/ibex_core.sv#L195),
[resolved hierarchy](evidence/hierarchy.json),
[parameter checks](evidence/parameter_checks.json).

## Đọc cấu hình theo cách của người thiết kế CPU

Trước khi hỏi “khối này làm gì”, xác định nhánh generate nào tồn tại, register
nào được nhân đôi, và tín hiệu nào vẫn là runtime input. Cụ thể: không có
branch predictor trong thiết kế này; cache vẫn tồn tại khi CSR cache enable
bằng 0; main/shadow không phải hai CPU chạy workload độc lập; hai ISA chia sẻ
phần cứng RF; `SingleCycle` không có nghĩa mọi lệnh M hoàn tất trong một cycle.

So với baseline tài liệu cũ `fc3b3dd6`, diff của RTL, YAML, config utility và hai
thư mục primitive được kiểm tra là rỗng. Kết quả cũ có thể làm tài liệu tham
chiếu cơ chế, nhưng các run cũ không thay thế bằng chứng cho đúng preset này.
Xem [baseline và tool version](evidence/baseline.json),
[dependency hashes](evidence/source_dependencies_sha256.json),
[build command](evidence/build.command.json),
[generated parameters](evidence/opentitan_params.svh).
