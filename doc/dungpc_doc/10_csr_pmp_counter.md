# 10 — CSR, SCR CHERIoT, ePMP, HPM Counter, Debug Trigger

Tệp: `ibex/rtl/ibex_cs_registers.sv` (2262 dòng), `ibex_csr.sv` (57), `ibex_counter.sv` (111),
`ibex_pmp.sv` (263).

---

## 1. Primitive `ibex_csr`

`ibex/rtl/ibex_csr.sv`

```systemverilog
module ibex_csr #(Width, ShadowCopy, ResetValue) (
  clk_i, rst_ni, wr_data_i, wr_en_i, rd_data_o, rd_error_o);

  always_ff: if (!rst_ni) rdata_q <= ResetValue; else if (wr_en_i) rdata_q <= wr_data_i;
  assign rd_data_o = rdata_q;

  if (ShadowCopy) begin
    always_ff: if (!rst_ni) shadow_q <= ~ResetValue; else if (wr_en_i) shadow_q <= ~wr_data_i;
    assign rd_error_o = rdata_q != ~shadow_q;       // SEC_CM: CSR.SHADOW
  end else assign rd_error_o = 1'b0;
endmodule
```

> **Trong cấu hình `opentitan` của repo này, `ShadowCSR = 1'b0`** (localparam hard-code
> tại `ibex_core.sv:197`). Do đó mọi `rd_error_o = 0` và `csr_shadow_err_o = 0`.
> Cơ chế shadow-CSR tồn tại trong RTL nhưng **không được kích hoạt**.

---

## 2. Danh sách CSR được hiện thực

### 2.1 Thông tin máy (read-only)

| CSR | Địa chỉ | Giá trị |
|---|---|---|
| `mvendorid` | `F11` | `CsrMvendorId` (mặc định 0) |
| `marchid` | `F12` | CHERIoT bật → `32'hce1`; tắt → `32'h0000_0016` |
| `mimpid` | `F13` | `CsrMimpId` (mặc định 0) |
| `mhartid` | `F14` | `hart_id_i` |
| `mconfigptr` | `F15` | 0 |

`marchid` đổi **động** theo `cheriot_enable_i` (`ibex_cs_registers.sv:424-427`).

### 2.2 `misa` (`301`) — động theo chế độ

`ibex_cs_registers.sv:188-210` và `:375-392`

```systemverilog
MISA_VALUE = (1<<2)   // C
           | (RV32E<<4)              // E
           | (!RV32E<<8)             // I
           | (RV32MEnabled<<12)      // M
           | (1<<20)                 // U
           | (MisaXBit<<23)          // X
           | (CSR_MISA_MXL<<30);     // MXL=1 (RV32)

misa_value_masked = { MISA_VALUE[31:24],
                      X: CHERIoT ? ((enabled) || (RV32BExtra != 0)) : MISA_VALUE[23],
                      MISA_VALUE[22:9],
                      I: CHERIoT ? (enabled != On) : MISA_VALUE[8],
                      MISA_VALUE[7:5],
                      E: CHERIoT ? (enabled == On) : MISA_VALUE[4],
                      MISA_VALUE[3:0] };
```

| | RV32I mode | CHERIoT mode |
|---|---|---|
| `E` | 0 | **1** |
| `I` | 1 | **0** |
| `X` | 1 (vì `RV32BOTEarlGrey` có phần ngoài chuẩn) | **1** |
| `C`, `M`, `U`, MXL | 1, 1, 1, 1 | giống |

`RV32BExtra` (`ibex_cs_registers.sv:179`) = 1 với mọi cấu hình bitmanip vì tất cả đều bật
sub-extension chưa phê chuẩn.

### 2.3 Trap setup / handling

| CSR | Địa chỉ | Trường | Ghi chú |
|---|---|---|---|
| `mstatus` | `300` | `mie, mpie, mpp[1:0], mprv, tw` | Reset: `mpie=1, mpp=U` |
| `mie` | `304` | `MSIE(3), MTIE(7), MEIE(11), fast[30:16]` | |
| `mtvec` | `305` | `{base[31:8], 6'b0, 1'b0, mode}` | mode = `~CHERIoT_on` → CHERIoT dùng **direct(0)**, RV32 dùng **vectored(1)** |
| `mcounteren` | `306` | `[MHPMCounterNum+2:0]` | Chỉ ghi được khi `mcounteren_writable_i == IbexMuBiOn` |
| `mscratch` | `340` | 32 bit | |
| `mepc` | `341` | `{wdata[31:1], 1'b0}` | |
| `mcause` | `342` | `{irq_ext, irq_int, lower_cause[4:0]}` | Bit 31:30 mã hoá: `10`=irq ext, `11`=irq int (NMI nội bộ) |
| `mtval` | `343` | 32 bit | |
| `mip` | `344` | **tổ hợp thuần** từ chân IRQ | Không có flop → WFI thức dậy được |

**Reset `mtvec`**: `csr_mtvec_init_i` từ IF (`pc_mux == PC_BOOT & pc_set`) nạp
`{boot_addr[31:8], 6'b0, 1'b0, mode}`.

### 2.4 Lưu/khôi phục khi trap

`ibex_cs_registers.sv:893-945`

```systemverilog
csr_save_cause_i:
  exception_pc = csr_save_if_i ? pc_if_i : csr_save_id_i ? pc_id_i : pc_wb_i;
  priv_lvl_d   = PRIV_LVL_M;                       // mọi trap → M-mode

  if (debug_csr_save_i) begin                      // vào debug mode
    dcsr_d.prv = priv_lvl_q;  dcsr_d.cause = debug_cause_i;  dcsr_en = 1;
    depc_d = exception_pc;    depc_en = 1;
    // KHÔNG đụng mstatus/mepc/mcause/mtval
  end else if (!debug_mode_i) begin                // exception thường
    mtval_d  = csr_mtval_i;       mtval_en  = 1;
    mstatus_d.mie  = 1'b0;                          // tắt interrupt
    mstatus_d.mpie = mstatus_q.mie;                 // lưu MIE cũ
    mstatus_d.mpp  = priv_lvl_q;                    // lưu priv cũ
    mepc_d   = exception_pc;      mepc_en   = 1;
    mcause_d = csr_mcause_i;      mcause_en = 1;
    mstack_en = 1'b1;                               // lưu cho NMI lồng
    ...double fault detection...
  end
```

**Exception trong debug mode không cập nhật CSR nào** — đúng đặc tả debug.

### 2.5 MRET

```systemverilog
csr_restore_mret_i:
  priv_lvl_d    = mstatus_q.mpp;
  mstatus_d.mie = mstatus_q.mpie;                   // khôi phục interrupt
  if (mstatus_q.mpp != PRIV_LVL_M) mstatus_d.mprv = 1'b0;
  cpuctrlsts_part_d.sync_exc_seen = 1'b0;           // xoá cờ double-fault

  if (nmi_mode_i) begin                             // NMI khôi phục từ mstack
    mstatus_d.mpie = mstack_q.mpie;
    mstatus_d.mpp  = mstack_q.mpp;
    mepc_d   = mstack_epc_q;    mepc_en   = 1;
    mcause_d = mstack_cause_q;  mcause_en = 1;
  end else begin
    mstatus_d.mpie = 1'b1;  mstatus_d.mpp = PRIV_LVL_U;
  end
```

### 2.6 CSR "mstack" — NMI khôi phục được

`ibex_cs_registers.sv:1256-1300`. Ba thanh ghi **không chuẩn**
(xem riscv-isa-manual issue #261):

| Thanh ghi | Lưu gì | Khi nào |
|---|---|---|
| `mstack_q` | `{mstatus.mpie, mstatus.mpp}` | mọi `csr_save_cause` |
| `mstack_epc_q` | `mepc_q` **cũ** | mọi `csr_save_cause` |
| `mstack_cause_q` | `mcause_q` **cũ** | mọi `csr_save_cause` |

Vấn đề giải quyết: NMI có thể xảy ra **ngay trong** exception handler, trước khi handler
kịp lưu `mepc`/`mcause`. Nếu không có mstack thì thông tin trap gốc bị mất. Với mstack,
`mret` từ NMI handler khôi phục lại đúng trạng thái.

Ở chế độ CHERIoT còn có `mstack_epc_cap_q` (`ibex_cs_registers.sv:2126-2132`) lưu
`mepc_cap` — để NMI return khôi phục được cả **tag** của MEPCC.

### 2.7 Phát hiện double fault

`ibex_cs_registers.sv:936-948`, SEC_CM: `EXCEPTION.CTRL_FLOW.LOCAL_ESC` / `GLOBAL_ESC`

```systemverilog
if (!(mcause_d.irq_ext || mcause_d.irq_int)) begin   // chỉ exception ĐỒNG BỘ
  cpuctrlsts_part_d.sync_exc_seen = 1'b1;
  if (cpuctrlsts_part_q.sync_exc_seen) begin
    double_fault_seen_o                 = 1'b1;      // xung 1 chu kỳ ra ngoài
    cpuctrlsts_part_d.double_fault_seen = 1'b1;      // bit dính trong CSR
  end
end
```

`sync_exc_seen` được xoá bởi `mret`. Nếu xảy ra exception đồng bộ **thứ hai** trước khi
handler kịp `mret` → handler đang bị lỗi → báo ra ngoài để hệ thống escalate
(OpenTitan dùng để reset chip).

### 2.8 CSR debug

| CSR | Địa chỉ | Ghi chú |
|---|---|---|
| `dcsr` | `7B0` | `xdebugver=4(STD)`, `ebreakm`, `ebreaku`, `step`, `prv`, `cause`, `nmip`, `mprven` |
| `dpc` | `7B1` | |
| `dscratch0/1` | `7B2/7B3` | |
| `tselect` | `7A0` | `DbgHwNumLen = 1` bit (vì `DbgHwBreakNum = 1`) |
| `tdata1` | `7A1` | Read-only pattern + bit `execute` ghi được |
| `tdata2` | `7A2` | Địa chỉ so khớp |
| `tdata3`, `mcontext`, `scontext`, `mscontext` | — | đọc 0 |

Tất cả CSR debug chỉ truy cập được trong debug mode: `illegal_csr_dbg = dbg_csr & ~debug_mode_i`.

### 2.9 CSR đặc thù Ibex / OpenTitan

| CSR | Địa chỉ | Trường | Điều kiện |
|---|---|---|---|
| `cpuctrlsts` | `7C0` | `{double_fault_seen, sync_exc_seen, dummy_instr_mask[2:0], dummy_instr_en, data_ind_timing, icache_enable}` + `ic_scr_key_valid` (đọc riêng) | luôn |
| `secureseed` | `7C1` | write-only, nạp seed LFSR dummy instr | `DummyInstructions=1` |
| `mshwm` | `BC1` | Stack high-water mark (align 16 byte) | CHERIoT bật |
| `mshwmb` | `BC2` | Stack high-water mark **base** | CHERIoT bật |
| `cdbg_ctrl` | `BC4` | bit 0 = `csr_dbg_tclr_fault` | CHERIoT bật |

`icache_enable_o = cpuctrlsts_part_q.icache_enable & ~(debug_mode_i | debug_mode_entering_i)`
— I$ **tự động tắt** trong debug mode.

`cdbg_ctrl[0]` (`csr_dbg_tclr_fault`): khi bật, các thao tác capability làm **xoá tag**
(set-address/set-bounds không biểu diễn được, store-local violation) sẽ **sinh exception**
thay vì âm thầm xoá tag. Dùng để gỡ lỗi phần mềm CHERI.

---

## 3. SCR CHERIoT (Special Capability Registers)

`ibex_cs_registers.sv:2003-2230` — khối `gen_scr` **[BẬT]**.

Truy cập bằng lệnh `CSpecialRW` (`cheriot_csr_addr_i` 5 bit), **không** dùng `csr_addr_i` 12 bit.

| Mã | Tên | Reset cap | Reset data | Đi kèm CSR RV32 |
|---|---|---|---|---|
| `5'h1f` | `MEPCC` | `ROOT_CAP_TX` | — | `mepc_q` |
| `5'h1e` | `MSCRATCHC` | `ROOT_CAP_TS` | `0` | (riêng, khác `mscratch`) |
| `5'h1d` | `MTDC` | `ROOT_CAP_TM` | `0` | (không có) |
| `5'h1c` | `MTCC` | `ROOT_CAP_TX` | — | `mtvec_q` |
| `5'h1b` | `ZTOPC` | — | — | **chưa hiện thực** (`ztop_rdata_i = 0`) |
| `5'h1a` | `DSCRATCHC1` | `NULL_CAP` | — | `dscratch1_q` (debug only) |
| `5'h19` | `DSCRATCHC0` | `NULL_CAP` | — | `dscratch0_q` (debug only) |
| `5'h18` | `DEPCC` | `NULL_CAP` | — | `depc_q` (debug only) |

**Cấu trúc chia đôi:** phần **địa chỉ** dùng chung flop với CSR RV32 tương ứng
(`mepc_q`, `mtvec_q`, `depc_q`, `dscratch0/1_q`), phần **metadata capability** nằm
trong flop riêng (`mepc_cap`, `mtvec_cap`, `depc_cap`, `dscratch0/1_cap`).
`mtdc` và `mscratchc` có cả hai phần riêng.

Ghi vào SCR:
```systemverilog
mepc_en_cheriot = cheriot_csr_op_en_i && (cheriot_csr_addr_i == CHERIOT_SCR_MEPCC)
                  && (cheriot_csr_op_i == CHERIOT_CSR_RW);
mepc_en_combi   = mepc_en | mepc_en_cheriot;                     // OR với đường RV32
mepc_d_combi    = ({32{mepc_en}} & mepc_d) | ({32{mepc_en_cheriot}} & cheriot_csr_wdata_i);
```

`mepc_cap` có 3 nguồn (`ibex_cs_registers.sv:2134-2148`):
```systemverilog
if (cheriot_on && csr_save_cause_i && ~debug_csr_save_i && ~debug_mode_i)
     mepc_cap <= pcc_exc_cap;                     // = cheriot_pcc_to_mepc(pcc_q, exception_pc, clrtag)
else if (cheriot_on && csr_restore_mret_i && nmi_mode_i)
     mepc_cap <= mstack_epc_cap_q;                // khôi phục từ NMI
else if (mepc_en_cheriot)
     mepc_cap <= cheriot_csr_wcap_i;              // CSpecialRW
```

`cheriot_pcc_to_mepc()` (`ibex_cheriot_pkg.sv:736-750`):
```systemverilog
new_dcap = cheriot_set_address(pcc, address);     // kiểm tra representability
cap      = cheriot_encode_cap(new_dcap);
if (clrtag) cap.valid = 1'b0;                     // csr_mepcc_clrtag_i từ controller
```

### 3.1 CHERIoT set/clear MIE

`ibex_cs_registers.sv:1060-1072`

```systemverilog
mstatus_en_combi = mstatus_en | (cheriot_on & (cheriot_csr_clr_mie_i | cheriot_csr_set_mie_i));
mstatus_d_combi.mie = (mstatus_d.mie & ~(cheriot_on & cheriot_csr_clr_mie_i))
                    | (cheriot_on & cheriot_csr_set_mie_i);
```

Cơ chế sentry (§4.4 của [07_cheriot_ex.md](07_cheriot_ex.md)) can thiệp trực tiếp
vào `mstatus.MIE` qua đường này.

### 3.2 Kiểm soát truy cập CSR theo capability

`ibex_cs_registers.sv:1015-1025`

```systemverilog
csr_we_int = csr_wr & csr_op_en_i
           & (~CHERIoT | (cheriot_enable_i != IbexMuBiOn) | debug_mode_i | pcc_cap_q.perms.SR)
           & ~illegal_csr_insn_o;
```

Ở chế độ CHERIoT, **mọi** ghi CSR đều đòi `pcc.perms.SR = 1` (trừ trong debug mode).
Exception ASR được sinh riêng ở controller; điều kiện này chỉ là lớp bảo vệ thứ hai
(defence in depth).

Đọc CSR không bị gate — vì lệnh sẽ bị fault ngay sau đó nên giá trị đọc được không có
hiệu lực kiến trúc.

---

## 4. ePMP (`ibex_pmp`)

`ibex/rtl/ibex_pmp.sv`. Cấu hình: `PMPNumRegions = 16`, `PMPGranularity = 0`, `PMPNumChan = 3`.

### 4.1 Ba kênh

`ibex_core.sv:1583-1612`:

| Kênh | Địa chỉ | Loại | Priv level |
|---|---|---|---|
| `PMP_I` (0) | `{2'b00, pc_if}` | `PMP_ACC_EXEC` | `priv_mode_id` |
| `PMP_I2` (1) | `{2'b00, pc_if + 2}` | `PMP_ACC_EXEC` | `priv_mode_id` |
| `PMP_D` (2) | `{2'b00, data_addr_o}` | `we ? WRITE : READ` | `priv_mode_lsu` |

```systemverilog
priv_mode_lsu_o = mstatus_q.mprv ? mstatus_q.mpp : priv_lvl_q;   // MPRV
```

### 4.2 Cổng CHERIoT

`ibex_core.sv:1592-1596` và `:1750-1760`:

```systemverilog
// Cổng ĐỊA CHỈ về 0 để comparator không chuyển trạng thái (tiết kiệm công suất)
pmp_req_addr[PMP_I] = (cheriot_enable_i == IbexMuBiOn) ? '0 : {2'b00, pc_if};

// Cổng LỖI về 0
pmp_req_err[PMP_I]  = (cheriot_enable_i == IbexMuBiOn) ? 1'b0 : pmp_req_err_raw[PMP_I];
```

Ở chế độ CHERIoT, capability thay thế hoàn toàn ePMP.

### 4.3 Tính vùng địa chỉ

`ibex_pmp.sv:157-185`

```systemverilog
// TOR: start = cfg[r-1] (hoặc 0 với r=0); NA4/NAPOT: start = cfg[r]
region_start_addr[r] = (cfg[r].mode == PMP_MODE_TOR) ? (r==0 ? 0 : csr_pmp_addr[r-1])
                                                     : csr_pmp_addr[r];

// Mask cho NAPOT: bit b bị mask nếu mọi bit dưới nó (tới PMP_ADDR_LSB) đều là 1
region_addr_mask[r][b] = (cfg[r].mode != PMP_MODE_NAPOT) | ~&csr_pmp_addr[r][b-1:2];
```

`PMPGranularity = 0` → `PMP_ADDR_LSB = 2` → so sánh từ bit địa chỉ [2] trở lên,
granularity nhỏ nhất **4 byte**.

### 4.4 So khớp vùng

```systemverilog
region_match_eq[c][r] = (addr & mask) == (start & mask);
region_match_gt[c][r] =  addr > start;
region_match_lt[c][r] =  addr < csr_pmp_addr[r];

unique case (cfg[r].mode)
  PMP_MODE_OFF:   match = 0;
  PMP_MODE_NA4:   match = eq;
  PMP_MODE_NAPOT: match = eq;
  PMP_MODE_TOR:   match = (eq | gt) & lt;
endcase
```

### 4.5 Kiểm tra quyền — Smepmp

`ibex_pmp.sv:59-127`

```systemverilog
region_basic_perm_check[c][r] = (type==EXEC  & cfg[r].exec)
                              | (type==WRITE & cfg[r].write)
                              | (type==READ  & cfg[r].read);

region_perm_check[c][r] = mseccfg.mml ? mml_perm_check(...) : orig_perm_check(...);
```

**`orig_perm_check`** (PMP gốc):
```systemverilog
return (priv == M) ? (~cfg.lock | permission_check) : permission_check;
```
M-mode bỏ qua vùng không khoá; vùng khoá vẫn áp dụng cho M-mode.

**`mml_perm_check`** (Smepmp/ePMP, khi `mseccfg.MML = 1`) — bảng `R=0, W=1` đặc biệt:

| `{L, X}` | Ý nghĩa |
|---|---|
| `2'b00` | Read/Write ở M, **Read-only** ở S/U |
| `2'b01` | Read/Write ở M/S/U |
| `2'b10` | **Execute-only** ở M/S/U |
| `2'b11` | Read/Execute ở M, **Execute-only** ở S/U |

Ngoài ra: `R=1,W=1,X=1,L=1` → vùng **shared read-only** (chỉ đọc cho mọi mode).
Các trường hợp khác: `permission_check & (priv==M ? cfg.lock : ~cfg.lock)` —
tức ở MML, ý nghĩa bit L bị **đảo**: L=1 nghĩa là "vùng của M-mode".

### 4.6 Quyết định lỗi

`ibex_pmp.sv:128-150`

```systemverilog
access_fail = mseccfg.mmwp                                  // Machine Mode Whitelist Policy
            | (priv != PRIV_LVL_M)                          // mặc định từ chối cho S/U
            | (mseccfg.mml && (type == PMP_ACC_EXEC));      // MML: M-mode không exec vùng không khớp

for (r = 0; r < 16; r++)                                    // ƯU TIÊN TĨNH: vùng 0 cao nhất
  if (!matched && match_all[r]) { access_fail = ~final_perm_check[r]; matched = 1; }
```

`pmp_req_err_o[c] = ~debug_mode_allowed_access[c] & access_fault_check_res[c]` với
```systemverilog
debug_mode_allowed_access[c] = debug_mode_i & ((addr & ~DmAddrMask) == DmBaseAddr);
```
→ Trong debug mode, truy cập vùng Debug Module (`0x1A110000` ± `0xFFF`) **luôn** được phép
(bắt buộc theo RISC-V Debug Spec §A.2).

### 4.7 CSR PMP với RLB (Rule Locking Bypass)

`ibex_cs_registers.sv:1359-1548`. Điều kiện ghi `pmpcfg`/`pmpaddr`:

* Vùng bị khoá (`cfg.lock = 1`) → **không** ghi được, trừ khi `mseccfg.rlb = 1`.
* `pmpaddr[i]` cũng bị khoá nếu `pmpcfg[i+1].mode == TOR` và `pmpcfg[i+1].lock`.
* `mseccfg`: `MML` và `MMWP` là **sticky** (chỉ set được, không clear).
  `RLB` chỉ clear được; và không set được khi có vùng nào đang khoá.

---

## 5. Bộ đếm hiệu năng

### 5.1 `ibex_counter`

`ibex/rtl/ibex_counter.sv`

```systemverilog
counter_upd = counter[W-1:0] + 1;
we          = counter_we_i | counterh_we_i;
counter_load = counterh_we_i ? {counter_val_i, counter[31:0]}
                             : {counter[63:32], counter_val_i};
counter_d = we ? counter_load[W-1:0] : (counter_inc_i ? counter_upd : counter[W-1:0]);
```

`ProvideValUpd` (chỉ cho `minstret` và `mhpmcounter10`) điều khiển có xuất
`counter_val_upd_o` (giá trị **đã tăng**) hay không. Tham số này tồn tại vì nếu xuất
giá trị tăng thì Xilinx **không** infer được DSP48.

Trên FPGA Xilinx, `UseDsp = (CounterWidth < 49) ? "yes" : "no"` và dùng **sync reset**
(DSP48 chỉ hỗ trợ sync reset).

### 5.2 Các counter được instantiate (MHPMCounterNum = 10)

| Chỉ số | CSR | Rộng | Sự kiện |
|---|---|---|---|
| 0 | `mcycle` | **64** | `1'b1` (mỗi chu kỳ) |
| 1 | — | — | **reserved**, đọc 0 |
| 2 | `minstret` | **64** | `instr_ret_i` |
| 3 | `mhpmcounter3` | 32 | `dside_wait_i` — chu kỳ chờ D-mem |
| 4 | `mhpmcounter4` | 32 | `iside_wait_i` — chu kỳ chờ I-mem |
| 5 | `mhpmcounter5` | 32 | `mem_load_i` — số lệnh load |
| 6 | `mhpmcounter6` | 32 | `mem_store_i` — số lệnh store |
| 7 | `mhpmcounter7` | 32 | `jump_i` — số jump |
| 8 | `mhpmcounter8` | 32 | `branch_i` — số branch |
| 9 | `mhpmcounter9` | 32 | `branch_taken_i` — branch taken |
| 10 | `mhpmcounter10` | 32 | `instr_ret_compressed_i` |
| 11 | `mhpmcounter11` | 32 | `mul_wait_i` — chu kỳ chờ nhân |
| 12 | `mhpmcounter12` | 32 | `div_wait_i` — chu kỳ chờ chia |
| 13–31 | — | — | **không hiện thực**, đọc 0 |

`mhpmevent[i][i-3] = 1'b1` — event selector hard-wired, đọc ra bitmask.

### 5.3 Giá trị suy đoán cho `minstret` / `mhpmcounter10`

```systemverilog
mhpmcounter[2]  = instr_ret_spec_i & ~mcountinhibit[2] ? minstret_next : minstret_raw;
mhpmcounter[10] = instr_ret_compressed_spec_i & ~mcountinhibit[10] ? mhpmcounter_next
                                                                   : mhpmcounter_raw;
```

Xem [09_tang_WB.md](09_tang_WB.md) §6.

### 5.4 `mcountinhibit` / `mcounteren`

```systemverilog
mcountinhibit_d = csr_wdata_int[12:0];  mcountinhibit_d[1] = 1'b0;   // bit 1 luôn 0
mcounteren_d    = csr_wdata_int[12:0];  mcounteren_d[1]    = 1'b0;   // không có time CSR
mcountinhibit   = {16'b0, mcountinhibit_q};                          // MHPMCounterNum<29
```

`mcounteren` chỉ ghi được khi `mcounteren_writable_i == IbexMuBiOn` — chân cấp top-level,
cho phép SoC khoá cứng việc U-mode đọc counter (chống side-channel qua `cycle`).

---

## 6. Debug Trigger

`ibex_cs_registers.sv:1754-1882` — `DbgTriggerEn = 1`, `DbgHwBreakNum = 1`.

```systemverilog
tselect_we      = csr_we_int & debug_mode_i & (csr_addr == CSR_TSELECT);
tmatch_control_we[i] = (i == tselect_q) & csr_we_int & debug_mode_i & (csr_addr == CSR_TDATA1);
tmatch_value_we[i]   = (i == tselect_q) & csr_we_int & debug_mode_i & (csr_addr == CSR_TDATA2);

tmatch_control_d = csr_wdata_int[2];       // chỉ bit "execute"
tmatch_value_d   = csr_wdata_int[31:0];

trigger_match[i] = tmatch_control_q[i] & (pc_if_i[31:0] == tmatch_value_q[i]);
trigger_match_o  = |trigger_match;
```

`tdata1` đọc ra pattern cố định (`ibex_cs_registers.sv:1848-1868`):

| Trường | Giá trị | Ý nghĩa |
|---|---|---|
| `type[3:0]` | `4'h2` | Address/data match trigger |
| `dmode` | `1'b1` | Chỉ truy cập từ debug mode |
| `maskmax[5:0]` | `6'h00` | Chỉ so khớp chính xác |
| `hit` | 0 | Không hỗ trợ |
| `select` | 0 | Chỉ so địa chỉ |
| `timing` | 0 | Match **trước** khi thực thi |
| `sizelo[1:0]` | `2'b00` | Mọi kích thước |
| `action[3:0]` | `4'h1` | Vào debug mode |
| `chain` | 0 | Không hỗ trợ |
| `match[3:0]` | `4'h0` | So khớp đơn giản |
| `m` | 1 | Khớp ở M-mode |
| `u` | 1 | Khớp ở U-mode |
| `execute` | ghi được | Bật trigger |
| `store`, `load` | 0 | **Không hỗ trợ** data watchpoint |

So khớp với `pc_if_i` (không phải `pc_id_i`) vì `timing = 0` — trigger phải kích hoạt
**trước** khi lệnh được thực thi.

`tselect` chỉ nhận giá trị `< DbgHwBreakNum`, ngược lại bị kẹp về `MaxTselect` —
debugger dò số trigger bằng cách ghi giá trị lớn rồi đọc lại.

---

## 7. Kiểm tra truy cập CSR

`ibex_cs_registers.sv:402-407`

```systemverilog
illegal_csr_dbg    = dbg_csr & ~debug_mode_i;               // CSR debug ngoài debug mode
illegal_csr_priv   = (csr_addr[9:8] > priv_lvl_q);          // bit [9:8] = privilege tối thiểu
illegal_csr_write  = (csr_addr[11:10] == 2'b11) && csr_wr;  // bit [11:10]=11 → read-only
illegal_csr_insn_o = csr_access_i & (illegal_csr | illegal_csr_write
                                   | illegal_csr_priv | illegal_csr_dbg);
```

`illegal_csr` được set trong khối đọc (`always_comb`) cho mọi địa chỉ không nhận dạng được.

U-mode đọc counter (`0xC00`–`0xC1F`) còn phải qua `mcounteren`:
kiểm tra bổ sung trong nhánh đọc của các CSR `CYCLE`/`INSTRET`/`HPMCOUNTER*`.

---

## 8. Sơ đồ nguồn ghi vào `mepc` / `mtvec` / `depc`

```
                    ┌──────────────────────────────────────────────┐
  csr_wdata_int ───►│                                              │
  (CSRRW/S/C)       │  mepc_d = {wdata[31:1], 1'b0}   mepc_en ────►│
  exception_pc ────►│  mepc_d = exception_pc          mepc_en ────►│──► mepc_d_combi
  mstack_epc_q ────►│  (NMI mret)                                  │    mepc_en_combi
  cheriot_csr_wdata►│  mepc_en_cheriot (CSpecialRW MEPCC) ────────►│         │
                    └──────────────────────────────────────────────┘         ▼
                                                                    ┌─────────────┐
                                                                    │ ibex_csr    │
                                                                    │ u_mepc_csr  │──► mepc_q
                                                                    └─────────────┘

                    ┌──────────────────────────────────────────────┐
  pcc_exc_cap ─────►│ (csr_save_cause & !debug)                    │
  mstack_epc_cap_q ►│ (mret & nmi_mode)                            │──► mepc_cap (flop riêng)
  cheriot_csr_wcap ►│ (CSpecialRW MEPCC)                           │
                    └──────────────────────────────────────────────┘
```
