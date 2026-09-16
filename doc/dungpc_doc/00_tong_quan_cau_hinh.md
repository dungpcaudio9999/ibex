# 00 — Tổng quan cấu hình `opentitan`

## 1. Khai báo gốc

`ibex/ibex_configs.yaml:41-60`:

```yaml
opentitan:
  BaseIsa                  : "ibex_pkg::BaseIsaRV32IorCHERIoT"
  RV32E                    : 0
  RV32M                    : "ibex_pkg::RV32MSingleCycle"
  RV32B                    : "ibex_pkg::RV32BOTEarlGrey"
  RV32ZC                   : "ibex_pkg::RV32ZcaZcbZcmp"
  RegFile                  : "ibex_pkg::RegFileFF"
  BranchTargetALU          : 1
  WritebackStage           : 1
  ICache                   : 1
  ICacheECC                : 1
  ICacheScramble           : 1
  BranchPredictor          : 0
  DbgTriggerEn             : 1
  SecureIbex               : 1
  PMPEnable                : 1
  PMPGranularity           : 0
  PMPNumRegions            : 16
  MHPMCounterNum           : 10
  MHPMCounterWidth         : 32
```

## 2. Ý nghĩa vi kiến trúc từng tham số

| Tham số | Giá trị | Hệ quả vi kiến trúc |
|---|---|---|
| `BaseIsa` | `BaseIsaRV32IorCHERIoT` | Sinh **toàn bộ** datapath CHERIoT: `ibex_cheriot_ex`, SCR trong `ibex_cs_registers`, cổng capability của register file, `ibex_trvk` ở `ibex_top`. Bật/tắt lúc chạy bằng `cheriot_enable_i`. |
| `RV32E` | 0 | Register file RV32I 32 thanh ghi khi CHERIoT tắt. Khi CHERIoT bật thì **luôn** chỉ dùng x0–x15 (E ngầm định). |
| `RV32M` | `RV32MSingleCycle` | `ibex_multdiv_fast` với **3 bộ nhân 17×17**. MUL = 1 chu kỳ, MULH = 2 chu kỳ. Chia dùng long-division 37 chu kỳ. |
| `RV32B` | `RV32BOTEarlGrey` | Zba+Zbb+Zbc+Zbs **cộng** các phần chưa phê chuẩn: `shfl/unshfl`, `xperm.n/b/h`, `slo/sro`, `grev/gorc`, `clmul/clmulr/clmulh`, `crc32[c].b/h/w`. **Không** có nhóm ternary (`cmov/cmix/fsl/fsr` dạng Zbt đầy đủ vẫn có qua shifter), `bcompress/bdecompress`, `bfp` (chỉ `RV32BFull`). |
| `RV32ZC` | `RV32ZcaZcbZcmp` | Compressed decoder có **FSM Zcmp** (`cm.push/pop/popret/popretz/mvsa01/mva01s`) bung thành chuỗi micro-op. |
| `RegFile` | `RegFileFF` | `ibex_register_file_ff` — flop-based, hỗ trợ bank `rf_shared` dùng chung cho x16–x31 (RV32I) hoặc metadata capability (CHERIoT). |
| `BranchTargetALU` | 1 | ALU cộng riêng 32-bit trong `ibex_ex_block` → jump 0 stall, taken-branch 1 stall. |
| `WritebackStage` | 1 | **Pipeline 3 tầng** IF / ID-EX / WB. Bật forwarding WB→ID, stall load-use, exception chính xác từ WB. |
| `ICache` | 1 | `ibex_icache` thay cho `ibex_prefetch_buffer`. 4 KiB, 2 way, line 64-bit. |
| `ICacheECC` | 1 | SECDED trên tag (28,22) và data (39,32) mỗi beat. |
| `ICacheScramble` | 1 | RAM `prim_ram_1p_scr` (PRINCE 2 half-round, 2 vòng address scramble), key 128-bit / nonce 64-bit từ OTP. |
| `BranchPredictor` | 0 | Không có skid buffer, không `nt_branch_mispredict`, `ibex_branch_predict` không được instantiate. |
| `DbgTriggerEn` | 1 | 1 trigger (`DbgHwBreakNum=1` mặc định) so khớp `pc_if` với `tdata2`. |
| `SecureIbex` | 1 | Kích hoạt **7 localparam dẫn xuất** (bảng dưới) — xem [11_security.md](11_security.md). |
| `PMPEnable` | 1 | `ibex_pmp` với 16 vùng, 3 kênh (I, I2, D), hỗ trợ Smepmp/ePMP. |
| `PMPGranularity` | 0 | So sánh xuống tới bit địa chỉ [2] → granularity 4 byte. |
| `MHPMCounterNum` | 10 | `mhpmcounter3` … `mhpmcounter12` được instantiate. |
| `MHPMCounterWidth` | 32 | Các HPM counter rộng 32 bit (mcycle/minstret vẫn 64 bit). |

## 3. Tham số dẫn xuất từ `SecureIbex = 1`

`ibex/rtl/ibex_top.sv:212-216` và `ibex/rtl/ibex_core.sv:194-197`:

| Localparam | Nơi khai báo | Giá trị | Ý nghĩa |
|---|---|---|---|
| `Lockstep` | `ibex_top.sv:212` | 1 | Instantiate `ibex_lockstep` chứa một `ibex_core` bóng |
| `ResetAll` | `ibex_top.sv:213` | 1 | **Mọi** flop có reset bất đồng bộ (kể cả flop dữ liệu) → lõi chính và lõi bóng khởi động đồng nhất |
| `DummyInstructions` | `ibex_top.sv:214` | 1 | Instantiate `ibex_dummy_instr`, x0 trở thành thanh ghi vật lý thật |
| `RegFileECC` | `ibex_top.sv:215` | **0** | Lõi **chính** không tự sinh/kiểm ECC cho RF |
| `RegFileLockstepECC` | `ibex_top.sv:216` | 1 | Lõi **bóng** mới là nơi sinh/kiểm ECC — xem §4 |
| `MemECC` | `ibex_top.sv:41` | 1 (`= SecureIbex`) | `MemDataWidth = 39`, SECDED inverted 39/32 trên cả I-side và D-side |
| `ICacheTweakInfection` | `ibex_top.sv:45` | 1 | XOR "tweak" địa chỉ vào dữ liệu/tag trước khi ghi RAM I$ |
| `DataIndTiming` | `ibex_core.sv:195` | 1 | Cho phép bit `cpuctrl.data_ind_timing` — nhánh và chia có thời gian cố định |
| `PCIncrCheck` | `ibex_core.sv:196` | 1 | So sánh `pc_if` với `pc_id + 2/4` để phát hiện lỗi luồng điều khiển |
| `ShadowCSR` | `ibex_core.sv:197` | **0** | Hard-code 0 → `csr_shadow_err` luôn bằng 0 trong cấu hình này |
| `LockstepOffset` | `ibex_top.sv:41` | 1 | Lõi bóng trễ đúng **1 chu kỳ** so với lõi chính |

> **Điểm dễ nhầm #1:** `RegFileECC = 0` ở lõi chính. Bảo vệ ECC cho register file được
> thực hiện "chẻ đôi": lõi chính lưu 32 bit dữ liệu, lõi bóng lưu 7 bit ECC, và
> **lõi bóng** chạy `prim_secded_inv_39_32_dec` trên phần ghép. Chi tiết §4.

> **Điểm dễ nhầm #2:** `ShadowCSR = 0`. Tức là cấu hình `opentitan` ở repo này
> **không** có shadow copy cho các CSR (`ibex_csr.ShadowCopy` luôn 0), khác với mô tả
> trong một số tài liệu Ibex cũ.

## 4. Sơ đồ bảo vệ ECC cho Register File

```
                    ibex_top
   ┌───────────────────────────────────────────────────────────────┐
   │  ibex_core (chính)              register_file_i               │
   │  RegFileECC=0                   DataWidth=32, CapWidth=35     │
   │  RegFileDataWidth=32   ───────► lưu 32 bit data + 35 bit cap  │
   │                        ◄─────── rf_rdata_a/b (32b)            │
   │                                 rf_rcap_a/b  (35b)            │
   │                                                                │
   │  ibex_lockstep                                                 │
   │   ├ ibex_core (bóng)            register_file_shadow_i        │
   │   │  RegFileECC=1               DataWidth = 39-32 = 7         │
   │   │  RegFileDataWidth=39  ─────► lưu 7 bit ECC data           │
   │   │                              + 7 bit ECC cap              │
   │   │  rf_rdata_a_ecc_i = {shadow_rf_rdata_a_intg[6:0],          │
   │   │                      main_rf_rdata_a[31:0]}  ← 39 bit      │
   │   │  → prim_secded_inv_39_32_dec → rf_ecc_err_comb            │
   │   │  → alert_major_internal_o                                 │
   └───────────────────────────────────────────────────────────────┘
```

Tham chiếu: `ibex_top.sv:1215-1222` (RegFileDataEccWidth=39, RegFileCapEccWidth=REGCAP_W+7=42),
`ibex_lockstep.sv:636-668` (shadow RF với `DataWidth = RegFileDataEccWidth - RegFileDataWidth`,
`CapWidth = 7`), `ibex_core.sv:1214-1330` (khối `gen_regfile_ecc`).

Capability ECC dùng `prim_secded_inv_64_57`: 35 bit cap được zero-pad lên 57 bit, chỉ 7 bit
check `[63:57]` được lưu. Lỗi cap ECC chỉ được tính khi `cheriot_enable_i == IbexMuBiOn`
(`ibex_core.sv:1281-1292`).

## 5. Tham số I-Cache dẫn xuất

`ibex_pkg.sv:396-415`:

| Hằng | Công thức | Giá trị |
|---|---|---|
| `IC_SIZE_BYTES` | — | 4096 |
| `IC_NUM_WAYS` | — | 2 |
| `IC_LINE_SIZE` | — | 64 bit |
| `IC_LINE_BYTES` | 64/8 | 8 |
| `IC_LINE_W` | clog2(8) | 3 |
| `IC_NUM_LINES` | 4096/2/8 | **256** |
| `IC_LINE_BEATS` | 8/4 | **2** |
| `IC_LINE_BEATS_W` | clog2(2) | 1 |
| `IC_INDEX_W` | clog2(256) | **8** |
| `IC_INDEX_HI` | 8+3-1 | 10 |
| `IC_TAG_SIZE` | 32-8-3+1 | **22** (21 bit tag + 1 bit valid) |
| `IC_OUTPUT_BEATS` | 4/2 | 2 |
| `TagSizeECC` | 22+6 | **28** |
| `BusSizeECC` | 32+7 | **39** |
| `LineSizeECC` | 39×2 | **78** |

→ RAM thực tế: 2 × `prim_ram_1p_scr(Width=28, Depth=256)` cho tag,
2 × `prim_ram_1p_scr(Width=78, Depth=256)` cho data.
Số fill buffer `NUM_FB = 4`, ngưỡng throttle `FB_THRESHOLD = 2` (`ibex_icache.sv:71-73`).

## 6. ISA được hỗ trợ

### 6.1 Chế độ RV32I (`cheriot_enable_i != IbexMuBiOn`)

`RV32IMCB_Zicsr_Zifencei` + Zba/Zbb/Zbc/Zbs + phần mở rộng OpenTitan Earl Grey.
`misa` = `ibex_cs_registers.sv:188-210`, với bit I=1, E=0, X = (`RV32BExtra != 0`).

Chi tiết nhóm bitmanip bật trong `RV32BOTEarlGrey`:

| Nhóm | Lệnh |
|---|---|
| Zba | `sh1add`, `sh2add`, `sh3add` |
| Zbb | `andn`,`orn`,`xnor`,`clz`,`ctz`,`cpop`,`max[u]`,`min[u]`,`sext.b`,`sext.h`,`rol`,`ror[i]`,`rev8`,`orc.b` |
| Zbs | `bset[i]`,`bclr[i]`,`binv[i]`,`bext[i]` |
| Zbc | `clmul`,`clmulh`,`clmulr` |
| Ngoài chuẩn | `shfl[i]`,`unshfl[i]`,`xperm.n/b/h`,`slo[i]`,`sro[i]`,`grev[i]`,`gorc[i]`,`crc32.b/h/w`,`crc32c.b/h/w` |

### 6.2 Chế độ CHERIoT (`cheriot_enable_i == IbexMuBiOn`)

* `misa`: bit **E = 1**, **I = 0**, **X = 1**; `marchid` = `32'hce1` (`ibex_pkg.sv:728`).
* Chỉ dùng **x0–x15** (`ibex_decoder.sv:207-223` cắt `raddr[3:0]`); truy cập x16–x31 → illegal.
* Opcode mới: `OPCODE_CHERI = 7'h5b`, `OPCODE_AUICGP = 7'h7b` (`ibex_pkg.sv:84-85`).
* Các opcode RV32I được **tái định nghĩa** sang CHERIoT: `JAL`, `JALR`, `AUIPC`,
  `LOAD` funct3=`011` → `CLC`, `STORE` funct3=`011` → `CSC`.
* ePMP bị **cổng về 0** (`ibex_core.sv:1629-1636`) — kiểm tra bound/permission do capability đảm nhiệm.
* `mtvec` chỉ chế độ direct: `exc_pc = {csr_mtvec[31:2], 2'b00}` cho cả exception lẫn IRQ
  (`ibex_if_stage.sv:220-230`).
* Exception mới `ExcCauseCheriFault = 28` (`ibex_pkg.sv:378-379`).

> Assertion `CheriotEnableOneWaySwitch` (`ibex_core.sv:1346-1348`): một khi
> `cheriot_enable_i` lên `IbexMuBiOn` thì phải giữ mãi đến khi reset.
> Mã hoá MuBi sai (không phải On cũng không phải Off) → `alert_major_internal_o`.

## 7. Giao diện bus của `ibex_top` trong cấu hình này

| Nhóm | Tín hiệu | Ghi chú cấu hình opentitan |
|---|---|---|
| I-side | `instr_req/gnt/rvalid/addr/rdata[31:0]/rdata_intg[6:0]/err` | `rdata_intg` được dùng (MemECC=1) |
| D-side | `data_req/gnt/rvalid/we/be/addr/wdata/wdata_intg/tag_o/rdata/rdata_intg/tag_i/err` | Có **tag bit** cho capability; đi qua `ibex_trvk` |
| Revocation bitmap | `trvk_revbm_req/gnt/rvalid/addr/rdata/rdata_intg/err` | Chỉ tồn tại vì `BaseIsa == BaseIsaRV32IorCHERIoT` |
| Scramble | `scramble_key_valid_i/key_i/nonce_i/scramble_req_o` | Bật vì `ICacheScramble=1` |
| RAM cfg | `ram_cfg_icache_tag_i/o`, `ram_cfg_icache_data_i/o` | 2 way mỗi loại |
| Lockstep | `lockstep_cmp_en_o`, `data_*_shadow_o`, `instr_*_shadow_o` | Bật vì `SecureIbex=1` |
| Alert | `alert_minor_o`, `alert_major_internal_o`, `alert_major_bus_o` | |
| Điều khiển | `fetch_enable_i` (MuBi), `mcounteren_writable_i` (MuBi), `cheriot_enable_i` (MuBi) | |

Tối đa **2 giao dịch D-side outstanding** (`MaxOutstandingDSideAccesses = 2`,
`ibex_top.sv:233`) — do một lệnh load/store lệch hàng sinh 2 truy cập.
