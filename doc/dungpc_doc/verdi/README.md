# Verdi signal file cho Ibex — cấu hình `opentitan`

| File | Mô tả |
|---|---|
| `ibex_opentitan.rc` | Verdi/nWave signal file: **148 tín hiệu / 16 nhóm** |
| `open_waves.sh` | Script mở Verdi kèm signal file |

## Đã kiểm chứng

File này **không phải viết tay theo suy đoán**:

1. Mọi đường dẫn được trích từ RTL thật (kể cả nhãn generate-block như
   `gen_icache`, `g_cheriot_ex`, `gen_multdiv_fast`, `gen_lockstep`).
2. Toàn bộ 148 tên tín hiệu được đối chiếu với khai báo trong `rtl/*.sv`.
3. **Round-trip qua Verdi**: nạp bằng `-sswr` rồi `wvSaveSignal` ra lại →
   trả về đúng **148 addSignal / 16 addGroup**, **0 warning, 0 error**.
   Verdi tự resolve được bit-width (`pc_id[31:0]`, `fill_busy_q[3:0]`,
   `inval_state_q[1:0]`…) → chứng tỏ hierarchy khớp thiết kế đã elaborate.

## Cách dùng

```bash
# Cách nhanh nhất
./open_waves.sh

# Chỉ định test khác
./open_waves.sh riscv_rand_instr_test.3

# Chỉ định FSDB bất kỳ
./open_waves.sh /duong/dan/waves.fsdb
```

Hoặc gọi Verdi trực tiếp:

```bash
verdi -ssf out/run/tests/riscv_arithmetic_basic_test.1/waves.fsdb \
      -sswr doc/dungpc_doc/verdi/ibex_opentitan.rc &
```

Trong nWave đang mở: **File → Restore Signal…** rồi chọn `ibex_opentitan.rc`.

> File **không bị buộc** vào một FSDB cụ thể (không chứa `openDirFile`), nên dùng lại
> được cho mọi test miễn là cùng testbench `core_ibex_tb_top`.

## 16 nhóm tín hiệu

| Nhóm | Số tín hiệu | Nội dung | Tài liệu liên quan |
|---|---|---|---|
| `00_TB_CLK` | 2 | `clk`, `rst_n` | — |
| `01_RVFI_RETIRE` | 10 | RVFI: `valid/order/insn/pc_rdata/pc_wdata/rd_addr/rd_wdata/trap/intr/mode` | đối chiếu với Spike cosim |
| `02_IF_FETCH_BUS` | 8 | Bus I-side + `pc_if` + `instr_req_gated`/`instr_exec` | [03_tang_IF](../03_tang_IF.md) |
| `03_ICACHE` | 11 | IC0/IC1, fill buffer, FSM invalidate, skid buffer | [04_icache](../04_icache.md) |
| `04_IF_ID_REG` | 9 | Thanh ghi IF/ID + lỗi fetch + vi phạm PCC | [03_tang_IF](../03_tang_IF.md) §7 |
| `05_ID_CONTROLLER` | 14 | `ctrl_fsm_cs`, `id_fsm_q`, `pc_set/pc_mux`, `exc_cause` | [05_tang_ID](../05_tang_ID.md) §2 |
| `06_STALL_HAZARD` | 9 | Toàn bộ `stall_*` + `ready_wb` | [12_pipeline_timing](../12_pipeline_timing.md) §2 |
| `07_REGFILE` | 9 | Địa chỉ/dữ liệu RF + đường forwarding | [05_tang_ID](../05_tang_ID.md) §4 |
| `08_EX_ALU_MULDIV` | 11 | ALU, branch, FSM chia (`md_state_q`, `div_counter_q`) | [06_tang_EX](../06_tang_EX.md) |
| `09_CHERIOT_EX` | 11 | Operator CHERIoT, `addr_bound_vio`, `perm_vio_vec` | [07_cheriot_ex](../07_cheriot_ex.md) |
| `10_LSU_FSM` | 13 | `ls_fsm_cs`, `cap_rx_fsm_q`, lỗi load/store | [08_lsu](../08_lsu.md) §5 |
| `11_DATA_BUS` | 10 | Bus D-side, gồm cả `data_tag_o/i` (capability) | [08_lsu](../08_lsu.md) |
| `12_WB_STAGE` | 5 | `rf_write_wb`, `outstanding_load/store_wb` | [09_tang_WB](../09_tang_WB.md) |
| `13_CSR` | 10 | `priv_lvl_q`, `mstatus/mepc/mcause/mtval/mtvec`, `mip/mie` | [10_csr_pmp_counter](../10_csr_pmp_counter.md) |
| `14_IRQ_DEBUG` | 6 | `irq_pending_o`, `nmi_mode`, `debug_mode`, `handle_irq` | [12_pipeline_timing](../12_pipeline_timing.md) §5 |
| `15_ALERT_SECURITY` | 10 | 3 mức alert + `rf_ecc_err_comb`, `pc_mismatch_alert`, lockstep `outputs_mismatch` | [11_security](../11_security.md) |

## Nhóm nào quan trọng cho từng test

`riscv_arithmetic_basic_test` (test mặc định) sinh với
`+no_branch_jump=1 +no_data_page=1 +no_fence=1` → **không có load/store, không branch/jump**.
Với test này:

* **Tập trung**: `01`, `02`, `04`, `05`, `06`, `07`, `08`
* **Gần như im lặng**: `10_LSU_FSM`, `11_DATA_BUS` (có thể collapse lại)
* **Chỉ hoạt động nếu bật CHERIoT**: `09_CHERIOT_EX`

Test khác nên mở thêm:

| Test | Nhóm cần xem |
|---|---|
| `riscv_mmu_stress_test`, `riscv_load_store_*` | `10`, `11` |
| `riscv_debug_*`, `riscv_dret_test` | `14`, `13` |
| `riscv_irq_*`, `riscv_nested_irq_test` | `14`, `05`, `13` |
| `core_ibex_*_intg_test`, `core_ibex_pc_intg_test` | `15` |
| `core_ibex_icache_intg_test` | `03`, `15` |

## Hierarchy tham chiếu

```
core_ibex_tb_top
├── clk, rst_n
├── rvfi_if/                                    ← RVFI interface
└── dut/                                        (ibex_top_tracing)
    └── u_ibex_top/                             (ibex_top)
        ├── core_sleep_o
        ├── u_ibex_core/                        (ibex_core)
        │   ├── if_stage_i/gen_icache/icache_i/ (ibex_icache)
        │   ├── id_stage_i/                     (ibex_id_stage)
        │   │   └── controller_i/               (ibex_controller)
        │   ├── ex_block_i/
        │   │   └── gen_multdiv_fast/multdiv_i/ (ibex_multdiv_fast)
        │   ├── g_cheriot_ex/u_ibex_cheriot_ex/ (ibex_cheriot_ex)
        │   ├── load_store_unit_i/              (ibex_load_store_unit)
        │   ├── wb_stage_i/                     (ibex_wb_stage)
        │   └── cs_registers_i/                 (ibex_cs_registers)
        ├── gen_regfile_ff/register_file_i/
        ├── gen_lockstep/u_ibex_lockstep/
        └── gen_cheriot_trvk/i_ibex_trvk/
```

## Thêm tín hiệu của riêng bạn

Cú pháp trong `.rc`:

```
addGroup "TEN_NHOM"
addSignal -h 16 /duong/dan/tuyet/doi/tin_hieu
addSignal -h 16 -holdScope ten_tin_hieu_cung_scope
addSignal -h 16 -UNSIGNED -HEX /duong/dan/vector[31:0]
```

* `-h 16` = chiều cao dòng
* `-holdScope` = dùng lại scope của dòng trước (ngắn gọn hơn)
* Bit-range và radix (`-HEX`, `-UNSIGNED`) là **tuỳ chọn** — Verdi tự suy ra

Cách dễ nhất: mở Verdi, kéo thêm tín hiệu, rồi **File → Save Signal** đè lên file này.

## Lưu ý

* Cần chạy test với `WAVES=1`, hoặc chạy `simv` tay với `-ucli -do vcs.tcl`
  (xem [13_mo_phong_vcs.md](../13_mo_phong_vcs.md) §3.4 — không cần build lại TB).
* `vcs.tcl` mặc định dump `fsdbDumpvars 0 core_ibex_tb_top +all` (toàn bộ TB) nên
  mọi tín hiệu trong file này đều có sẵn. Nếu bạn thu hẹp phạm vi dump, hãy đảm bảo
  còn phủ các scope ở trên.
* Nhóm `15_ALERT_SECURITY` tham chiếu `gen_lockstep/u_ibex_lockstep` — chỉ tồn tại khi
  `SecureIbex=1` (đúng với `opentitan`).
