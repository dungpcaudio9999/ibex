# 07 — Khối CHERIoT EX & định dạng capability

Tệp: `ibex/rtl/ibex_cheriot_ex.sv` (1031 dòng), `ibex_cheriot_pkg.sv` (965 dòng).

Đây là phần **đặc thù nhất** của bản Ibex này so với upstream. `ibex_cheriot_ex` chạy
**song song** với `ibex_ex_block` trong cùng tầng ID/EX.

---

## 1. Định dạng capability

### 1.1 Biểu diễn nén `cap_t` — 35 bit

`ibex_cheriot_pkg.sv:87-97`

```
 [34:33]  [32]    [31]   [30:25]   [24:22]  [21:18]  [17:9]  [8:0]
┌────────┬───────┬──────┬─────────┬────────┬────────┬───────┬───────┐
│cap_cor │ valid │ rsvd │ cperms  │ otype  │  cexp  │  top  │ base  │
│ (2b)   │ (tag) │ (R)  │  (6b)   │  (3b)  │  (4b)  │ (9b)  │ (9b)  │
└────────┴───────┴──────┴─────────┴────────┴────────┴───────┴───────┘
 ↑ mở rộng nội bộ   ↑──────── 33 bit theo spec v1.0 chương 7.13 ────────↑
```

Bit `[32:0]` **khớp 1:1** với định dạng trong đặc tả → ghi ra bộ nhớ chỉ là phép cắt
(`cheriot_cap_to_mem` = `cap_bits[32:0]`). Bit `[34:33]` (`cap_cor`) là **tối ưu hoá của
implementation**, không có trong spec.

Cùng với **địa chỉ 32-bit** lưu trong `rf_data`, mỗi thanh ghi CHERIoT = 32 + 35 = 67 bit.

### 1.2 Biểu diễn giải nén `decoded_cap_t` — 112 bit

`ibex_cheriot_pkg.sv:100-114`

```
 [111:79]   [78:47]    [46:35]   [34:0]
┌──────────┬──────────┬─────────┬───────────────────┐
│  top33   │  base32  │  perms  │ ... giống cap_t ...│
│  (33b)   │  (32b)   │  (12b)  │      (35b)        │
└──────────┴──────────┴─────────┴───────────────────┘
```

35 bit thấp **giống hệt** `cap_t` → `cheriot_encode_cap()` chỉ là một phép cast xuống.

### 1.3 Permissions

`ibex_cheriot_pkg.sv:39-52` — 12 bit mở rộng:

| Bit | Tên | Ý nghĩa |
|---|---|---|
| 11 | `U0` | User-defined |
| 10 | `SE` | Seal |
| 9 | `US` | Unseal |
| 8 | `EX` | Execute |
| 7 | `SR` | Access System Registers (quyền CSR!) |
| 6 | `MC` | Load/Store Capability |
| 5 | `LD` | Load |
| 4 | `SL` | Store Local capability |
| 3 | `LM` | Load Mutable |
| 2 | `SD` | Store |
| 1 | `LG` | Load Global |
| 0 | `GL` | Global |

Nén thành 6 bit (`cperms`) theo 6 "format" (`ibex_cheriot_pkg.sv:203-240`):

| `cperms[4:...]` | Format | Mask ngầm định | Bit biến thiên |
|---|---|---|---|
| `[4:3] == 2'b11` | Memory cap-read-write | `LD,MC,SD` | `[0]=LG, [1]=LM, [2]=SL` |
| `[4:2] == 3'b101` | Memory cap-read-only | `LD,MC` | `[0]=LG, [1]=LM` |
| `[4:0] == 5'b10000` | Memory cap-write-only | `SD,MC` | — |
| `[4:2] == 3'b100` | Memory data-only | — | `[0]=SD, [1]=LD` |
| `[4:3] == 2'b01` | Executable | `EX,MC,LD` | `[0]=LG, [1]=LM, [2]=SR` |
| `[4:3] == 2'b00` | Sealing | — | `[0]=US, [1]=SE, [2]=U0` |

`cperms[5]` luôn là `GL`.

### 1.4 Object type (sealing)

`ibex_cheriot_pkg.sv:55-61`

| Giá trị | Tên | Ý nghĩa |
|---|---|---|
| 0 | `OTYPE_UNSEALED` | Không niêm phong |
| 1 | `OTYPE_SENTRY_II_FWD` | Forward sentry, **kế thừa** trạng thái interrupt |
| 2 | `OTYPE_SENTRY_ID_FWD` | Forward sentry, **tắt** interrupt khi nhảy |
| 3 | `OTYPE_SENTRY_IE_FWD` | Forward sentry, **bật** interrupt khi nhảy |
| 4 | `OTYPE_SENTRY_ID_BKWD` | Backward sentry (địa chỉ trả về), tắt interrupt |
| 5 | `OTYPE_SENTRY_IE_BKWD` | Backward sentry, bật interrupt |

> Đây là cơ chế **interrupt control qua capability**: chỉ cần nhảy qua một sentry
> phù hợp là `mstatus.MIE` tự động đổi — xem §4.4.

### 1.5 Bounds nén & `cap_cor`

`ibex_cheriot_pkg.sv:347-400`

Top và base được lưu dưới dạng **mantissa 9 bit** + **exponent 4 bit**. Địa chỉ đầy đủ:

```
bound33 = ((addr & mask) + (cor << exp << 9)) | (mant << exp)
   với mask = (33'h1_FFFF_FFFF << exp) << 9
```

Vì mantissa chỉ có 9 bit, phần cao của bound "mượn" từ **địa chỉ hiện tại**. Nếu top hoặc
base nằm ở "vùng" 2^(e+9) khác với địa chỉ thì cần một **correction** ±1.

`cap_cor` mã hoá `{top_hi XOR addr_hi, addr_hi}` với:
* `top_hi  = (top < base)`
* `addr_hi = (addr < base)` (so sánh trên mantissa 9 bit)

| `cap_cor` | top correction | base correction | Tình huống |
|---|---|---|---|
| `2'b00` | 0 | 0 | top và addr cùng vùng với base |
| `2'b01` | 0 | −1 | top và addr đều ở vùng trên |
| `2'b10` | +1 | 0 | top ở vùng trên, addr không |
| `2'b11` | −1 | −1 | addr ở vùng trên, top không |

**Vì sao lưu `cap_cor` trong register file?** Comment (`ibex_cheriot_pkg.sv:365-385`):
tính correction cần so sánh đắt; thay vì làm mỗi lần đọc thanh ghi, ta tính **một lần**
khi bounds/address thay đổi và lưu 2 bit. `cheriot_get_top_correction()` /
`cheriot_get_base_correction()` chỉ là logic tổ hợp vài cổng.

Exponent: `cexp` 4 bit, giá trị `15` (`MAXCEXP`) giải mã thành `24` (`MAXEXP`)
— tức phủ toàn bộ không gian 32-bit.

### 1.6 Root capabilities

`ibex_cheriot_pkg.sv:144-190`

| Hằng | `cperms` | Dùng làm |
|---|---|---|
| `ROOT_CAP_TX` / `ROOT_DECODED_CAP_TX` | `6'b101111` | **PCC reset**, `mtvec_cap` reset, `mepc_cap` reset |
| `ROOT_CAP_TM` | `6'b111111` | `mtdc_cap` reset |
| `ROOT_CAP_TS` | `6'b100111` | `mscratchc_cap` reset |

`ROOT_DECODED_CAP_TX`: `top33 = 0x1_0000_0000`, `base32 = 0`, `perms = 12'h1eb`,
`valid = 1`, `cexp = 15`, `top = 9'h100`, `base = 0`.
→ PCC sau reset phủ toàn bộ 4 GiB với quyền EX+MC+LD+SR+GL+LG+LM.

---

## 2. Cấu trúc `ibex_cheriot_ex`

```
 rf_rdata_a/b, rf_rcap_a/b ──┐
 fwd_wdata/wcap (từ WB) ─────┤
                             ▼
                     ┌───────────────┐
                     │ fwd_data_merger│  forwarding riêng cho cap
                     └───────┬───────┘
                             ▼ rf_rdata_ng_a/b, rf_rcap_ng_a/b
                     ┌───────────────┐
                     │ operand gating│  gate về 0 nếu không phải lệnh CHERIoT/RV32-LSU
                     └───────┬───────┘
                             ▼ rf_rdata_a/b, rf_rcap_a/b
                 ┌───────────┴───────────┐
                 ▼                       ▼
        cheriot_decode_cap()     shared_adder (32-bit)
        → rf_fullcap_a/b          → addr_result
                 │                       │
    ┌────────────┼───────────────────────┼───────────────┐
    ▼            ▼                       ▼               ▼
┌─────────┐ ┌──────────────┐  ┌──────────────────┐ ┌───────────┐
│ main_ex │ │set_address   │  │ set_bounds_comb  │ │check_rv32 │
│ (26 case│ │  _comb       │  │ prep+ex+rounddown│ │check_cher.│
│  one-hot│ └──────────────┘  └──────────────────┘ └───────────┘
└────┬────┘                                              │
     │ result_data/cap, cheriot_rf_we, branch_req,        │ addr_bound_vio
     │ csr_*, pcc_cap_o, cheriot_wb_err_raw               │ perm_vio_vec
     ▼                                                    ▼
 tới WB stage                                       lsu_cheriot_err_o
                                                    cheriot_wb_err_info
```

### 2.1 Forwarding capability

`ibex_cheriot_ex.sv:209-226`

```systemverilog
always_comb begin : fwd_data_merger
  if ((rf_raddr_a_i == fwd_waddr_i) && fwd_we_i && (|rf_raddr_a_i)) begin
    rf_rdata_ng_a = fwd_wdata_i;   rf_rcap_ng_a = fwd_wcap_i;
  end else begin
    rf_rdata_ng_a = rf_rdata_a_i;  rf_rcap_ng_a = rf_rcap_a_i;
  end
  // tương tự cho port b
end
```

**Khác với ID stage:** ID chỉ forward `rf_wdata_fwd_wb_i` (32 bit dữ liệu);
CHERIoT EX phải forward cả `rf_wcap_fwd_wb_i` (35 bit metadata). Đây là logic
**độc lập**, không dùng `rf_rdata_a_fwd` của ID.

### 2.2 Cổng toán hạng (tiết kiệm công suất)

```systemverilog
rf_rcap_a  = (instr_is_cheriot_i | instr_is_rv32lsu_i) ? rf_rcap_ng_a  : NULL_CAP;
rf_rdata_a = (instr_is_cheriot_i | instr_is_rv32lsu_i) ? rf_rdata_ng_a : 32'h0;
rf_rcap_b  = instr_is_cheriot_i ? rf_rcap_ng_b : NULL_CAP;
rf_rdata_b = instr_is_cheriot_i ? rf_rdata_ng_b : 32'h0;
```

`rf_fullcap_a/b = cheriot_decode_cap(...)` là logic rất lớn (giải nén bounds 33 bit,
permissions 12 bit). Gating đầu vào giữ nó tĩnh khi lệnh không liên quan.

Lưu ý port **a** cũng được bật cho lệnh load/store RV32 (`instr_is_rv32lsu_i`) — vì
địa chỉ RV32 vẫn phải được kiểm tra với capability trong rs1.

### 2.3 Gate đầu ra bằng `cheriot_exec_id_i`

`ibex_cheriot_ex.sv:244-258`

```systemverilog
cheriot_rf_we_o   = cheriot_rf_we_raw   & cheriot_exec_id_i;
branch_req_o      = branch_req_raw      & cheriot_exec_id_i;
branch_req_spec_o = branch_req_spec_raw & cheriot_exec_id_i;
csr_set_mie_o     = csr_set_mie_raw     & cheriot_exec_id_i;
csr_clr_mie_o     = csr_clr_mie_raw     & cheriot_exec_id_i;
csr_op_en_o       = csr_op_en_raw       & cheriot_exec_id_i;
cheriot_ex_valid_o= cheriot_ex_valid_raw& cheriot_exec_id_i;
cheriot_ex_err_o  = cheriot_ex_err_raw  & cheriot_exec_id_i & ~debug_mode_i;
```

---

## 3. Bộ cộng dùng chung

`ibex_cheriot_ex.sv:601-620`

```systemverilog
unique case (cheriot_adder_a_sel_i)
  CHERIOT_ADDER_A_IMM12: tmp32a = {{20{imm12[11]}}, imm12};
  CHERIOT_ADDER_A_IMM21: tmp32a = {{11{imm21[20]}}, imm21};
  CHERIOT_ADDER_A_IMM20: tmp32a = {imm20[19], imm20, 11'h0};    // imm20 << 11? xem ghi chú
  CHERIOT_ADDER_A_RS2:   tmp32a = rf_rdata_b;
  default:               tmp32a = 32'h0;
endcase
unique case (cheriot_adder_b_sel_i)
  CHERIOT_ADDER_B_RS1: tmp32b = rf_rdata_a;
  CHERIOT_ADDER_B_PC:  tmp32b = pc_id_i;
  default:             tmp32b = 32'h0;
endcase
addr_result = tmp32a + tmp32b;
```

Bộ cộng 32-bit duy nhất phục vụ: `CJAL`, `CJALR`, `CAUIPCC`, `CAUICGP`, `CSetAddr`,
`CIncAddr`, `CIncAddrImm`.

Đường địa chỉ load/store **tách riêng** để giúp timing:
```systemverilog
cs1_imm          = (is_cap | CJALR) ? {{20{imm12[11]}}, imm12} : '0;
cs1_addr_plusimm = rf_rdata_a + cs1_imm;
cheriot_lsu_addr = cs1_addr_plusimm + {29'h0, addr_incr_req_i, 2'b00};   // +4 cho word 2
pc_id_nxt        = pc_id_i + (instr_is_compressed_i ? 2 : 4);
```

---

## 4. Khối `main_ex` — 26 nhánh one-hot

`ibex_cheriot_ex.sv:265-560`, `unique case (1'b1)` trên các bit của `cheriot_operator_i`.

### 4.1 `CGET_FIELD` — đọc trường capability

```systemverilog
CFIELD_PERM: result_data = {20'h0, rf_fullcap_a.perms};              // 12 bit
CFIELD_TYPE: result_data = {28'h0, cheriot_decode_otype(otype, perms.EX)};
CFIELD_BASE: result_data = rf_fullcap_a.base32;
CFIELD_TOP:  result_data = top33[32] ? 32'hffff_ffff : top33[31:0];  // bão hoà
CFIELD_LEN:  result_data = cheriot_cap_length(rf_fullcap_a);         // bão hoà
CFIELD_TAG:  result_data = {31'h0, rf_fullcap_a.valid};
CFIELD_ADDR: result_data = rf_rdata_a;
CFIELD_HIGH: result_data = 32'(cheriot_cap_to_mem(rf_rcap_a));       // 33 bit cắt còn 32
```

`cheriot_decode_otype(otype3, perm_ex)` = `{~perm_ex & (otype3 != 0), otype3}` — otype
không-thực-thi được đánh dấu ở bit 3 để phần mềm phân biệt sentry và sealing key.

### 4.2 `CSEAL` / `CUNSEAL`

```systemverilog
CSEAL:   result_cap = encode(seal(fullcap_a, rf_rdata_b[2:0]));
CUNSEAL: tfcap = unseal(fullcap_a);
         tfcap.perms.GL = fullcap_a.perms.GL & fullcap_b.perms.GL;   // GL bị hạ
         tfcap.cperms   = compress_perms(tfcap.perms);
         result_cap     = encode(tfcap);

result_cap.valid &= ~addr_bound_vio & ~perm_vio;     // KHÔNG sinh exception, chỉ xoá tag
```

Kiểm tra (`ibex_cheriot_ex.sv:828-840`):
* `CSEAL`: `cs2` phải hợp lệ, không sealed, có `SE`, và `cs2.addr` nằm trong
  `[cs2.base, cs2.top)`. Với `cs1` có `EX`: otype hợp lệ 1–7; không `EX`: 9–15.
* `CUNSEAL`: `cs1` phải **đang** sealed, `cs2` không sealed và có `US`,
  `cs2.addr == cs1.otype` (kiểm tra qua bound check với `chk_base_chkaddr = otype`).

### 4.3 `CAND_PERM`

```systemverilog
tfcap.perms  = perms_t'(12'(tfcap.perms) & rf_rdata_b[11:0]);
tfcap.cperms = compress_perms(tfcap.perms);
pmask        = perms_t'(rf_rdata_b[11:0]);  pmask.GL = 1'b1;
tfcap.valid  = tfcap.valid & (~is_sealed(fullcap_a) | (&12'(pmask)));
```

Capability đã sealed **chỉ** giữ được tag nếu mask (bỏ qua GL) là toàn 1 — tức không
thực sự bớt quyền nào.

### 4.4 `CJAL` / `CJALR` — jump + điều khiển interrupt

```systemverilog
branch_target_o = {addr_result[31:1], 1'b0};       // RV32 JALR semantics: cộng rồi mask bit 0
pcc_cap_o       = cheriot_unseal(rf_fullcap_a);    // PCC mới = cs1 đã unseal
result_data_o   = pc_id_nxt;                       // link address

seal_type = csr_mstatus_mie_i ? OTYPE_SENTRY_IE_BKWD : OTYPE_SENTRY_ID_BKWD;
tfcap     = (rf_waddr_i == 5'h1) ? cheriot_seal(setaddr1_outcap, seal_type)
                                 : setaddr1_outcap;
result_cap_o = encode(tfcap);
```

**Điểm mấu chốt:** nếu đích ghi là `x1` (= `ra`), địa chỉ trả về được **tự động seal**
thành backward sentry, mã hoá trạng thái `MIE` **hiện tại**. Khi `ret` (jalr x0, 0(ra)),
`MIE` được khôi phục:

```systemverilog
csr_set_mie_raw = ~instr_fault && CJALR &&
                  ((fullcap_a.otype == OTYPE_SENTRY_IE_FWD) ||
                   (fullcap_a.otype == OTYPE_SENTRY_IE_BKWD));
csr_clr_mie_raw = ~instr_fault && CJALR &&
                  ((fullcap_a.otype == OTYPE_SENTRY_ID_FWD) ||
                   (fullcap_a.otype == OTYPE_SENTRY_ID_BKWD));
```

Đây là cơ chế "interrupt-safe compartment switch" của CHERIoT: không cần lệnh CSR để
bật/tắt interrupt, mà gắn vào chính capability của hàm.

Ràng buộc otype cho `CJALR` (`ibex_cheriot_ex.sv:845-856`):

```systemverilog
perm_vio_vec[PVIO_SEAL] =
  (is_sealed(cs1) && (imm12 != 0)) ||        // sealed thì offset phải = 0
  ~( (rd==0 && rs1==1 && otype_45)           // ret: backward sentry
   | (rd==0 && rs1!=1 && (otype_0|otype_1))  // tail call: unsealed / inherit sentry
   | (rd==1 && (otype_0 | otype_23))         // call: unsealed / forward ID/IE sentry
   | (rd!=0 && (otype_0 | otype_1)) );       // jalr khác
perm_vio_vec[PVIO_EX] = ~fullcap_a.perms.EX;
```

`branch_req_o` (cập nhật PCC trong CSR) chỉ bật cho `CJALR`, **không** cho `CJAL` —
vì `CJAL` giữ nguyên PCC (chỉ đổi address, bounds giữ nguyên).
`branch_req_spec_o` bật cho cả hai (để IF fetch sớm).

### 4.5 `CCSR_RW` — CSpecialRW

```systemverilog
is_ztop       = (cs2_dec == CHERIOT_SCR_ZTOPC);        // 5'h1b
is_write      = (rf_raddr_a_i != 0);                   // cs1 != C0 → ghi
instr_fault   = perm_vio | illegal_scr_addr;
csr_op_en_raw = ~instr_fault && is_write && ~is_ztop;

illegal_scr_addr = (csr_addr_o < 24) | (csr_addr_o == 27) |
                   (~debug_mode_i & (csr_addr_o < 28));
perm_vio_vec[PVIO_ASR] = ~pcc_cap_i.perms.SR;
```

Dải SCR hợp lệ: 24–31, trừ 27 (`ZTOPC` chưa hiện thực). Ngoài debug mode chỉ cho phép
28–31 (`DEPCC`=24, `DSCRATCHC0`=25, `DSCRATCHC1`=26 là SCR debug).

**Legalization cho MTCC và MEPCC** (quan trọng):
```systemverilog
// MTCC: địa chỉ phải align 4
csr_wdata_o = {rf_rdata_a[31:2], 2'b00};
trcap       = encode(setaddr1_outcap);
trcap.valid = (rf_rdata_a[1:0] != 0 || ~perms.EX || otype != 0) ? 1'b0 : fullcap_a.valid;

// MEPCC: địa chỉ phải align 2
csr_wdata_o = {rf_rdata_a[31:1], 1'b0};
trcap.valid = (rf_rdata_a[0] != 0 || ~perms.EX || otype != 0) ? 1'b0 : fullcap_a.valid;
```
`scr_legalization = 1` kích hoạt nhánh `SETADDR_SCR` trong `set_address_comb` để
**tính lại `cap_cor`** cho địa chỉ đã cắt — khớp với mô hình tham chiếu Sail
ngay cả khi capability vẫn bị xoá tag.

### 4.6 `CLOAD_CAP` / `CSTORE_CAP`

```systemverilog
CLOAD_CAP:
  lc_cglg  = ~fullcap_a.perms.LG;   // thiếu LG → capability load về bị xoá GL và LG
  lc_csdlm = ~fullcap_a.perms.LM;   // thiếu LM → xoá SD và LM
  lc_ctag  = ~fullcap_a.perms.MC;   // thiếu MC → xoá luôn tag
  cheriot_rf_we_raw = 0;            // RF được ghi bởi LSU, không phải ở đây
  cheriot_ex_err_raw = 0;           // lỗi được chuyển cho LSU → báo ở WB

CSTORE_CAP:
  csc_wcap       = rf_rcap_b;
  csc_wcap.valid = rf_rcap_b.valid & ~perm_vio_slc;   // thiếu SL + cap non-global → xoá tag
```

`perm_vio_slc = ~fullcap_a.perms.SL && fullcap_b.valid && ~fullcap_b.perms.GL`
— "store local": capability không-global chỉ được lưu qua capability có quyền `SL`.
Vi phạm **không** sinh exception (trừ khi debug), chỉ xoá tag.

Quy tắc clearing áp dụng ở LSU qua `cheriot_mask_loaded_cperms()`
(`ibex_cheriot_pkg.sv:284-338`).

### 4.7 Các lệnh so sánh/số học

| Lệnh | Kết quả |
|---|---|
| `CIS_SUBSET` | `(a.valid == b.valid) && ~addr_bound_vio && (&(a.perms \| ~b.perms))` |
| `CIS_EQUAL` | `cheriot_caps_equal(a, b, addr_a, addr_b)` — so tất cả trường + địa chỉ |
| `CSUB_CAP` | `rf_rdata_a - rf_rdata_b` (chỉ địa chỉ) |
| `CMOVE_CAP` | copy nguyên `{rf_rdata_a, rf_rcap_a}` |
| `CCLEAR_TAG` | copy, `valid = 0` |
| `CSET_HIGH` | `cheriot_mem_to_cap({1'b0, rs2}, {1'b0, rs1}, 0)` — ghi đè metadata |

---

## 5. Set-Address và Set-Bounds

### 5.1 `set_address_comb`

`ibex_cheriot_ex.sv:623-644`

```systemverilog
case (cheriot_setaddr_sel_i)
  SETADDR_PCC_PCNXT: {tfcap1, taddr1} = {pcc_cap_i,   pc_id_nxt};    // CJAL/CJALR link
  SETADDR_PCC_ARITH: {tfcap1, taddr1} = {pcc_cap_i,   addr_result};  // CAUIPCC
  SETADDR_RFA_ARITH: {tfcap1, taddr1} = {rf_fullcap_a, addr_result}; // CSetAddr/CIncAddr/AUICGP
  SETADDR_SCR (& scr_legalization): {tfcap1, taddr1} = {rf_fullcap_a, csr_wdata_o};
  default:           {tfcap1, taddr1} = {NULL_DECODED_CAP, 32'h0};
endcase
setaddr1_outcap = cheriot_set_address(tfcap1, taddr1);
```

`cheriot_set_address()` (`ibex_cheriot_pkg.sv:410-438`):
```systemverilog
repr_mask      = {24{1'b1}} << exp5;                // = 0 khi exp5 == 24
ptr_minus_base = {1'b0, newptr} - {1'b0, base32};
high_delta     = ptr_minus_base[32:9] & repr_mask;
if (high_delta != 0) out_cap.valid = 1'b0;          // KHÔNG biểu diễn được → xoá tag
ptr_mantissa   = 9'(newptr >> exp5);
out_cap.cap_cor = compute_corrections(top, base, ptr_mantissa);
```

Đây là **representability check** của CHERI: địa chỉ mới phải đủ gần bounds để mantissa
9 bit còn khôi phục được bound đầy đủ.

### 5.2 `set_bounds_comb` — 2 pha

`ibex_cheriot_ex.sv:646-694`

**Pha 1: `cheriot_prep_bounds()`** (`ibex_cheriot_pkg.sv:492-518`)
```systemverilog
top33req = {1'b0, addr} + {1'b0, length};
expb     = count_trailing_zeros(addr);                  // exponent từ alignment base
explen   = msb_position({9'h0, length[31:9]});          // exponent từ độ dài
exp1     = min(explen, 24);
exp2     = min(explen + 1, 24);
in_bound = ~((top33req > in_cap.top33) || (addr < in_cap.base32));
```

**Pha 2: `cheriot_set_bounds_ex()`** (`ibex_cheriot_pkg.sv:520-610`)

Tính **song song hai đường** (exp1 và exp2), chọn theo overflow:
```systemverilog
// đường 1
mask1 = {33{1'b1}} << exp1;
base1 = 10'(addr >> exp1);
top1  = 10'(top33req >> exp1) + topoff1;     // topoff1 = có phần dư → làm tròn LÊN
len1  = top1 - base1;
ovrflw = len1[9];                             // mantissa 9 bit tràn?

// đường 2 (exp2 = exp1+1) tính song song
...
// chọn
if (~ovrflw) → dùng đường 1, else → dùng đường 2

if (req_exact & (topoff | baseoff)) out_cap.valid = 1'b0;   // CSetBoundsExact
if (~in_bound)                      out_cap.valid = 1'b0;   // vượt bounds cha
out_cap.cap_cor = tophi ? 2'b00 : 2'b10;   // base mới = addr>>exp ⇒ addr_hi = 0
```

Hai đường song song tránh phải làm tuần tự "thử exp, nếu tràn thì tăng exp" → đảm bảo
1 chu kỳ.

Đồng thời trả về:
* `maska = mask1/mask2[31:0]` → kết quả của `CRAM` (CRepresentableAlignmentMask)
* `rlen = len << exp` → kết quả của `CRRL` (CRepresentableLength)

**`cheriot_set_bounds_rounddown()`** (`ibex_cheriot_pkg.sv:613-658`) cho
`CSetBoundsRoundDown`: chọn `exp_final = min(14, explen, expb)`, base = `addr >> exp`,
top có thể là `base - 1` (length = 0) nếu không biểu diễn được.

---

## 6. Kiểm tra bound & permission

Tách làm **hai khối `always_comb` riêng** (`check_rv32` và `check_cheriot`) — comment
giải thích: gộp lại gây vòng tổ hợp `instr_executing → rv32_lsu_req → lsu_error →
cheriot_ex_err → instr_executing`.

### 6.1 `check_rv32` — cho load/store RV32I

`ibex_cheriot_ex.sv:699-740`

```systemverilog
rv32_top_offset = (type==00) ? 4 : (type==01) ? 2 : 1;      // word / half / byte
rv32_top_size_ok= (type==00) ? |top33[32:2] : (type==01) ? |top33[32:1] : |top33[32:0];

rv32_top_bound  = fullcap_a.top33 - rv32_top_offset;
rv32_base_bound = fullcap_a.base32;
rv32_top_vio    = (addr > rv32_top_bound) || ~rv32_top_size_ok;
rv32_base_vio   = (addr < rv32_base_bound);

addr_bound_vio_rv32 = (rv32_top_vio | rv32_base_vio) & ~addr_incr_req_i;   // chỉ kiểm word 1

perm_vio_vec_rv32[PVIO_TAG]  = ~fullcap_a.valid;
perm_vio_vec_rv32[PVIO_SEAL] = is_sealed(fullcap_a);
perm_vio_vec_rv32[PVIO_LD]   = ~we && ~fullcap_a.perms.LD;
perm_vio_vec_rv32[PVIO_SD]   =  we && ~fullcap_a.perms.SD;

rv32_lsu_err = cheriot_on & ~debug_mode_i & (addr_bound_vio_rv32 | perm_vio_rv32);
```

Thay vì `addr + size <= top`, mã dùng `addr <= top - size` — tránh cộng 33 bit trên
đường tới hạn. `rv32_top_size_ok` bắt trường hợp `top < size` (underflow).

Chỉ kiểm địa chỉ **đầu tiên** của truy cập lệch hàng (`~addr_incr_req_i`) — nếu word 1
lỗi thì `addr_incr_req` không bao giờ xuất hiện.

### 6.2 `check_cheriot` — cho lệnh CHERIoT

`ibex_cheriot_ex.sv:751-880`

Địa chỉ được kiểm tra thay đổi theo lệnh:

| Lệnh | `chk_base_chkaddr` | `chk_top_chkaddr` | `chk_*_bound` |
|---|---|---|---|
| `CSEAL` | `rf_rdata_b` (cs2.addr) | `{1'b0, chk_base}` | từ `fullcap_b` |
| `CUNSEAL` | `decode_otype(cs1.otype)` | `{1'b0, chk_base}` | từ `fullcap_b` |
| `CIS_SUBSET` | `fullcap_b.base32` | `fullcap_b.top33` | từ `fullcap_a` |
| `CLC`/`CSC` | `cs1_addr_plusimm` | `{chk_base[31:3], 3'b000}` | `{a.top33[32:3], 3'b000}` |
| khác | `cs1_addr_plusimm` | `{1'b0, chk_base}` | từ `fullcap_a` |

```systemverilog
chk_top_vio   = (chk_top_chkaddr  > chk_top_bound);
chk_base_vio  = (chk_base_chkaddr < chk_base_bound);
chk_top_equal = (chk_top_chkaddr == chk_top_bound);

addr_bound_vio = debug_mode_i               ? 1'b0
               : is_cap                      ? (chk_top_vio | chk_base_vio | chk_top_equal)
               : CIS_SUBSET                  ? (chk_top_vio | chk_base_vio)
               : (CSEAL | CUNSEAL)           ? (chk_top_vio | chk_base_vio | chk_top_equal)
               :                               1'b0;
```

Với capability load/store, bound được **làm tròn xuống bội số 8** — CLC/CSC chỉ truy cập
8 byte căn hàng. `chk_top_equal` bị coi là vi phạm vì cần **8 byte** từ địa chỉ đó.

Vector vi phạm quyền cho từng nhóm lệnh (`ibex_cheriot_ex.sv:815-870`):

| Lệnh | Vi phạm được kiểm |
|---|---|
| `CLC` | `TAG` (~valid), `SEAL` (sealed), `LD`, `ALIGN` (addr[2:0]≠0) |
| `CSC` | `TAG`, `SEAL`, `SD`, `SC` (~MC && cs2.valid), `ALIGN`; + `perm_vio_slc` riêng |
| `CSEAL` | `TAG` (cs2), `SEAL` (a hoặc b sealed, hoặc ~b.SE, hoặc otype sai) |
| `CUNSEAL` | `TAG` (cs2), `SEAL` (a chưa sealed, b sealed, hoặc ~b.US) |
| `CJALR` | `TAG`, `SEAL` (bảng phức tạp §4.4), `EX` |
| `CCSR_RW` | `ASR` (~pcc.SR); + `illegal_scr_addr` |

### 6.3 Mã hoá nguyên nhân

`cheriot_violation_cause()` (`ibex_cheriot_pkg.sv:937-965`), theo thứ tự ưu tiên:

| Vi phạm | Mã |
|---|---|
| `PVIO_TAG` | `0x02` |
| `PVIO_SEAL` | `0x03` |
| `PVIO_EX` | `0x11` |
| `PVIO_LD` | `0x12` |
| `PVIO_SD` | `0x13` |
| `PVIO_SC` | `0x15` |
| `PVIO_ASR` | `0x18` |
| `bound_vio` | `0x01` |
| không có | `0x00` |

`PVIO_ALIGN` **không** ánh xạ sang mã cause — nó được báo qua bit `[11]` của
`cheriot_wb_err_info` và controller dịch thành `ExcCauseLoad/StoreAddrMisaligned`.

### 6.4 `addr_bound_vio_ext` — khớp ưu tiên Sail

`ibex_cheriot_ex.sv:888-892`

```systemverilog
cheriot_top_chkaddr_ext = cheriot_ls_chkaddr + 33'd8;
addr_bound_vio_ext = is_cap ? addr_bound_vio | (cheriot_top_chkaddr_ext > fullcap_a.top33)
                            : addr_bound_vio;
```

`addr_bound_vio` (bản tối ưu timing, dùng bound làm tròn 8) được dùng để **gate `data_req`**.
`addr_bound_vio_ext` (bản đầy đủ) chỉ dùng để sinh `mcause`/`mtval` — đi qua flop nên
không ảnh hưởng timing. Cần thiết vì đặc tả Sail quy định bound violation ưu tiên hơn
alignment error.

---

## 7. Đóng gói lỗi cho WB

`ibex_cheriot_ex.sv:895-940`

```systemverilog
cheriot_wb_err_d = cheriot_wb_err_raw & cheriot_exec_id_i & cheriot_ex_valid_raw & ~debug_mode_i;

// cheriot_wb_err_info: bit[15:13] reserved, [12] illegal_scr_addr, [11] alignment,
//                      [10:0] mtval theo spec CHERIoT
if (CCSR_RW & wb_err_raw & illegal_scr_addr) info = {3'h0, 1'b1, 12'h0};
else if (CCSR_RW & wb_err_raw)               info = {5'h0, 1'b1, cs2_dec, err_cause};   // S=1
else if (wb_err_raw)                         info = {5'h0, 1'b0, rf_raddr_a_i, err_cause};
else if ((CLC|CSC) & lsu_err)   info = {4'h0, ls_addr_misaligned_only, 1'b0,
                                        rf_raddr_a_i, err_cause};
else if (rv32_lsu_req & rv32_err) info = {5'h0, 1'b0, rf_raddr_a_i, rv32_err_cause};

always_ff: {cheriot_wb_err_q, cheriot_wb_err_info_q} <= {cheriot_wb_err_d, info};
```

Định dạng `mtval` 11 bit của CHERIoT: `{S (1b), cap_idx (5b), cause (5b)}`,
với `S=1` nghĩa là "special register" (SCR) chứ không phải thanh ghi thường.

`ls_addr_misaligned_only` = chỉ có lỗi alignment, không có vi phạm nào khác và không
vượt bounds → controller sẽ báo `Load/StoreAddrMisaligned` thay vì `CheriFault`.

Vì `WritebackStage = 1` → `cheriot_wb_err_o = cheriot_wb_err_q` (đã flop 1 chu kỳ,
khớp với lệnh đang ở WB).

---

## 8. Mux LSU

`ibex_cheriot_ex.sv:943-985`

```systemverilog
lsu_req_o           = instr_is_cheriot_i ? cheriot_lsu_req : rv32_lsu_req_i;
lsu_cheriot_err_o   = instr_is_cheriot_i ? cheriot_lsu_err : rv32_lsu_err;
lsu_addr_o          = instr_is_cheriot_i ? cheriot_lsu_addr : rv32_lsu_addr_i;
lsu_we_o            = instr_is_cheriot_i ? cheriot_lsu_we   : rv32_lsu_we_i;
lsu_wdata_o         = instr_is_cheriot_i ? cheriot_lsu_wdata: rv32_lsu_wdata_i;
lsu_is_cap_o        = instr_is_cheriot_i & cheriot_lsu_is_cap;
lsu_wcap_o          = instr_is_cheriot_i ? cheriot_lsu_wcap : NULL_CAP;
lsu_type_o          = ~instr_is_cheriot_i ? rv32_lsu_type_i : 2'b00;
lsu_sign_ext_o      = ~instr_is_cheriot_i ? rv32_lsu_sign_ext_i : 1'b0;
lsu_lc_clrperm_o    = instr_is_cheriot_i ? cheriot_lsu_lc_clrperm : '0;

rv32_addr_incr_req_o = ((cheriot_enable_i != IbexMuBiOn) | instr_is_rv32lsu_i)
                       ? addr_incr_req_i : 1'b0;
rv32_addr_last_o     = addr_last_i;
```

`cheriot_lsu_req` với `WritebackStage=1`:
```systemverilog
cheriot_lsu_req = is_cap & cheriot_exec_id_i;      // giữ cao tới khi lsu_req_done
```
(Không có WB stage thì thêm `& instr_first_cycle_i`.)

`rv32_addr_incr_req_o` phải được gate: nếu không, nó đi ngược vào ALU của ID stage
(`alu_op_a_mux_sel = OP_A_FWD`) và làm hỏng các lệnh không phải load/store.

---

## 9. Stack High-Water Mark

`ibex_cheriot_ex.sv:991-995`

```systemverilog
csr_mshwm_set_o = lsu_req_o & ~lsu_cheriot_err_o & lsu_we_o
                & (lsu_addr_o[31:4] >= csr_mshwmb_i[31:4])
                & (lsu_addr_o[31:4] <  csr_mshwm_i[31:4]);
csr_mshwm_new_o = {lsu_addr_o[31:4], 4'h0};
```

Mỗi lần **ghi** vào vùng `[mshwmb, mshwm)` thì `mshwm` được hạ xuống địa chỉ đó
(granularity 16 byte). Phần mềm dùng để biết cần xoá bao nhiêu stack khi chuyển
compartment — chỉ phải zero-fill từ `mshwm` tới đỉnh stack thay vì toàn bộ.

Comment ghi rõ: kể cả nếu lệnh sau đó bị fault ở WB thì cũng vô hại — worst case là
`mshwm` "quá bi quan" và phần mềm xoá nhiều hơn cần thiết.

---

## 10. Quản lý PCC

PCC (`pcc_cap_q`) sống trong **`ibex_cs_registers`** (`ibex_cs_registers.sv:2062-2110`),
không phải trong `ibex_cheriot_ex`:

```systemverilog
always_ff: if (!rst_ni)                     pcc_cap_q <= ROOT_DECODED_CAP_TX;
           else if (cheriot_on)             pcc_cap_q <= pcc_cap_d;

always_comb begin
  if (csr_save_cause_i)                 {tr_cap, tr_addr} = {mtvec_cap,  mtvec_q};   // vào trap
  else if (csr_restore_mret_i)          {tr_cap, tr_addr} = {mepc_cap,   mepc_q};    // MRET
  else if (csr_restore_dret_i & debug)  {tr_cap, tr_addr} = {depc_cap,   depc_q};    // DRET
  else                                  {tr_cap, tr_addr} = {NULL_CAP,   32'h0};

  tf_cap = cheriot_decode_cap(tr_cap, tr_addr);

  if (csr_save_cause_i | csr_restore_mret_i | (csr_restore_dret_i & debug_mode_i))
       pcc_cap_d = tf_cap;              // trap/return: PCC = MTCC/MEPCC/DEPCC
  else if (cheriot_branch_req_i)
       pcc_cap_d = pcc_cap_i;           // CJALR: PCC = cs1 đã unseal (từ cheriot_ex)
  else pcc_cap_d = pcc_cap_q;           // giữ nguyên
end
```

**Quan trọng:** branch/jump RV32I (`beq`, `jal` ở chế độ RV32) **không** đổi PCC — chỉ đổi
PC. Do đó chúng vẫn bị giới hạn bởi bounds của PCC hiện tại, và tầng IF sẽ báo
`cheriot_bound_vio` nếu nhảy ra ngoài.

Lỗi chí mạng (`ibex_cs_registers.sv:2216-2228`):
```systemverilog
always_ff: if (cheriot_on && csr_save_cause_i && ~mtvec_cap.valid) cheriot_fatal_err_q <= 1'b1;
assign cheriot_fatal_err_o = cheriot_fatal_err_q;    // → alert_major_internal_o, cần reset ngoài
```
Nếu xảy ra exception mà `MTCC` không hợp lệ thì không có nơi nào để nhảy tới → lỗi không
khôi phục được.
