# 02 — Deep dive `ibex_top`

## 1. Contract

`ibex_top` là biên CPU/SoC và sở hữu clock gate, external bus adaptation,
physical RF, I-cache RAM, lockstep, TRVK và alert aggregation. `ibex_core` chỉ
sở hữu pipeline/architectural control.

## 2. Port domains

| Domain | Contract |
|---|---|
| Clock/reset/test | `clk_i`, active-low reset, clock-gate test enable, scan reset |
| I-side | decoupled request/grant và response/error/integrity |
| D-side | request/grant, response, byte enable, tag và integrity |
| TRVK bitmap | read-only request/grant/response port riêng |
| IRQ/debug | software/timer/external/fast/NMI, debug request/crash dump |
| Scramble | key-valid/key/nonce/request handshake |
| MuBi controls | fetch, counter policy, CHERIoT runtime enable |
| Alerts | minor, major internal, major bus |
| Lockstep observability | compare enable và shadow bus request outputs |

## 3. Clock-enable state

Với secure profile, `core_busy_q` là MuBi flop. `clock_en` xét busy cùng pending
interrupt/debug/test. `prim_clock_gating` tạo `clk` dùng cho main core, RF, RAM,
lockstep và TRVK.

**Invariant I-TOP-01:** Mọi event có thể làm core tiến khi đang sleep phải có
đường mở clock không phụ thuộc `clk` đã bị gate. CSR `mip` vì vậy lấy IRQ pins
tổ hợp.

## 4. Main-core instantiation

Top truyền toàn bộ ISA/pipeline/cache/security parameters xuống `u_ibex_core`.
Data/instruction response được ghép thành `MemDataWidth`; RF interface có data
32 bit và capability 35 bit.

Main core cố định `RegFileECC=0`. ECC RF không mất: nó được thực hiện qua shadow
core/RF khi lockstep active.

## 5. Physical register file generate

Ba branches `RegFileFF`, `RegFileFPGA`, `RegFileLatch` có cùng logical port.
Named profiles dùng FF.

Trong dual ISA:

- `rf_data[16]` giữ x0..x15 data;
- `rf_shared[16]` giữ x16..x31 data ở RV32 hoặc cap metadata ở CHERIoT;
- dummy mode có handling x0 vật lý riêng;
- write data/cap phải cùng destination và enable policy.

**Critical candidate:** RF combinational read → forwarding/operand mux → ALU.

## 6. I-cache physical RAM

Cache controller trong IF, RAM ở top. Generate matrix:

| ICache | Scramble | RAM implementation |
|---:|---:|---|
| 0 | any | tie-off |
| 1 | 0 | `prim_ram_1p` tag/data per way |
| 1 | 1 | `prim_ram_1p_scr` tag/data per way |

Scramble branch quản lý effective key/nonce, address-scramble rounds và RAM
alerts. OpenTitan active; FX1 loại toàn bộ RAM tree.

## 7. Bus integrity adaptation

`MemECC=1`:

```text
instr_rdata_core = {instr_rdata_intg_i, instr_rdata_i}
data_rdata_core  = {data_rdata_intg_i, data_rdata_i}
data_wdata_core  -> split data_wdata_o + integrity_o
```

`MemECC=0`: core buses rộng 32, input integrity được đánh dấu unused và output
integrity được tie-off. TRVK vẫn tồn tại nhưng bitmap ECC checking cũng theo
`MemECC`.

## 8. Lockstep boundary

Khi `SecureIbex=1`, top buffer main inputs/outputs trước khi đưa vào
`ibex_lockstep`. Buffers là anchor chống synthesis gộp common logic. Shadow core
không lái external bus; outputs được compare và một phần được đưa ra quan sát.

Khi lockstep absent, shadow outputs và alerts đều tie-off xác định.

## 9. TRVK insertion

Trong dual ISA branch:

```text
core D-side -> trvk_* internal -> ibex_trvk -> external data_*
```

Trong non-CHERIoT branch, internal core D-side nối trực tiếp external port và
bitmap outputs tie-off. TRVK tồn tại theo compile-time BaseIsa, không theo
runtime `cheriot_enable_i`; nó forward normal RV32 transactions nhưng chỉ lookup
tagged capability response.

## 10. Alert aggregation equations

```text
major_internal = core_internal | lockstep_internal | icache_ram_alert
major_bus      = core_bus | lockstep_bus
               | trvk_bitmap_integrity | trvk_bitmap_device_error
minor          = core_minor | lockstep_minor
```

Assertions yêu cầu outputs không X. Bus ECC assertions yêu cầu response ECC
error dẫn tới major bus alert trong bounded window.

## 11. External transaction assertions

Top theo dõi tối đa hai D-side outstanding entries vì một access lệch hàng có
thể phát hai requests. Properties cần bảo đảm:

- request payload ổn định đến grant;
- response chỉ đến cho request đã grant;
- ordering phù hợp LSU/TRVK assumptions;
- error/integrity không bị mất;
- secure and non-secure branches đều tie-off unused signals.

## 12. Reset behavior

Top reset clock/busy/lockstep control. RF reset semantics phụ thuộc
`ResetAll`/dummy/security. Scrambled RAM reset không đồng nghĩa clear toàn RAM;
cache invalidate/key protocol tạo validity boundary.

**Open O-TOP-01:** Với FX1 `ResetAll=0`, cần L4/Gate-X evidence rằng compare
bundle không quan sát uninitialized payload trước valid state.

## 13. L4 handoff

Signals: `clock_en`, `core_busy_q`, `instr_*`, `trvk_*`, `data_*`,
`lockstep_cmp_en_o`, three alerts, RF write/read, active RAM requests.

Scenarios: WFI wakeup, outstanding-2 misaligned access, MemECC on/off, main/
shadow alignment, TRVK forward in RV32 mode.

## 14. Source anchors

- [`rtl/ibex_top.sv`](../../../../rtl/ibex_top.sv)
- [`rtl/ibex_register_file_ff.sv`](../../../../rtl/ibex_register_file_ff.sv)
- [`rtl/ibex_lockstep.sv`](../../../../rtl/ibex_lockstep.sv)
- [`rtl/ibex_trvk.sv`](../../../../rtl/ibex_trvk.sv)

