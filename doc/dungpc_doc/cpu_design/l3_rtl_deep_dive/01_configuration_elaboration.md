# 01 — Configuration và elaboration

## 1. Parameter truth table

| Parameter | opentitan | fx1 dev | fx1 prod | dev resetall |
|---|---|---|---|---|
| BaseIsa | I-or-CHERIoT | same | same | same |
| RV32M | SingleCycle | Fast | Fast | Fast |
| RV32B | OTEarlGrey | None | None | None |
| RV32ZC | ZcaZcbZcmp | Zca | Zca | Zca |
| BranchTargetALU | 1 | 1 | 1 | 1 |
| WritebackStage | 1 | 1 | 1 | 1 |
| ICache/ECC/Scramble | 1/1/1 | 0/0/0 | 0/0/0 | 0/0/0 |
| BranchPredictor | 0 | 0 | 0 | 0 |
| SecureIbex | 1 | 1 | 1 | 1 |
| MemECC | default 1 | 0 | 0 | 0 |
| DummyInstructions | default 1 | 0 | 0 | 0 |
| ResetAll | default 1 | 0 | 0 | 1 |
| PMP regions | 16 | 16 | 16 | 16 |
| Debug trigger | 1 × 1 | 1 × 2 | off | 1 × 2 |
| HPM count/width | 10/32 | 4/32 | 0/32 | 4/32 |

`fx1_secure_adj` không phải primary profile nhưng giữ RV32B OpenTitan và các
countermeasure mặc định; nó hữu ích làm cầu nối khi root-cause compatibility.

## 2. Derived parameters

Trong `ibex_top`:

```text
Lockstep             = SecureIbex
RegFileECC           = 0
RegFileLockstepECC   = Lockstep
MemDataWidth         = MemECC ? 39 : 32
BusSizeECC           = ICacheECC ? 39 : 32
TagSizeECC           = ICacheECC ? IC_TAG_SIZE+ECC : IC_TAG_SIZE
NumAddrScrRounds     = ICacheScramble ? 2 : 0
```

Trong `ibex_core`:

```text
DataIndTiming = SecureIbex
PCIncrCheck   = SecureIbex
ShadowCSR     = 0
PMPNumChan    = 3
```

**Finding F-CFG-01 (Fact):** FX1 tắt ba countermeasure override nhưng vẫn giữ
lockstep, DIT capability và PC increment check. `SecureIbex` không thể dùng như
một nhãn thay cho countermeasure matrix.

## 3. Active hierarchy matrix

| Block | opentitan | FX1 dev/prod |
|---|---:|---:|
| Main `ibex_core` | active | active |
| WB stage registers | active | active |
| Branch target ALU | active | active |
| `ibex_icache` | active | absent |
| `ibex_prefetch_buffer` | absent | active |
| I-cache RAMs | active | absent |
| Branch predictor | absent | absent |
| Dummy insertion | active | absent |
| Zcmp FSM | active | inactive by parameter |
| Bitmanip datapath | OTEarlGrey | eliminated/constant paths |
| CHERIoT EX | active | active |
| PMP | active in RV32 mode | active in RV32 mode |
| Lockstep shadow core | active | active |
| Memory bus ECC | active | absent |
| Split RF ECC | active | active |
| TRVK | active | active |

## 4. Propagation chain

`Config` có hai nhóm field:

- `known_fields`: mọi named config phải khai báo;
- `optional_fields`: chỉ phát option khi key tồn tại.

`FusesocOpts` và `SimOpts` iterate union của known fields với optional fields có
trong profile. TB khai báo defaults tương ứng top defaults. Vì vậy:

```text
omitted optional key -> top/TB default
explicit 0           -> override default
```

**Invariant I-CFG-01:** Default ở TB wrapper và RTL top phải đồng nhất. Nếu một
file đổi mà file kia không đổi, simulation có thể kiểm khác netlist tích hợp.

## 5. Base ISA runtime selection

`BaseIsaRV32IorCHERIoT` là compile-time choice tạo cả hai đường. `cheriot_enable_i`
là runtime MuBi state chọn semantics. Khi On:

- RF chỉ dùng x0..x15 + capability metadata;
- decoder cho CHERIoT opcodes/semantics;
- PCC bảo vệ fetch;
- capability bảo vệ data;
- PMP results bị gate;
- `misa` I/E/X đổi động.

Assertion cấm chuyển On về Off trước reset.

## 6. ResetAll semantics

`ResetAll` chọn giữa flop payload có asynchronous reset và flop payload chỉ có
clock enable. Valid/control state cần reset bất kể setting.

**Inference I-CFG-02:** Area/reset routing giảm khi bằng 0, nhưng X-propagation và
lockstep equivalence phụ thuộc valid gating hoàn chỉnh. Đây là hypothesis cần L4
reset/X-prop trace, chưa phải kết luận lỗi.

## 7. Unsupported combinations cần tránh suy diễn

- `ICacheECC=1` khi `ICache=0` có thể tạo widths nhưng không tạo cache RAM hữu
  ích; named profiles không dùng tổ hợp này.
- `DbgHwBreakNum>0` không tự bật trigger nếu `DbgTriggerEn=0`.
- `RV32Zca` là mức compressed tối thiểu của tree; comment FX1 nói “off” nhưng
  implementation dùng Zca.
- `SecureIbex=0` loại lockstep và split RF ECC, dù có thể override `MemECC=1`.

## 8. L4 handoff

- Dump elaborated parameters từ VCS cho từng profile.
- So sánh hierarchy thực với bảng mục 3.
- Compile firmware bằng đúng `-march` của từng profile.
- X-prop reset comparison DEV versus DEV-resetall.
- Check trigger CSR behavior DEV versus PROD.

## 9. Source anchors

- [`ibex_configs.yaml`](../../../../ibex_configs.yaml)
- [`util/ibex_config.py`](../../../../util/ibex_config.py)
- [`rtl/ibex_top.sv`](../../../../rtl/ibex_top.sv)
- [`rtl/ibex_core.sv`](../../../../rtl/ibex_core.sv)

