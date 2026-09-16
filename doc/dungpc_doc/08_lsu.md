# 08 — Load-Store Unit

Tệp: `ibex/rtl/ibex_load_store_unit.sv` (836 dòng).

LSU nhận yêu cầu từ `ibex_cheriot_ex` (đã mux giữa đường CHERIoT và đường RV32),
điều khiển giao thức bus D-side, và trả dữ liệu đã căn chỉnh về register file qua WB stage.

---

## 1. Giao diện

| Nhóm | Tín hiệu | Ghi chú |
|---|---|---|
| Bus | `data_req_o`, `data_gnt_i`, `data_rvalid_i`, `data_bus_err_i`, `data_pmp_err_i` | Giao thức OBI-like: req/gnt, rvalid sau |
| Bus payload | `data_addr_o` (word-aligned), `data_we_o`, `data_be_o[3:0]`, `data_wdata_o[38:0]`, `data_tag_o`, `data_rdata_i[38:0]`, `data_tag_i` | `tag` là bit capability |
| Từ EX | `lsu_req_i`, `lsu_we_i`, `lsu_type_i[1:0]`, `lsu_wdata_i`, `lsu_wcap_i`, `lsu_sign_ext_i`, `adder_result_ex_i`, `lsu_is_cap_i`, `lsu_cheriot_err_i`, `lsu_lc_clrperm_i` | |
| Tới EX/WB | `lsu_rdata_o`, `lsu_rcap_o`, `lsu_rdata_valid_o`, `lsu_req_done_o`, `lsu_resp_valid_o`, `addr_incr_req_o`, `addr_last_o` | |
| Lỗi | `load_err_o`, `store_err_o`, `load_resp_intg_err_o`, `store_resp_intg_err_o`, `lsu_err_is_cheriot_o` | |

`lsu_type_i`: `2'b00` = word, `2'b01` = half, `2'b10`/`2'b11` = byte.

---

## 2. Sinh byte-enable

`ibex_load_store_unit.sv:135-192`

```systemverilog
data_offset = (CHERIoT && lsu_is_cap_i) ? 2'b00 : data_addr[1:0];
```

Capability **luôn** căn hàng word (thực ra 8 byte) nên offset ép về 0.

### 2.1 Bảng BE cho word (`lsu_type = 00`)

| `data_offset` | Phần 1 (`!handle_misaligned_q`) | Phần 2 (`handle_misaligned_q`) |
|---|---|---|
| `00` | `1111` | `0000` (không dùng) |
| `01` | `1110` | `0001` |
| `10` | `1100` | `0011` |
| `11` | `1000` | `0111` |

### 2.2 Bảng BE cho half-word (`lsu_type = 01`)

| `data_offset` | Phần 1 | Phần 2 |
|---|---|---|
| `00` | `0011` | — |
| `01` | `0110` | — |
| `10` | `1100` | — |
| `11` | `1000` | `0001` |

### 2.3 Byte (`lsu_type = 1x`)

`0001`/`0010`/`0100`/`1000` theo `data_offset` — không bao giờ lệch hàng.

### 2.4 Capability

`data_be = 4'b1111` cho cả hai word.

---

## 3. Căn chỉnh dữ liệu ghi

`ibex_load_store_unit.sv:194-228`

```systemverilog
unique case (data_offset)                         // xoay vòng trái theo byte
  2'b00: wdata_int = lsu_wdata_i;
  2'b01: wdata_int = {lsu_wdata_i[23:0], lsu_wdata_i[31:24]};
  2'b10: wdata_int = {lsu_wdata_i[15:0], lsu_wdata_i[31:16]};
  2'b11: wdata_int = {lsu_wdata_i[ 7:0], lsu_wdata_i[31: 8]};
endcase
```

Xoay vòng (rotate) chứ không dịch — nhờ đó cùng một giá trị xoay dùng được cho **cả hai**
phần của truy cập lệch hàng.

### 3.1 Dữ liệu + tag cho CHERIoT

```systemverilog
if (CHERIoT && enabled && lsu_is_cap_i) begin
  if (lsu_we_i && (ls_fsm_cs == CTX_WAIT_GNT2))
    {data_wdata_tag, data_wdata_data} = cheriot_cap_to_mem(lsu_wcap_i);  // word CAO = metadata
  else if (lsu_we_i)
    {data_wdata_tag, data_wdata_data} = {lsu_wcap_i.valid, lsu_wdata_i}; // word THẤP = address
  else
    {data_wdata_tag, data_wdata_data} = {1'b1, lsu_wdata_i};             // cap LOAD: tag=1 báo hiệu
end else
  {data_wdata_tag, data_wdata_data} = {1'b0, wdata_int};
```

Ba điểm:
1. `CSC` ghi **2 word**: word thấp = địa chỉ (32 bit), word cao = metadata nén 33 bit.
   Cả hai đều phát `tag` = `lsu_wcap_i.valid` / bit 32 của metadata.
2. `CLC` (không ghi) vẫn phát `data_tag_o = 1` — đây là **tín hiệu cho bộ nhớ/TRVK** rằng
   đây là truy cập capability, cần trả về tag bit.
3. Ở chế độ RV32, `data_tag_o` luôn 0 → mọi ghi thường sẽ **xoá tag** của ô nhớ (đúng
   ngữ nghĩa CHERI: ghi dữ liệu thường lên capability làm nó mất tính hợp lệ).

---

## 4. Căn chỉnh dữ liệu đọc

### 4.1 Thanh ghi đệm

`ibex_load_store_unit.sv:230-267`

```systemverilog
always_ff: if (rdata_update) rdata_q <= data_rdata_i[31:8];    // 24 bit (đủ cho ghép lệch hàng)

always_ff: if (ctrl_update) begin
  rdata_offset_q  <= data_offset;
  data_type_q     <= lsu_type_i;
  data_sign_ext_q <= lsu_sign_ext_i;
  data_we_q       <= lsu_we_i;
end

addr_last_d = addr_incr_req_o ? data_addr_w_aligned : data_addr;
always_ff: if (addr_update) addr_last_q <= addr_last_d;
```

`addr_last_q` phục vụ 3 mục đích: (1) `mtval` khi có lỗi, (2) AGU cho phần 2 của truy cập
lệch hàng (đi ngược lên ID stage qua `OP_A_FWD`), (3) `crash_dump_o.last_data_addr`.

Được cập nhật có chọn lọc để giữ **địa chỉ lỗi đầu tiên**:
`addr_update = data_gnt_i & ~(data_bus_err_i | pmp_err_q)` ở `WAIT_RVALID_MIS`.

### 4.2 Ghép word lệch hàng

```systemverilog
unique case (rdata_offset_q)
  2'b00: rdata_w_ext =  data_rdata_i[31:0];
  2'b01: rdata_w_ext = {data_rdata_i[ 7:0], rdata_q[31:8]};
  2'b10: rdata_w_ext = {data_rdata_i[15:0], rdata_q[31:16]};
  2'b11: rdata_w_ext = {data_rdata_i[23:0], rdata_q[31:24]};
endcase
```

`rdata_q` chứa word **đầu tiên** (phần cao), `data_rdata_i` là word **thứ hai** (phần thấp).

### 4.3 Mở rộng dấu

Half-word (`ibex_load_store_unit.sv:283-322`) và byte (`:322-365`): mỗi trường hợp có
4 nhánh theo `rdata_offset_q`, mỗi nhánh 2 nhánh con theo `data_sign_ext_q`.
Trường hợp `rdata_offset_q = 2'b11` với half-word cũng dùng `rdata_q[31:24]`
(lệch hàng qua ranh giới word).

```systemverilog
unique case (data_type_q)
  2'b00:       data_rdata_ext = rdata_w_ext;
  2'b01:       data_rdata_ext = rdata_h_ext;
  2'b10,2'b11: data_rdata_ext = rdata_b_ext;
endcase
```

---

## 5. FSM chính (`ls_fsm_e`, 8 trạng thái)

`ibex_pkg.sv:816-820`, logic ở `ibex_load_store_unit.sv:399-608`.

```
                              ┌────────────────────────────────────────┐
                              │                  IDLE                  │
                              └──┬────────┬─────────┬──────────┬───────┘
              cheriot_err (1 cyc)│        │         │          │
              ◄──────────────────┘        │         │          │
                                          │         │          │
   cap access & gnt ──────────────────────┘         │          │ normal & gnt & !misaligned
                    ▼                               │          ▼
            ┌───────────────┐                       │        IDLE
            │ CTX_WAIT_GNT2 │◄──┐                   │
            └───┬───────┬───┘   │ cap & !gnt        │ normal & !gnt
                │gnt&   │gnt    │                   │
                │rvalid │       │           ┌───────▼────────┐
                ▼       ▼   ┌───┴───────┐   │   WAIT_GNT     │ (misaligned=0)
              IDLE  CTX_WAIT│CTX_WAIT_  │   └───┬────────────┘
                     _RESP  │  GNT1     │       │ gnt | pmp_err
                        │   └───────────┘       ▼
                        │ rvalid                IDLE
                        ▼
                      IDLE

    normal & gnt & misaligned ──► WAIT_RVALID_MIS ──┬─ rvalid & gnt ──► IDLE
    normal & !gnt & misaligned ─► WAIT_GNT_MIS ─────┤
                                   │ gnt|pmp_err    ├─ rvalid & !gnt ─► WAIT_GNT
                                   └──► WAIT_RVALID_MIS
                                                    └─ !rvalid & gnt ─► WAIT_RVALID_MIS_GNTS_DONE
                                                                            │ rvalid
                                                                            ▼ IDLE
```

### 5.1 Phân loại yêu cầu

```systemverilog
split_misaligned_access = ((lsu_type_i == 2'b00) && (data_offset != 2'b00))    // word lệch
                        || ((lsu_type_i == 2'b01) && (data_offset == 2'b11));  // half qua ranh giới

cpu_req_valid = lsu_req_i & ~(cheriot_on & lsu_cheriot_err_i);
cpu_req_erred = lsu_req_i &  (cheriot_on & lsu_cheriot_err_i);
```

### 5.2 `IDLE` — 3 nhánh

**Nhánh 1 — lỗi CHERIoT (không phát request)**
```systemverilog
data_req_o = 0;  cheriot_err_d = 1;  ctrl_update = 1;  addr_update = 1;
lsu_go = 1;      ls_fsm_ns = IDLE;
```
Truy cập bị capability chặn: **không** đụng tới bus, nhưng vẫn "hoàn thành" ngay trong
1 chu kỳ và báo lỗi lên WB. Đây là lý do `lsu_req_done` phải bao gồm cả trường hợp này.

**Nhánh 2 — truy cập capability (CLC/CSC)**
```systemverilog
data_req_o = 1;  lsu_go = 1;  lsu_go_goodcap = 1;
ls_fsm_ns = data_gnt_i ? CTX_WAIT_GNT2 : CTX_WAIT_GNT1;
```

**Nhánh 3 — truy cập thường**
```systemverilog
data_req_o = 1;  lsu_go = 1;  pmp_err_d = data_pmp_err_i;
if (data_gnt_i) ls_fsm_ns = split_misaligned_access ? WAIT_RVALID_MIS : IDLE;
else            ls_fsm_ns = split_misaligned_access ? WAIT_GNT_MIS    : WAIT_GNT;
```

### 5.3 Đường lệch hàng

**`WAIT_GNT_MIS`** — chờ grant cho phần 1.
```systemverilog
data_req_o = 1;
if (data_gnt_i || pmp_err_q) { addr_update=1; ctrl_update=1; handle_misaligned_d=1;
                               ls_fsm_ns = WAIT_RVALID_MIS; }
```
`pmp_err_q` cũng thoát được — vì `data_req_o` đã bị chặn bởi `~pmp_req_err[PMP_D]` ở
`ibex_core.sv:1063` nên sẽ không bao giờ có grant.

**`WAIT_RVALID_MIS`** — phát phần 2, chờ rvalid phần 1.
```systemverilog
data_req_o      = 1;
addr_incr_req_o = 1;                        // báo ID stage tính addr_last + 4

if (data_rvalid_i || pmp_err_q) begin
  pmp_err_d           = data_pmp_err_i;             // PMP cho phần 2
  lsu_err_d           = data_bus_err_i | pmp_err_q; // ghi nhớ lỗi phần 1
  rdata_update        = ~data_we_q;                 // đệm dữ liệu phần 1
  ls_fsm_ns           = data_gnt_i ? IDLE : WAIT_GNT;
  addr_update         = data_gnt_i & ~(data_bus_err_i | pmp_err_q);
  handle_misaligned_d = ~data_gnt_i;
end else if (data_gnt_i) begin
  ls_fsm_ns = WAIT_RVALID_MIS_GNTS_DONE;    // grant phần 2 tới TRƯỚC rvalid phần 1
  handle_misaligned_d = 1'b0;
end
```

**`WAIT_RVALID_MIS_GNTS_DONE`** — cả hai grant xong, chờ rvalid phần 1.
```systemverilog
addr_incr_req_o = 1;
if (data_rvalid_i) begin
  pmp_err_d    = data_pmp_err_i;
  lsu_err_d    = data_bus_err_i;         // phần 1 không thể có PMP error ở đây
  addr_update  = ~data_bus_err_i;
  rdata_update = ~data_we_q;
  ls_fsm_ns    = IDLE;                   // rồi chờ rvalid phần 2 ở IDLE
end
```

**`WAIT_GNT`** — chờ grant (phần 1 aligned, hoặc phần 2 của lệch hàng).
```systemverilog
addr_incr_req_o = handle_misaligned_q;
data_req_o      = 1;
if (data_gnt_i || pmp_err_q) { ctrl_update=1; addr_update=~lsu_err_q; ls_fsm_ns=IDLE;
                               handle_misaligned_d=0; }
```

### 5.4 Đường capability (CLC/CSC)

**`CTX_WAIT_GNT1`** — chờ grant word 1.
```systemverilog
addr_incr_req_o = 0;  data_req_o = 1;
if (data_gnt_i) { ls_fsm_ns = CTX_WAIT_GNT2; ctrl_update = 1; addr_update = 1; }
```

**`CTX_WAIT_GNT2`** — phát word 2 (`addr + 4`).
```systemverilog
addr_incr_req_o = 1;  data_req_o = 1;
if (data_gnt_i && (data_rvalid_i || (cap_rx_fsm_q == CRX_WAIT_RESP2))) ls_fsm_ns = IDLE;
else if (data_gnt_i)                                                   ls_fsm_ns = CTX_WAIT_RESP;
```

**`CTX_WAIT_RESP`** — chỉ cần nếu bộ nhớ cho phép 2 request outstanding.
```systemverilog
addr_incr_req_o = 1;  data_req_o = 0;
if (data_rvalid_i) ls_fsm_ns = IDLE;
```

Với `cheriot_enable_i != IbexMuBiOn`, cả ba trạng thái này đều `ls_fsm_ns = IDLE`
(thoát an toàn).

### 5.5 FSM phụ nhận capability

`ibex_load_store_unit.sv:611-628`

```
CRX_IDLE ──(lsu_go_goodcap)──► CRX_WAIT_RESP1 ──(rvalid)──► CRX_WAIT_RESP2
    ▲                                                            │
    └──────────(rvalid & !lsu_go_goodcap)────────────────────────┘
                                                                 │
              (rvalid & lsu_go_goodcap) ─► CRX_WAIT_RESP1 ◄──────┘  (back-to-back cap)
```

FSM này **theo dõi phía phản hồi**, độc lập với FSM request. Cần thiết vì word 1 và word 2
của capability về ở hai chu kỳ khác nhau, và giữa chúng FSM chính có thể đã về `IDLE`.

Ở `CRX_WAIT_RESP1` + `rvalid`:
```systemverilog
if (~data_we_q) { cap_lsw_data_q <= data_rdata_i[31:0];  cap_lsw_tag_q <= data_tag_i; }
cap_lsw_err_q <= data_bus_err_i;
```
→ Word thấp (địa chỉ) được lưu; word cao (metadata) đến sau sẽ được ghép.

---

## 6. Chốt thông tin phản hồi

`ibex_load_store_unit.sv:660-670`

```systemverilog
if (lsu_go) begin
  resp_is_cap_q     <= lsu_is_cap_i;
  resp_lc_clrperm_q <= lsu_lc_clrperm_i;
end
```

Comment giải thích rõ: `resp_is_cap_q` khớp với **phản hồi**, còn `lsu_is_cap_i` khớp với
**yêu cầu**. Chỉ hợp lệ vì LSU chỉ có **một lệnh** outstanding tại một thời điểm
(request mới không được phát tới khi `lsu_resp_valid`, và `lsu_resp_valid` bị gate bởi
`ls_fsm_cs == IDLE`).

---

## 7. Đầu ra

`ibex_load_store_unit.sv:684-800`

```systemverilog
data_or_pmp_err = lsu_err_q | data_bus_err_i | pmp_err_q |
                  (cheriot_on & (cheriot_err_q | (resp_is_cap_q & cap_lsw_err_q)));

all_resp         = data_rvalid_i | pmp_err_q | (cheriot_on & cheriot_err_q);
lsu_resp_valid_o = all_resp & (ls_fsm_cs == IDLE);

lsu_rdata_valid_o = (ls_fsm_cs == IDLE) & data_rvalid_i & ~data_or_pmp_err
                  & ~data_we_q & ~data_intg_err;

lsu_req_done      = (lsu_go | (ls_fsm_cs != IDLE)) & (ls_fsm_ns == IDLE);

load_err_o  = data_or_pmp_err & ~data_we_q & lsu_resp_valid_o;
store_err_o = data_or_pmp_err &  data_we_q & lsu_resp_valid_o;

load_resp_intg_err_o  = data_intg_err & data_rvalid_i & ~data_we_q;
store_resp_intg_err_o = data_intg_err & data_rvalid_i &  data_we_q;

lsu_err_is_cheriot_o  = cheriot_on & cheriot_err_q;

busy_o = (ls_fsm_cs != IDLE);
```

### 7.1 Vì sao lỗi ECC tách riêng?

Comment (`ibex_load_store_unit.sv:750-760`):

> `load_err_o` được đưa **trực tiếp** vào `data_req_o` (qua `instr_executing`) để
> exception đồng bộ trên lỗi load không mất hiệu năng. `data_intg_err` là **tổ hợp
> trực tiếp** từ `data_rdata_i`; nếu đưa nó vào `load_err_o` thì sẽ có đường
> feedthrough `data_rdata_i → data_req_o` — điều không mong muốn.

Vì vậy lỗi ECC được xử lý qua **NMI nội bộ** (`ibex_controller.sv:393-452`) chứ không
qua exception đồng bộ.

### 7.2 Ghép capability đọc về

```systemverilog
lsu_rdata_o = (cheriot_on & resp_is_cap_q) ? cap_lsw_data_q : data_rdata_ext;

lsu_rcap_o  = (cheriot_on && resp_is_cap_q && data_rvalid_i &&
               (cap_rx_fsm_q == CRX_WAIT_RESP2) && ~data_or_pmp_err)
            ? cheriot_mem_to_cap({data_tag_i, data_rdata_i[31:0]},    // word CAO = metadata
                                 {cap_lsw_tag_q, cap_lsw_data_q},     // word THẤP = address
                                 resp_lc_clrperm_q)
            : NULL_CAP;
```

`cheriot_mem_to_cap()` (`ibex_cheriot_pkg.sv:763-795`):
```systemverilog
valid_in   = cap_mw[32] & addr33[32];             // CẢ HAI word phải có tag
cap.valid  = valid_in & ~clrperm.CTAG;
cap.base   = cap_mw[8:0];   cap.top = cap_mw[17:9];
cap.cexp   = cap_mw[21:18]; cap.otype = cap_mw[24:22];
cap.cperms = cheriot_mask_loaded_cperms(cap_mw[30:25], clrperm, cap.valid, sealed);
cap.cap_cor= compute_corrections(cap.top, cap.base, 9'(addr33[31:0] >> exp5));
cap.rsvd   = cap_mw[31];
```

Tag hợp lệ đòi hỏi **cả hai** word đều có tag = 1. Đây là cơ chế chống "ghép nửa capability".

### 7.3 Quy tắc xoá quyền khi load (`cheriot_mask_loaded_cperms`)

`ibex_cheriot_pkg.sv:284-338`

```systemverilog
clr_gl   = clrperm.GL_LG & valid_in;                  // thiếu LG → xoá GL
clr_lg   = clrperm.GL_LG & valid_in & ~sealed;        // thiếu LG → xoá LG (nếu chưa sealed)
clr_sdlm = clrperm.SD_LM & valid_in & ~sealed;        // thiếu LM → xoá SD, LM

cperms_out[5] = cperms_in[5] & ~clr_gl;               // GL

// Với format memory cap-read-write (cperms[4:3]==2'b11):
cperms_out[0]   = cperms_in[0] & ~clr_lg;             // LG
cperms_out[1]   = cperms_in[1] & ~clr_sdlm;           // LM
cperms_out[4:2] = clr_sdlm ? 3'b101 : cperms_in[4:2]; // RW → RO (vì mất SD)
```

Đây là "capability monotonicity": capability load qua một capability yếu hơn thì cũng
yếu đi. Capability đã sealed được **miễn** xoá LG/SD/LM (chỉ bị xoá GL).

---

## 8. Kiểm tra ECC D-side

`ibex_load_store_unit.sv:376-398` (đọc) và `:781-790` (ghi)

```systemverilog
// Đọc
prim_buf #(.Width(39)) u_prim_buf_instr_rdata (.in_i(data_rdata_i), .out_o(data_rdata_buf));
prim_secded_inv_39_32_dec u_data_intg_dec (.data_i(data_rdata_buf), .err_o(ecc_err));
data_intg_err = |ecc_err;

// Ghi
prim_secded_inv_39_32_enc u_data_gen (.data_i(data_wdata_data), .data_o(data_wdata_o));
assign data_tag_o = data_wdata_tag;
```

Lưu ý: `data_wdata_o` rộng 39 bit đi ra `ibex_core`, sau đó `ibex_top` tách thành
`trvk_wdata[31:0]` + `trvk_wdata_intg[6:0]`.

**Với `SecureIbex = 1`**, ECC được kiểm tra trên **cả write response** — khi đó
`data_rdata_i` không mang dữ liệu có nghĩa nhưng `data_rdata_intg_i` vẫn phải hợp lệ
(assertion `IbexDataRPayloadX` ở `ibex_top.sv:1494-1504`).

---

## 9. Bảo vệ phản hồi giả (spurious response)

`ibex_core.sv:1181-1195` — nằm ngoài LSU:

```systemverilog
if (SecureIbex) begin : g_check_mem_response
  lsu_load_err  = lsu_load_err_raw  & (outstanding_load_wb  | expecting_load_resp_id);
  lsu_store_err = lsu_store_err_raw & (outstanding_store_wb | expecting_store_resp_id);
  rf_we_lsu     = lsu_rdata_valid   & (outstanding_load_wb  | expecting_load_resp_id);
end
```

Với `WritebackStage = 1`, `expecting_load/store_resp_id` luôn 0
(`ibex_id_stage.sv:1140-1141`) — vì khi có WB stage thì mọi phản hồi được xử lý ở WB.
Nên điều kiện rút gọn thành `outstanding_load_wb` / `outstanding_store_wb`.

Ý nghĩa: nếu kẻ tấn công glitch `data_rvalid_i` khi không có giao dịch nào đang chờ,
register file **không** bị ghi và exception **không** bị kích hoạt.

---

## 10. Độ trễ LSU

| Trường hợp | Chu kỳ tối thiểu | Ghi chú |
|---|---|---|
| Load/Store căn hàng, grant ngay, rvalid ngay | 2 | 1 request + 1 response |
| Load/Store căn hàng, grant sau N | 2+N | |
| Load/Store lệch hàng | 3+ | 2 request, 2 response |
| `CLC`/`CSC` | 3+ | 2 request liên tiếp, 2 response |
| Lỗi CHERIoT (bound/perm) | **1** | Không đụng bus, báo lỗi ngay |
| Lỗi PMP | 1–2 | `data_req_o` bị chặn, FSM dùng `pmp_err_q` để thoát |

---

## 11. Assertion quan trọng

| Assertion | Nội dung |
|---|---|
| `IbexLsuStateValid` | `ls_fsm_cs` luôn trong 8 trạng thái hợp lệ |
| `IbexDataAddrUnaligned` | `data_req_o \|-> data_addr_o[1:0] == 2'b00` |
| `IbexDataAddrUnknown` | Không có X trên `data_addr_o` khi `data_req_o` |
| `IbexDataTypeKnown` / `IbexDataOffsetKnown` | Không có X khi đang hoạt động |
| `IbexLsuIsCapDisabled` | `cheriot_enable != On \|-> !lsu_is_cap_i` |
| `IbexLsuCheriotErrDisabled` | `cheriot_enable != On \|-> !lsu_cheriot_err_i` |

Và ở `ibex_core.sv:1380-1395`:
* `NoMemRFWriteWithoutPendingLoad`: `rf_we_lsu |-> outstanding_load_wb`
* `NoMemResponseWithoutPendingAccess`: `data_rvalid_i |-> outstanding_load_resp | outstanding_store_resp`
