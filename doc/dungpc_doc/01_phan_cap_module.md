# 01 — Phân cấp module & sơ đồ khối

## 1. Cây phân cấp đầy đủ (cấu hình `opentitan`)

```
ibex_top                                        rtl/ibex_top.sv
├── prim_clock_gating  core_clock_gate_i        ← cổng clock chính (core_sleep_o)
├── prim_flop          u_prim_core_busy_flop    ← core_busy_q dạng MuBi 4-bit
├── prim_buf           u_fetch_enable_buf / u_mcounteren_writable_buf
│
├── ibex_core          u_ibex_core              rtl/ibex_core.sv   ← LÕI CHÍNH
│   ├── ibex_if_stage          if_stage_i               rtl/ibex_if_stage.sv
│   │   ├── ibex_icache              icache_i           rtl/ibex_icache.sv      [BẬT]
│   │   │     (ibex_prefetch_buffer + ibex_fetch_fifo   [TẮT] vì ICache=1)
│   │   ├── ibex_compressed_decoder  compressed_decoder_i  rtl/ibex_compressed_decoder.sv
│   │   ├── ibex_dummy_instr         dummy_instr_i      rtl/ibex_dummy_instr.sv [BẬT]
│   │   │     └── prim_lfsr          lfsr_i
│   │   ├── prim_secded_inv_39_32_dec u_instr_intg_dec  ← MemECC=1
│   │   ├── prim_buf                 u_prev_instr_addr_incr_buf ← PCIncrCheck
│   │   └── ibex_branch_predict                          [TẮT] BranchPredictor=0
│   │
│   ├── ibex_id_stage          id_stage_i               rtl/ibex_id_stage.sv
│   │   ├── ibex_decoder             decoder_i          rtl/ibex_decoder.sv
│   │   └── ibex_controller          controller_i       rtl/ibex_controller.sv
│   │
│   ├── ibex_ex_block          ex_block_i               rtl/ibex_ex_block.sv
│   │   ├── ibex_alu                 alu_i              rtl/ibex_alu.sv
│   │   ├── ibex_multdiv_fast        multdiv_i          rtl/ibex_multdiv_fast.sv
│   │   │     └── gen_mult_single_cycle (3× 17×17)      ← RV32MSingleCycle
│   │   └── g_branch_target_alu      (adder 33-bit)     ← BranchTargetALU=1
│   │
│   ├── ibex_cheriot_ex        u_ibex_cheriot_ex        rtl/ibex_cheriot_ex.sv  [BẬT]
│   │
│   ├── ibex_load_store_unit   load_store_unit_i        rtl/ibex_load_store_unit.sv
│   │   ├── prim_secded_inv_39_32_dec u_data_intg_dec
│   │   └── prim_secded_inv_39_32_enc u_data_gen
│   │
│   ├── ibex_wb_stage          wb_stage_i               rtl/ibex_wb_stage.sv    [BẬT]
│   │
│   ├── ibex_cs_registers      cs_registers_i           rtl/ibex_cs_registers.sv
│   │   ├── ibex_csr × N             (mstatus, mepc, mie, mscratch, mcause,
│   │   │                             mtval, mtvec, dcsr, depc, dscratch0/1,
│   │   │                             mstack*, mshwm, mshwmb, cdbg_ctrl,
│   │   │                             pmp_cfg×16, pmp_addr×16, mseccfg,
│   │   │                             tselect, tdata1, tdata2, cpuctrlsts,
│   │   │                             mcountinhibit, mcounteren)
│   │   ├── ibex_counter × 12        (mcycle, minstret, mhpmcounter3..12)
│   │   └── gen_scr                  (SCR CHERIoT: PCC/MTCC/MEPCC/MTDC/
│   │                                 MSCRATCHC/DEPCC/DSCRATCHC0/1)
│   │
│   ├── ibex_pmp               pmp_i                    rtl/ibex_pmp.sv        [BẬT]
│   └── prim_secded_* (gen_regfile_ecc)                  [TẮT] RegFileECC=0
│
├── ibex_register_file_ff  register_file_i              rtl/ibex_register_file_ff.sv
│
├── prim_ram_1p_scr  tag_bank  [way 0..1]   Width=28, Depth=256
├── prim_ram_1p_scr  data_bank [way 0..1]   Width=78, Depth=256
│
├── ibex_lockstep      u_ibex_lockstep       rtl/ibex_lockstep.sv               [BẬT]
│   ├── prim_buf           u_signals_prim_buf (rào tối ưu hoá tổng hợp)
│   ├── prim_flop          u_prim_rst_shadow_set_flop / u_prim_enable_cmp_flop
│   ├── prim_clock_mux2    u_prim_rst_shadow_n_mux2 (bypass DFT)
│   ├── ibex_core                u_shadow_core   ← BẢN SAO TOÀN BỘ CÂY LÕI Ở TRÊN
│   └── ibex_register_file_ff    register_file_shadow_i (DataWidth=7, CapWidth=7)
│
└── ibex_trvk          i_ibex_trvk            rtl/ibex_trvk.sv                  [BẬT]
    ├── stream_fork            u_stream_fork_us2ds
    ├── stream_join_dynamic    u_stream_join_dynamic_ds2us
    ├── prim_fifo_sync         u_prim_fifo_sync_align   (Depth=2, Width=1)
    ├── prim_fifo_sync         u_prim_fifo_ds_rsp_store (Depth=2, Width=41)
    └── prim_secded_inv_39_32_dec u_prim_secded_inv_39_32_dec_bm_rsp_data
```

Tổng: `ibex_core` được instantiate **2 lần** (chính + bóng), `ibex_register_file_ff`
được instantiate **2 lần**. Diện tích ≈ gấp đôi so với cấu hình không có lockstep.

## 2. Sơ đồ khối mức lõi

```
                    ┌──────────────────── ibex_core ────────────────────┐
  instr_* ─────────►│  ┌──────────┐                                     │
  ic_tag/data ─────►│  │ IF stage │ pc_if, instr_rdata_id, fetch err    │
  (RAM I$)          │  │  +I$     │──────────────┐                      │
                    │  └────▲─────┘              │ IF/ID pipe reg       │
                    │       │ branch_target_ex   ▼                      │
                    │       │ pc_set/pc_mux   ┌─────────────────────┐   │
                    │       └─────────────────│      ID stage       │   │
                    │                         │ decoder + controller│   │
                    │                         └──┬───────┬──────┬───┘   │
   rf_rdata_a/b ───►│ operand mux ───────────────┘       │      │       │
   rf_rcap_a/b ────►│                                    │      │       │
                    │              ┌─────────────────────▼──┐   │       │
                    │              │     ibex_ex_block      │   │       │
                    │              │  ALU │ BT-ALU │ MULDIV │   │       │
                    │              └───┬────────┬───────────┘   │       │
                    │                  │        │ branch_target │       │
                    │              ┌───▼────────▼───────────┐   │       │
                    │              │    ibex_cheriot_ex     │◄──┘       │
                    │              │ cap ALU + bound/perm   │           │
                    │              └───┬─────────────┬──────┘           │
                    │      lsu_req/addr│             │ result_cap       │
                    │              ┌───▼──────┐      │                  │
  data_* ◄─────────►│              │   LSU    │      │                  │
                    │              └───┬──────┘      │                  │
                    │                  │ rf_wdata_lsu│                  │
                    │              ┌───▼─────────────▼──┐               │
                    │              │     WB stage       │──► rf_we_wb   │
                    │              └────────────────────┘   rf_wdata_wb │
                    │                                       rf_wcap_wb  │
                    │  ┌───────────────┐   ┌──────────┐                 │
  irq_* ───────────►│  │ cs_registers  │◄─►│ ibex_pmp │                 │
  debug_req_i ─────►│  │ + SCR + HPM   │   └──────────┘                 │
                    │  └───────────────┘                                │
                    └───────────────────────────────────────────────────┘
```

## 3. Bảng tín hiệu liên tầng chủ chốt

### 3.1 IF → ID (thanh ghi IF/ID, `ibex_if_stage.sv:589-632`)

| Tín hiệu | Rộng | Mô tả |
|---|---|---|
| `instr_valid_id_o` | 1 | Có lệnh hợp lệ trong ID (giữ tới khi `instr_valid_clear_i`) |
| `instr_new_id_o` | 1 | Lệnh **mới** vừa vào ID (chỉ dùng cho RVFI) |
| `instr_rdata_id_o` | 32 | Lệnh đã giải nén |
| `instr_rdata_alu_id_o` | 32 | Bản sao để giảm fan-out trên đường ALU |
| `instr_rdata_c_id_o` | 16 | Nửa dưới bản gốc (cho `mtval`) |
| `instr_is_compressed_id_o` | 1 | |
| `instr_gets_expanded_id_o` | 2 | `INSTR_NOT_EXPANDED`/`EXPANDED`/`EXPANDED_COMMIT`/`EXPANDED_LAST` (Zcmp) |
| `instr_expanded_id_o` | 16 | Lệnh nén gốc đang được bung |
| `illegal_c_insn_id_o` | 1 | |
| `instr_fetch_err_o` | 1 | Gộp bus err + intg err + PMP err + CHERIoT vio |
| `instr_fetch_err_plus2_o` | 1 | Lỗi nằm ở nửa sau lệnh 32-bit lệch hàng |
| `instr_fetch_cheriot_acc_vio_o` | 1 | PCC thiếu EX / tag=0 / otype≠0 |
| `instr_fetch_cheriot_bound_vio_o` | 1 | PC ngoài [PCC.base, PCC.top) |
| `pc_id_o` | 32 | |
| `dummy_instr_id_o` | 1 | |

### 3.2 ID → EX

`alu_operator_ex`, `alu_operand_a_ex`, `alu_operand_b_ex`, `bt_a_operand`, `bt_b_operand`,
`mult_en_ex`/`div_en_ex`/`mult_sel_ex`/`div_sel_ex`, `multdiv_operator_ex`,
`multdiv_signed_mode_ex`, `multdiv_operand_a/b_ex`, `imd_val_q_ex[2]` (34-bit × 2).

### 3.3 ID → CHERIoT EX

`cheriot_exec_id`, `instr_is_cheriot_id`, `instr_is_rv32lsu_id`, `cheriot_imm12/20/21`,
`cheriot_operator` (struct 26-bit one-hot), `cheriot_cs2_dec`, `cheriot_cap_field_sel`,
`cheriot_adder_a_sel`, `cheriot_adder_b_sel`, `cheriot_setaddr_sel`, `cheriot_setbounds_sel`.

### 3.4 EX → ID/IF

`result_ex`, `alu_adder_result_ex` (→ địa chỉ LSU RV32), `branch_target_ex`,
`branch_decision`, `ex_valid`, `imd_val_d_ex`, `imd_val_we_ex`.

`branch_target_ex` được mux ở `ibex_core.sv:1000-1002`:
```systemverilog
branch_target_ex = (instr_valid_id & instr_is_cheriot_id) ? branch_target_ex_cheriot
                                                          : branch_target_ex_rv32;
```

### 3.5 ID → WB

`en_wb`, `instr_type_wb` (LOAD/STORE/OTHER), `rf_waddr_id`, `rf_wdata_id`, `rf_we_id`,
`instr_perf_count_id`, `instr_is_cheriot_id`, `cheriot_load_id`, `cheriot_store_id`,
`cheriot_rf_we`, `cheriot_result_data`, `cheriot_result_cap`, `dummy_instr_id`.

### 3.6 WB → ID (forwarding & hazard)

`ready_wb`, `rf_write_wb`, `outstanding_load_wb`, `outstanding_store_wb`,
`rf_waddr_wb`, `rf_wdata_fwd_wb`, `rf_wcap_fwd_wb`.

## 4. Đường dữ liệu register file (đặc thù CHERIoT)

`ibex_register_file_ff.sv:75-232` — khối `g_cheriot_rf`:

```
                 rf_data[16]      (32-bit × 16)   ← x0..x15 dữ liệu (cả 2 chế độ)
                 rf_shared[16]    (35-bit × 16)   ← DÙNG CHUNG:
                                                     CHERIoT: metadata cap của x0..x15
                                                     RV32I  : dữ liệu x16..x31

 Ghi:  waddr[4]=0 → rf_data[waddr[3:0]]  (+ rf_shared cùng lúc nếu CHERIoT)
       waddr[4]=1 → rf_shared[waddr[3:0]]  (chỉ khi !CHERIoT && !RV32E)

 Đọc:  rdata = (raddr[4] && !cheriot) ? rf_shared[raddr[3:0]][31:0]
                                      : rf_data[raddr[3:0]]
       rcap  = cheriot ? rf_shared[raddr[3:0]] : 0
```

Ràng buộc: `CapWidth >= DataWidth` (assertion `CapWidthGTEDataWidth`).
Trong lõi chính: `DataWidth=32`, `CapWidth=REGCAP_W=35` ✓.
Trong lõi bóng: `DataWidth=7`, `CapWidth=7` ✓.

**x0 đặc biệt:** vì `DummyInstructions=1`, `rf_data[0]` và `rf_shared[0]` là flop thật.
Chúng chỉ đọc ra giá trị đã ghi khi `dummy_instr_id_i=1`; ngược lại đọc ra 0.
Assertion `DummyWriteTargetsX0` bắt buộc dummy instruction chỉ ghi vào x0.
