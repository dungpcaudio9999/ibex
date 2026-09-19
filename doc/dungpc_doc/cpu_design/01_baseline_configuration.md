# 01 — Baseline, cấu hình và elaboration

## 1. Vì sao cấu hình phải được đọc trước RTL

Ibex là RTL tham số hóa mạnh. Cùng một file source nhưng netlist có thể là CPU
hai tầng hoặc ba tầng, có hoặc không I-cache, có hoặc không CHERIoT, có hoặc
không lockstep. Vì vậy đơn vị phân tích đúng không phải chỉ là “module Ibex”, mà
là:

```text
commit + worktree diff + named configuration + top module + tool defines
```

Nếu thiếu một thành phần, kết luận như “khối này đang hoạt động” có thể sai ngay
cả khi đoạn SystemVerilog đó có mặt trong source.

## 2. Baseline của tài liệu

Baseline lúc phân tích:

| Thuộc tính | Giá trị |
|---|---|
| Repo | `/home/dungpc/projects/cpu_fx1/ibex` |
| Branch | `feature/server-work` |
| HEAD | `cdf80233` |
| Upstream master tại local | `90331a69` |
| Top chức năng | `rtl/ibex_top.sv` |
| Top có trace | `rtl/ibex_top_tracing.sv` |
| File cấu hình | `ibex_configs.yaml` |

Các file đang được chỉnh sửa cục bộ có ảnh hưởng kiến trúc:

- `ibex_configs.yaml` thêm các profile FX1;
- `rtl/ibex_top.sv` đưa `DummyInstructions` và `ResetAll` thành parameter;
- `rtl/ibex_top_tracing.sv` truyền hai parameter này xuống top;
- `util/ibex_config.py` chấp nhận các trường tùy chọn;
- testbench UVM truyền `RV32ZC`, `MemECC`, `DummyInstructions`, `ResetAll` và
  `DbgHwBreakNum`.

Không được dùng tài liệu này làm bằng chứng sign-off nếu baseline đã đổi mà chưa
review lại diff.

## 3. Các cấu hình cần phân biệt

### 3.1 `opentitan`

Đây là cấu hình đầy đủ nhất trong tree hiện tại:

- `BaseIsaRV32IorCHERIoT`;
- `RV32MSingleCycle`;
- bitmanip `RV32BOTEarlGrey`;
- `RV32ZcaZcbZcmp`;
- pipeline có WB;
- I-cache + ECC + scramble;
- `SecureIbex=1`, PMP 16 vùng;
- 10 HPM counters;
- debug trigger bật.

Do các giá trị mặc định mới trong local worktree, `SecureIbex=1` cũng làm
`MemECC=1`, `DummyInstructions=1`, `ResetAll=1` nếu profile không override.

### 3.2 `fx1_secure_adj`

Giữ tính tương thích OpenTitan tốt hơn nhưng giảm tài nguyên:

- MUL/DIV chuyển sang `RV32MFast`;
- bỏ I-cache;
- chỉ giữ `RV32Zca`;
- còn bitmanip OpenTitan;
- 4 HPM counters;
- các countermeasure dẫn xuất từ `SecureIbex` vẫn bật.

### 3.3 `fx1_secure_dev`

Profile DEV theo cấu hình FX1 cục bộ:

- bỏ bitmanip;
- chỉ `RV32Zca`;
- `RV32MFast`;
- debug trigger bật và có hai hardware breakpoints;
- `MemECC=0`, `DummyInstructions=0`, `ResetAll=0` dù `SecureIbex=1`;
- lockstep, data-independent timing và PC increment check vẫn xuất phát từ
  `SecureIbex=1`.

Đây là tổ hợp cần review cẩn thận nhất: nhãn “secure” không còn đồng nghĩa với
toàn bộ countermeasure mặc định.

### 3.4 `fx1_secure_dev_resetall`

Giống DEV nhưng `ResetAll=1`. Đây là profile chẩn đoán để cô lập ảnh hưởng của
`ResetAll=0` đối với lockstep và trạng thái chưa khởi tạo.

### 3.5 `fx1_secure_prod`

Gần DEV nhưng:

- debug trigger tắt;
- không có HPM counter tùy chọn;
- vẫn đặt `DbgHwBreakNum=2`, nhưng khi `DbgTriggerEn=0` phần trigger không hoạt
  động; con số này không tự bật trigger.

## 4. Parameter dẫn xuất quan trọng

Trong `ibex_top`:

| Đại lượng | Công thức hiện tại | Ý nghĩa |
|---|---|---|
| `Lockstep` | `SecureIbex` | Bật shadow core |
| `RegFileECC` | `0` | Core chính không tự lưu/check ECC RF |
| `RegFileLockstepECC` | `Lockstep` | Core bóng sinh/check ECC RF |
| `MemDataWidth` | `MemECC ? 39 : 32` | Data + 7 bit SECDED khi bật |
| `ICacheTweakInfection` | mặc định `SecureIbex` | Bảo vệ RAM I-cache khỏi sửa địa chỉ/dữ liệu |
| `MaxOutstandingDSideAccesses` | `2` | Tối đa hai request cho một access lệch hàng |

Trong `ibex_core`:

| Đại lượng | Công thức | Ý nghĩa |
|---|---|---|
| `DataIndTiming` | `SecureIbex` | Cho phép thực thi timing không phụ thuộc dữ liệu |
| `PCIncrCheck` | `SecureIbex` | Kiểm tra PC tuần tự tăng đúng 2/4 byte |
| `ShadowCSR` | `0` | Không instantiate shadow copy CSR trong core |
| `PMPNumChan` | `3` | I, I+2 và D |

Điểm cần nhớ: trong worktree hiện tại, `MemECC`, `DummyInstructions` và
`ResetAll` có thể được override độc lập với `SecureIbex`; các localparam còn lại
không như vậy.

## 5. Cây quyết định elaboration

```text
BaseIsa == BaseIsaRV32IorCHERIoT ?
  yes -> ibex_cheriot_ex + capability RF path + TRVK + CHERIoT CSR/SCR
  no  -> tie-off toàn bộ đường capability

SecureIbex ?
  yes -> lockstep + DataIndTiming + PCIncrCheck + secure core_busy encoding
  no  -> một core, logic busy thông thường

ICache ?
  yes -> ibex_icache + RAM tag/data bên ibex_top
  no  -> ibex_prefetch_buffer, không tạo RAM I-cache

WritebackStage ?
  yes -> pipeline IF / ID-EX / WB + forwarding WB->ID
  no  -> WB hoạt động như passthrough

MemECC ?
  yes -> bus nội bộ 39 bit, encode/decode SECDED
  no  -> bus nội bộ 32 bit
```

## 6. Cách xác minh một cấu hình

Trước khi đọc datapath, lập bảng sau cho profile mục tiêu:

| Nhóm | Cần ghi |
|---|---|
| ISA | BaseIsa, RV32E, RV32M, RV32B, RV32ZC |
| Pipeline | BranchTargetALU, WritebackStage, BranchPredictor |
| Memory | ICache, ICacheECC, ICacheScramble, MemECC |
| Privilege | PMPEnable, regions, granularity, HPM |
| Debug | DbgTriggerEn, DbgHwBreakNum |
| Security | SecureIbex, ResetAll, DummyInstructions |

Sau đó kiểm tra ba lớp truyền parameter:

1. YAML được `util/ibex_config.py` đọc đúng.
2. Testbench/FuseSoC truyền đúng vào `ibex_top` hoặc `ibex_top_tracing`.
3. Các `if (Parameter) begin : generate_label` đúng như kỳ vọng.

## 7. Rủi ro cấu hình hiện thấy

1. Comment trong `ibex_configs.yaml` dẫn tới `doc/fx1_secure_config_eval.md`,
   nhưng file này hiện không tồn tại.
2. Các tài liệu cũ ở `doc/dungpc_doc` chủ yếu chốt theo `opentitan`; không thể
   dùng nguyên trạng cho DEV/PROD.
3. `SecureIbex=1` nhưng tắt reset toàn bộ cần chứng minh rằng compare chỉ được
   enable sau khi main/shadow state hội tụ hoặc khởi tạo nhất quán.
4. Tắt `MemECC` làm bus còn 32 bit; cần kiểm tra testbench và SoC integration
   không giả định luôn có 7 bit integrity hữu hiệu.
5. Tắt `RV32BOTEarlGrey` có thể làm firmware OpenTitan không compile hoặc phát
   sinh illegal instruction.

## 8. Điểm vào source

- [`ibex_configs.yaml`](../../../ibex_configs.yaml)
- [`util/ibex_config.py`](../../../util/ibex_config.py)
- [`rtl/ibex_top.sv`](../../../rtl/ibex_top.sv)
- [`rtl/ibex_core.sv`](../../../rtl/ibex_core.sv)
- [`core_ibex_tb_top.sv`](../../../dv/uvm/core_ibex/tb/core_ibex_tb_top.sv)

