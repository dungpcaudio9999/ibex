# 12 — Timing pipeline, hazard, exception & interrupt

Tổng hợp hành vi thời gian của toàn bộ pipeline trong cấu hình `opentitan`.

---

## 1. Cấu trúc pipeline 3 tầng

```
   ┌──────────┐   ┌──────────────────┐   ┌──────────┐
   │    IF    │──►│     ID / EX      │──►│    WB    │
   └──────────┘   └──────────────────┘   └──────────┘
   I$ lookup      decode + regfile read   chờ phản hồi
   PCC check      ALU / MULDIV / CHERIoT  bộ nhớ,
   decompress     LSU request             ghi regfile
   dummy insert   branch resolve
```

Ranh giới pipeline:
* **IF/ID**: `if_id_pipe_reg_we = instr_new_id_d` (`ibex_if_stage.sv:587`)
* **ID/WB**: `en_wb_i = instr_done` (`ibex_id_stage.sv:1224`)

Độ trễ tối thiểu một lệnh: **3 chu kỳ**. Thông lượng tối đa: **1 IPC**.

---

## 2. Bảng stall đầy đủ

"Stall cycles" = số chu kỳ **thêm** mà lệnh chiếm tầng ID/EX (0 = thông lượng 1 IPC).

| Nhóm lệnh | Stall | Nguyên nhân |
|---|---|---|
| ALU/logic/shift/slt/lui | **0** | |
| Bitmanip 1 chu kỳ (zba/zbb/zbs/clmul/shfl/xperm/grev/gorc) | **0** | |
| Bitmanip 2 chu kỳ: `rol`, `ror[i]`, `fsl`, `fsr[i]`, `crc32[c].b/h/w` | **1** | `alu_multicycle_dec` → `stall_alu` |
| `MUL` | **0** | 3 bộ nhân 17×17 |
| `MULH`, `MULHSU`, `MULHU` | **1** | FSM `MULL → MULH` |
| `DIV`, `DIVU`, `REM`, `REMU` (b ≠ 0) | **36** | 37 chu kỳ tổng |
| `DIV`/`REM` (b = 0, DIT tắt) | **1** | `MD_IDLE → MD_FINISH` |
| `DIV`/`REM` (b = 0, DIT bật) | **36** | chạy đủ long division |
| CSR đọc/ghi | **0** trong ID | nhưng hầu hết ghi CSR → `csr_pipe_flush` → FLUSH (≈2 + N chu kỳ) |
| CSR `mscratch`/`mepc` ghi | **0** | miễn flush |
| Load/Store (grant ngay) | **0** trong ID | Chuyển sang WB ngay khi `lsu_req_done`. Chỉ stall nếu lệnh sau đọc thanh ghi đích |
| Load/Store (grant sau N) | **N** | `stall_mem` |
| Load-use hazard | **1 – N** | `stall_ld_hz` cho tới `lsu_resp_valid` |
| Load/Store lệch hàng | **1 – N** thêm | 2 request |
| `CLC`/`CSC` | **1 – N** thêm | 2 request |
| `CLC`/`CSC` bị chặn bởi capability | **0** | LSU báo lỗi trong 1 chu kỳ |
| `JAL`, `JALR` | **0** | nhờ BT-ALU |
| `CJAL`, `CJALR` | **0** | CHERIoT EX 1 chu kỳ |
| Branch không taken (DIT tắt) | **0** | |
| Branch taken (DIT tắt) | **0** trong ID, **1 – N** bong bóng IF | `pc_set` flush I$, chờ fetch |
| Branch bất kỳ (DIT bật) | **1** + bong bóng IF | `stall_branch = data_ind_timing_i` |
| `FENCE` | **0** | NOP |
| `FENCE.I` | như jump + **≥256** chu kỳ invalidate I$ | `icache_inval_o` |
| `cm.push` (N thanh ghi) | **N** | N+1 micro-op |
| `cm.pop` | **N** | |
| `cm.popret` | **N+1** | thêm micro-op `ret` |
| `cm.popretz` | **N+2** | thêm `li a0,0` và `ret` |
| `cm.mvsa01`, `cm.mva01s` | **1** | 2 micro-op |
| Dummy instruction được chèn | **1** | `stall_dummy_instr` |
| `WFI` | tới khi có IRQ | `WAIT_SLEEP → SLEEP` |
| `ECALL`/`EBREAK`/`MRET`/`DRET` | ≈2 + N | qua `FLUSH` |

"N" = độ trễ của hệ thống bộ nhớ (từ `req` tới `rvalid`).

---

## 3. Giản đồ thời gian

### 3.1 Luồng tuần tự lý tưởng (1 IPC)

```
chu kỳ:    0     1     2     3     4     5
I1:       IF    ID    WB
I2:             IF    ID    WB
I3:                   IF    ID    WB
I4:                         IF    ID    WB
```

### 3.2 Load rồi lệnh độc lập (WB stage phát huy tác dụng)

```
chu kỳ:    0     1     2     3     4
LW  x1:   IF    ID    WB----WB          ← chờ rvalid trong WB
ADD x3,x4,x5:   IF    ID    WB          ← chạy song song, KHÔNG stall
SUB x6,x7,x8:         IF    ID    WB
```

### 3.3 Load-use hazard (phải stall)

```
chu kỳ:    0     1     2     3     4     5
LW  x1:   IF    ID    WB----WB
                       ↑ outstanding_load_wb = 1
ADD x2,x1,x3:   IF    ID----ID    WB    ← stall_ld_hz
                            ↑ rvalid về, rf_we_lsu ghi x1
```

### 3.4 Branch taken (BT-ALU, DIT tắt)

```
chu kỳ:    0     1     2     3     4
BEQ:      IF    ID    WB
                 ↑ branch_decision → branch_set → pc_set_o
                 ↑ bt_alu tính branch_target CÙNG chu kỳ
I_seq:          IF    ×                 ← bị squash bởi pc_set (~pc_set_i)
I_target:             IF    ID    WB    ← I$ branch lookup
```

Một "bong bóng" 1 chu kỳ ở IF (nếu I$ hit). Nếu miss thì thêm N chu kỳ.

### 3.5 Branch với DIT bật

```
chu kỳ:    0     1     2     3     4
BEQ:      IF    ID----ID    WB          ← stall_branch = 1, luôn 2 chu kỳ
                       ↑ branch_set_raw_q (đã flop)
I_target:             IF    ID    WB
```

Taken và not-taken có **cùng** profile → không rò rỉ điều kiện nhánh qua timing.

### 3.6 `cm.push {ra,s0-s2}, -32`

```
chu kỳ:   0    1    2    3    4    5    6    7    8
IF:      C.P  C.P  C.P  C.P  C.P  I_next                ← lệnh nén GIỮ NGUYÊN ở IF
                                                          (fetch_ready = 0)
ID:            sw   sw   sw   sw   addi I_next
               s2   s1   s0   ra   sp,-32
gets_exp:      EXP  EXP  EXP  EXP  LAST
WB:                 sw   sw   sw   sw   addi
```

Bốn `sw` đi qua WB lần lượt; `minstret` chỉ tăng **1** lần (ở micro-op cuối, vì
`instr_perf_count_id_o` = 0 cho `INSTR_EXPANDED`).

### 3.7 `cm.popret` — chặn interrupt

```
chu kỳ:   0    1    2    3    4    5
ID:      lw   lw   addi  jalr(ret)
              s0   ra    sp,+32
gets_exp: EXP  EXP  COMMIT  LAST
                    ↑↑↑ handle_irq bị chặn ở đây
                        (INSTR_EXPANDED_COMMIT)
```

`INSTR_EXPANDED_COMMIT` được đặt ở `CmPopIncrSp` và `CmPopZeroA0`
(`ibex_compressed_decoder.sv:738, :762`) — để `sp` đã tăng và `ret` được thực thi
**nguyên tử**. Nếu interrupt xen vào giữa, `sp` đã trỏ ra ngoài stack frame cũ
nhưng `ra` chưa được dùng → stack bị hỏng.

### 3.8 `CLC` (capability load)

```
chu kỳ:   0    1    2    3    4    5
IF:      CLC
ID:           CLC (tính bound/perm, phát lsu_req)
LSU FSM: IDLE→CTX_WAIT_GNT2→CTX_WAIT_RESP→IDLE
bus req:      addr  addr+4
bus rsp:            word0  word1
cap_rx:  IDLE  RESP1        RESP2
WB:           CLC---CLC----CLC
                          ↑ lsu_rcap_o = cheriot_mem_to_cap(word1, word0, clrperm)
                            rf_we_lsu ghi cả data + cap
```

---

## 4. Ma trận hazard

| Lệnh trước (WB) | Lệnh sau (ID) | Xử lý |
|---|---|---|
| ALU ghi `xN` | đọc `xN` | **Forward** `rf_wdata_fwd_wb_o` |
| CHERIoT EX ghi `cN` | đọc `cN` (data) | **Forward** `rf_wdata_fwd_wb_o` (ID) |
| CHERIoT EX ghi `cN` | đọc `cN` (cap) | **Forward** `rf_wcap_fwd_wb_o` (trong `ibex_cheriot_ex`) |
| CSR đọc ghi `xN` | đọc `xN` | **Forward** |
| `LW` ghi `xN` | đọc `xN` | **Stall** (`stall_ld_hz`) |
| `CLC` ghi `cN` | đọc `cN` | **Stall** (`wb_cheriot_load_q` → `outstanding_load_wb`) |
| Load/Store bất kỳ | Load/Store khác | **Stall** (`data_req_allowed = ~outstanding_memory_access`) |
| bất kỳ | x0 | Không hazard (`|rf_raddr_a_o` loại trừ) |
| Lệnh bị exception ở WB | bất kỳ | **Kill** (`wb_exception → instr_kill`) |

**Chỉ có một** hazard phải stall: load-use. Mọi hazard ALU→ALU được forward.

---

## 5. Exception & Interrupt

### 5.1 Thứ tự ưu tiên tổng thể

```
1. Exception từ WB (store_err → load_err → cheriot_wb_err)
2. Exception từ ID  (instr_fetch_err → illegal_insn → ecall → ebreak
                     → cheriot_ex_err → cheriot_asr_err)
3. Debug (trigger_match / debug_req / single_step)
4. Interrupt (NMI → fast[0..14] → external → software → timer)
```

Nhưng trong `FLUSH`, EBREAK-vào-debug lại vượt lên trên `debug_req` và `step`
(`ibex_controller.sv:974-987`).

### 5.2 Trình tự vào exception

```
chu kỳ 0:  DECODE   — phát hiện special_req, retain_id = 1, halt_if = 1
                      chờ ready_wb_i | wb_exception_o
chu kỳ 1:  FLUSH    — flush_id = 1, halt_if = 1
                      pc_set_o = 1, pc_mux_o = PC_EXC
                      csr_save_cause_o = 1, csr_save_id_o / csr_save_wb_o
                      exc_cause_o, csr_mtval_o theo bảng ưu tiên
chu kỳ 2:  DECODE   — IF đã fetch từ mtvec, lệnh handler vào ID sau N chu kỳ
```

Tối thiểu **2 chu kỳ** + độ trễ fetch handler.

Cập nhật CSR trong chu kỳ FLUSH (`ibex_cs_registers.sv:893-945`):
```
priv_lvl    ← M
mstatus.mie ← 0,  mstatus.mpie ← mstatus.mie,  mstatus.mpp ← priv_lvl cũ
mepc        ← pc_if / pc_id / pc_wb  (theo csr_save_if/id/wb)
mcause      ← exc_cause_o
mtval       ← csr_mtval_o
mstack      ← {mstatus.mpie, mstatus.mpp} cũ
mstack_epc  ← mepc cũ,  mstack_cause ← mcause cũ
// CHERIoT: mepc_cap ← cheriot_pcc_to_mepc(pcc_q, exception_pc, clrtag)
//          pcc_cap_q ← decode(mtvec_cap, mtvec_q)
```

### 5.3 Trình tự vào interrupt

```
chu kỳ 0:  DECODE   — handle_irq = 1
                      nếu (stall | id_wb_pending) → halt_if = 1, ở lại DECODE
chu kỳ k:  DECODE   — pipeline rỗng → ctrl_fsm_ns = IRQ_TAKEN, halt_if = 1
chu kỳ k+1: IRQ_TAKEN — pc_set_o = 1, pc_mux_o = PC_EXC, exc_pc_mux_o = EXC_PC_IRQ
                        csr_save_if_o = 1  (mepc ← pc_if, tức lệnh CHƯA thực thi)
                        csr_save_cause_o = 1
                        nếu NMI: nmi_mode_d = 1
chu kỳ k+2: DECODE
```

Điểm khác biệt với exception: `csr_save_if_o` (không phải `_id_o`) — interrupt là
**bất đồng bộ**, `mepc` trỏ tới lệnh **chưa** chạy.

Assertion `PipeEmptyOnIrq` đảm bảo `~instr_valid_i & ready_wb_i` khi vào `IRQ_TAKEN`.

### 5.4 Địa chỉ handler

| Chế độ | Exception | Interrupt |
|---|---|---|
| RV32I | `mtvec & ~0xFF` | `(mtvec & ~0xFF) + irq_vec*4` (vectored) |
| CHERIoT | `mtvec & ~0x3` | `mtvec & ~0x3` (direct) |
| Debug entry | `DmHaltAddr` = `0x1A110800` | — |
| Exception trong debug | `DmExceptionAddr` = `0x1A110808` | — |

`irq_vec` với NMI nội bộ được ép thành `ExcCauseIrqNm.lower_cause = 31`
(`ibex_if_stage.sv:214-218`).

### 5.5 Trình tự vào debug mode

Hai đường:

**`DBG_TAKEN_IF`** — debug_req, single-step, trigger match:
```
flush_id = 1, pc_set_o = 1, pc_mux = PC_EXC, exc_pc_mux = EXC_PC_DBD
csr_save_if_o = 1, debug_csr_save_o = 1, csr_save_cause_o = 1
→ dpc ← pc_if, dcsr.cause ← debug_cause_q, dcsr.prv ← priv_lvl
debug_mode_d = 1
```

**`DBG_TAKEN_ID`** — EBREAK khi `dcsr.ebreakm/ebreaku` set, hoặc EBREAK trong debug mode:
```
flush_id = 1, pc_set_o = 1, exc_pc_mux = EXC_PC_DBD
if (ebreak_into_debug && !debug_mode_q) { csr_save_cause_o = 1; csr_save_id_o = 1;
                                          debug_csr_save_o = 1; }
→ dpc ← pc_id (địa chỉ CỦA CHÍNH lệnh EBREAK, theo đặc tả)
debug_mode_d = 1
```

Nếu đã ở debug mode thì EBREAK **không** cập nhật `dpc`/`dcsr`, chỉ nhảy lại handler.

Assertion `IbexPipelineFlushOnChangingDebugMode`:
`debug_mode_d != debug_mode_q |-> flush_id_o & pc_set_o`.

### 5.6 WFI và SLEEP

```
WFI ở ID → special_req_flush_only → FLUSH → WAIT_SLEEP → SLEEP
  WAIT_SLEEP: ctrl_busy_o = 0, instr_req_o = 0, halt_if = 1, flush_id = 1
  SLEEP:      ctrl_busy_o = 0 (giữ) → core_busy_o = IbexMuBiOff
              → clock_en = 0 (nếu không có debug/irq) → prim_clock_gating tắt clk
```

Thức dậy: `irq_nm || irq_pending_i || debug_req_i || debug_mode_q || debug_single_step_i`
→ `FIRST_FETCH`.

Chú ý `clock_en` ở `ibex_top.sv:314` dùng `debug_req_i | irq_pending | irq_nm_i`
**trực tiếp từ chân** (không qua flop), và `mip` là tổ hợp thuần — nên clock được bật lại
ngay trong chu kỳ có IRQ.

`WFI` trong debug mode hoặc single-step hoạt động như **NOP** (SLEEP thoát ngay).

### 5.7 NMI lồng nhau

```
nmi_mode_q = 1 → handle_irq = 0 → mọi interrupt (kể cả NMI) bị chặn
mret trong NMI handler → nmi_mode_d = 0, và khôi phục mepc/mcause/mstatus từ mstack
```

Chuỗi này cho phép NMI xảy ra **bên trong** exception handler mà không mất thông tin
trap gốc.

---

## 6. Ảnh hưởng của `pc_set_o`

`pc_set_o` là tín hiệu flush toàn cục cho tầng IF:

```systemverilog
// ibex_if_stage.sv
branch_req      = pc_set_i;                                  // → I$ branch
instr_valid_id_d = (if_instr_valid & id_in_ready_i & ~pc_set_i) | ...;   // squash
compressed_decoder.id_in_ready_i = id_in_ready_i & ~pc_set_i;            // không tiêu thụ
flush_expanded  = pc_set_i & (pc_mux_i == PC_EXC);                       // xoá FSM Zcmp
```

Trong I$ (`ibex_icache.sv`):
```systemverilog
fill_stale_d[fb] = fill_busy_q[fb] & (branch_i | fill_stale_q[fb]);   // mọi buffer → stale
skid_valid_d     = branch_i ? 1'b0 : ...;                              // xoá skid
output_addr_d    = branch_i ? addr_i[31:1] : ...;                      // đặt lại bộ đếm
prefetch_addr_en = branch_i | lookup_grant_ic0;
```

Các fill buffer đang bận vẫn **tiếp tục nhận rvalid** (không thể huỷ giao dịch bus đã
grant) và vẫn **ghi line vào cache** nếu `fill_cache_q` — dữ liệu prefetch không lãng phí.

---

## 7. Các đường tổ hợp tới hạn (dự kiến)

| # | Đường | Ghi chú |
|---|---|---|
| 1 | `ic_data_rdata_i` → un-tweak → mux way → ECC decode → mux nửa-từ → `rdata_o` → compressed decoder → `ibex_decoder` → `alu_operator` | Đường dài nhất khi I$ hit |
| 2 | `rf_rdata_a` → `cheriot_decode_cap` (bounds 33-bit) → bound compare → `cheriot_lsu_err` → `lsu_req_o` → `data_req_o` | Được tối ưu bằng cách dùng `addr_bound_vio` (bound làm tròn) thay vì `addr_bound_vio_ext` |
| 3 | `rf_rdata_a/b` → mux operand → ALU adder 33-bit → `alu_adder_result_ex` → `lsu_addr` → `data_addr_o` | Đường địa chỉ RV32 |
| 4 | `data_gnt_i` → LSU FSM → `lsu_req_done` → `stall_mem` → `instr_done` → `en_wb_o` | Được cắt bằng `instr_executing_spec` |
| 5 | `rf_rdata_a` → `cheriot_prep_bounds` → `cheriot_set_bounds_ex` (2 đường song song) → `result_cap` | Set-bounds 1 chu kỳ |
| 6 | `csr_rdata` → `illegal_csr_insn_i` → `illegal_insn_o` → `exc_req_d` → `special_req` | Cắt bằng flop `illegal_insn_q` |

Các kỹ thuật cắt đường tới hạn có trong mã:
* Nhân bản `instr_rdata_alu_id_o` (giảm fan-out).
* Flop `illegal_insn_q`, `cheriot_ex_err_q`, `load_err_q`, `store_err_q` trong controller.
* `csr_op_en_o` dùng `instr_first_cycle` thay `instr_id_done` ở chế độ CHERIoT.
* Tách `check_rv32` và `check_cheriot` thành 2 khối `always_comb`.
* `cs1_addr_plusimm` tách riêng khỏi `shared_adder`.
* `addr_bound_vio` (tối ưu) vs `addr_bound_vio_ext` (đầy đủ, chỉ dùng cho mtval).
* `pc_mux_o = PC_JUMP` được gán **vô điều kiện** ở đầu trạng thái `DECODE`
  (`ibex_controller.sv:660`) thay vì trong `if (branch_set_i | jump_set_i)`.
* BT-ALU tách khỏi ALU chính → mux `imm_b` nhỏ đi 2 lối vào.

---

## 8. So sánh với cấu hình khác

| | `small` | `maxperf` | **`opentitan`** |
|---|---|---|---|
| Tầng pipeline | 2 | 3 | **3** |
| BT-ALU | Không | Có | **Có** |
| Multiplier | Fast (3/4 chu kỳ) | SingleCycle | **SingleCycle** |
| Bitmanip | Không | Không | **RV32BOTEarlGrey** |
| Zc | Zca | Zca+Zcb+Zcmp | **Zca+Zcb+Zcmp** |
| I$ | Không | Không | **4 KiB, 2-way, ECC, scramble** |
| PMP | Không | Không | **16 vùng, ePMP** |
| SecureIbex | Không | Không | **Có** (lockstep, dummy, ECC…) |
| Debug trigger | Không | Không | **1 trigger** |
| HPM counter | 0 | 0 | **10 × 32-bit** |
| CHERIoT | — | — | **Có** (runtime switch) |

`opentitan` là cấu hình **duy nhất** có nightly regression theo ghi chú trong
`ibex_configs.yaml:14-16`.

---

## 9. Kiểm tra nhanh khi đọc waveform

| Tín hiệu | Ý nghĩa |
|---|---|
| `u_ibex_core.if_stage_i.pc_if_o` | PC đang fetch |
| `u_ibex_core.pc_id` | PC của lệnh trong ID |
| `u_ibex_core.wb_stage_i.g_writeback_stage.wb_pc_q` | PC của lệnh trong WB |
| `u_ibex_core.id_stage_i.controller_i.ctrl_fsm_cs` | Trạng thái controller |
| `u_ibex_core.id_stage_i.id_fsm_q` | `FIRST_CYCLE` / `MULTI_CYCLE` |
| `u_ibex_core.load_store_unit_i.ls_fsm_cs` | Trạng thái LSU |
| `u_ibex_core.load_store_unit_i.cap_rx_fsm_q` | FSM nhận capability |
| `u_ibex_core.if_stage_i.gen_icache.icache_i.inval_state_q` | FSM invalidate I$ |
| `u_ibex_core.if_stage_i.gen_icache.icache_i.fill_busy_q` | 4 bit — fill buffer nào đang bận |
| `u_ibex_core.if_stage_i.compressed_decoder_i.cm_state_q` | FSM Zcmp |
| `u_ibex_core.ex_block_i.gen_multdiv_fast.multdiv_i.md_state_q` | FSM chia |
| `u_ibex_core.id_stage_i.stall_id` | Đang stall ID |
| `u_ibex_core.cs_registers_i.gen_scr.pcc_cap_q` | PCC hiện tại |
| `lockstep_cmp_en_o` | So sánh lockstep đã bật chưa |

Assertion tham chiếu chéo crash dump (`ibex_top.sv:1605-1615`) xác nhận:
```systemverilog
crash_dump_o.current_pc     === u_ibex_core.pc_id
crash_dump_o.next_pc        === u_ibex_core.pc_if
crash_dump_o.last_data_addr === u_ibex_core.load_store_unit_i.addr_last_q
crash_dump_o.exception_pc   === u_ibex_core.cs_registers_i.mepc_q
crash_dump_o.exception_addr === u_ibex_core.cs_registers_i.mtval_q
```
