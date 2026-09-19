# 00 — Baseline manifest

## 1. Source identity

| Item | Snapshot |
|---|---|
| Repository | `/home/dungpc/projects/cpu_fx1/ibex` |
| Branch | `feature/server-work` |
| HEAD | `cdf80233237f33467784cf5737df9eb00f651425` |
| Upstream local master | `90331a69` |
| Top RTL | `rtl/ibex_top.sv` |
| Tracing top | `rtl/ibex_top_tracing.sv` |
| Named configs | `ibex_configs.yaml` |
| Config translator | `util/ibex_config.py` |

HEAD chỉ thêm bộ tài liệu phân tích. Các thay đổi chức năng FX1 vẫn nằm trong
worktree, vì vậy commit ID một mình không tái tạo đúng thiết kế đang phân tích.

## 2. Worktree inputs thuộc baseline

Các file modified ảnh hưởng kết luận L3:

| File | Ảnh hưởng |
|---|---|
| `ibex_configs.yaml` | thêm `fx1_secure_*` và optional fields |
| `rtl/ibex_top.sv` | `ResetAll`/`DummyInstructions` thành top parameters |
| `rtl/ibex_top_tracing.sv` | truyền hai parameters mới |
| `util/ibex_config.py` | phát optional parameters vào tool options |
| `dv/uvm/core_ibex/tb/core_ibex_tb_top.sv` | TB nhận các fields mới |

Các thư mục `out_*`, Verdi logs và FSDB artifacts không phải source-of-truth.

## 3. Reproduction metadata còn thiếu

**Open:** Để biến snapshot thành reproducible sign-off baseline còn cần lưu:

- VCS version;
- GCC/binutils version;
- Spike build/hash;
- FuseSoC version và resolved core graph;
- compile defines;
- exact command line và environment setup;
- checksum của uncommitted patch.

L3 chỉ xác minh static source. Các mục trên chuyển giao cho L4 environment
manifest.

## 4. Source scale và ownership

Core RTL trong `rtl/*.sv` khoảng 25.8 kLOC. External primitives đến từ vendored
lowRISC IP và là dependency chức năng của clock gating, RAM, ECC, FIFO, MuBi và
assertion macros. Phân tích này mô tả cách Ibex sử dụng primitives, không chứng
minh implementation nội bộ của mọi primitive.

## 5. Configuration parser evidence

`ibex_config.py` hiện phát đúng optional fields cho `fx1_secure_dev`:

```text
MemECC=0 DummyInstructions=0 ResetAll=0 DbgHwBreakNum=2
```

và không phát chúng cho `opentitan`, khiến default top áp dụng:

```text
MemECC=SecureIbex
DummyInstructions=SecureIbex
ResetAll=SecureIbex
DbgHwBreakNum=1
```

**Fact:** Đây là khác biệt do “field omitted” so với “field explicitly zero”,
không chỉ do giá trị YAML bình thường.

## 6. Known documentation inconsistency

Comment trong `ibex_configs.yaml` tham chiếu `doc/fx1_secure_config_eval.md`,
nhưng file đó không tồn tại trong snapshot. Các lý do thiết kế ghi trong comment
chưa có design record hoàn chỉnh.

## 7. Review discipline

Trước khi dùng tài liệu này sau một RTL update:

1. kiểm `git rev-parse HEAD`;
2. kiểm `git status --short`;
3. diff năm file baseline ở mục 2;
4. chạy lại config parser cho bốn profile;
5. kiểm state enum/module port có thay đổi;
6. đánh dấu tài liệu affected trước khi sửa nội dung.

## 8. Scope exclusions

- Không phân tích sâu standard-cell/timing-library implementation.
- Không chứng minh CHERIoT ISA compliance từ specification độc lập.
- Không coi assertions hiện có là proof coverage hoàn chỉnh.
- Không dùng old simulation output làm pass evidence nếu command/seed không tái
  tạo được.

## 9. Source anchors

- [`ibex_configs.yaml`](../../../../ibex_configs.yaml)
- [`util/ibex_config.py`](../../../../util/ibex_config.py)
- [`rtl/ibex_top.sv`](../../../../rtl/ibex_top.sv)
- [`core_ibex_tb_top.sv`](../../../../dv/uvm/core_ibex/tb/core_ibex_tb_top.sv)

