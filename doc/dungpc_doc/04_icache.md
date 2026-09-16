# 04 — Instruction Cache

Tệp: `ibex/rtl/ibex_icache.sv` (1338 dòng). **[BẬT]** vì `ICache = 1`.

## 0. Thông số tổng hợp

| Thuộc tính | Giá trị |
|---|---|
| Dung lượng | 4 KiB |
| Số way | 2 (associative) |
| Kích thước line | 8 byte (64 bit) = **2 beat** bus 32-bit |
| Số line / way | 256 |
| Index | `addr[10:3]` (8 bit) |
| Tag | `addr[31:11]` (21 bit) + 1 bit valid = 22 bit |
| Offset trong line | `addr[2]` chọn beat, `addr[1]` chọn nửa-từ |
| Chính sách thay thế | Way invalid thấp nhất, nếu không có → round-robin toàn cục |
| Chính sách ghi | Read-only cache (chỉ fill) |
| Fill buffer | **4** (`NUM_FB`), arbitration theo tuổi |
| Throttle | Khi `fb_fill_level > 2` thì ngừng lookup mới (trừ branch) |
| ECC | SECDED `(28,22)` tag, `(39,32)` mỗi beat data |
| Scramble | PRINCE 2 half-round + 2 vòng address scramble |
| Tweak infection | XOR địa chỉ vào data & tag trước khi ghi RAM |

---

## 1. Kiến trúc tổng thể

```
                                     ┌────── prefetch_addr_q ──────┐
                                     │  (+8 mỗi lookup được grant) │
  branch_i / addr_i ────────┬────────┴─────────────┐               │
                            │                      ▼               │
                            │        ┌──────── lookup_addr_ic0 ────┘
                            │        │
  ┌─────────────────────────▼────────▼─────────────────────────────────────┐
  │                      PIPELINE STAGE IC0                                │
  │  Arbitration: lookup > fill > inval > ecc_write                        │
  │  ┌──────────┐  ┌──────────┐  ┌─────────────┐  ┌──────────────┐        │
  │  │ lookup   │  │  fill    │  │ inval_write │  │ ecc_write    │        │
  │  │ _req_ic0 │  │ _req_ic0 │  │   _req      │  │   _req       │        │
  │  └────┬─────┘  └────┬─────┘  └──────┬──────┘  └──────┬───────┘        │
  │       └─────────────┴───────────────┴────────────────┘                │
  │                     │ tag_req/index/banks/write/wdata                  │
  │                     │ data_req/index/banks/write/wdata                 │
  │              ECC encode (28,22) & (39,32)  +  tweak XOR                │
  └─────────────────────┬──────────────────────────────────────────────────┘
                        ▼  ic_tag_* / ic_data_*  (ra prim_ram_1p_scr ở ibex_top)
  ┌──────────────────────────────────────────────────────────────────────┐
  │                      PIPELINE STAGE IC1                              │
  │  tag_rdata_ic1 = ic_tag_rdata_i ^ tag_tweak_lw_ic1     (un-tweak)    │
  │  tag_match_ic1[way] = (tag == {1'b1, lookup_addr_ic1})                │
  │  tag_hit_ic1 = |tag_match_ic1                                         │
  │  hit_data_ecc_ic1 = OR( ic_data_rdata_i[way] ^ data_tweak ) if match  │
  │  ECC decode → ecc_err_ic1 → ecc_error_o (alert_minor) + invalidate    │
  │  sel_way_ic1 = |tag_invalid ? lowest_invalid : round_robin_way_q      │
  └──────────────────────────────┬───────────────────────────────────────┘
                                 │ fill_hit_ic1[fb], hit_data_ic1
  ┌──────────────────────────────▼───────────────────────────────────────┐
  │                 4 × FILL BUFFER (mỗi buffer = 1 line)                │
  │  fill_busy_q  fill_older_q  fill_stale_q  fill_cache_q  fill_hit_q   │
  │  fill_ext_cnt_q  fill_rvd_cnt_q  fill_out_cnt_q  fill_ram_done_q     │
  │  fill_addr_q[32]  fill_way_q[2]  fill_data_q[64]  fill_err_q[2]      │
  └──────┬──────────────────┬─────────────────────┬──────────────────────┘
         │ fill_ext_arb     │ fill_ram_arb        │ fill_out_arb
         ▼                  ▼                     ▼
   instr_req_o        (ghi lại vào IC0)      output mux
   instr_addr_o                                   │
                                        ┌─────────▼─────────┐
                                        │  SKID BUFFER 16b  │
                                        │  + address counter│
                                        └─────────┬─────────┘
                                                  ▼
                                    valid_o / rdata_o / addr_o / err_o
```

---

## 2. Bộ đếm prefetch

`ibex_icache.sv:208-240`

```systemverilog
lookup_addr_aligned = {lookup_addr_ic0[31:3], 3'b000};

prefetch_addr_d  = lookup_grant_ic0 ? (lookup_addr_aligned + 8) : addr_i;
prefetch_addr_en = branch_i | lookup_grant_ic0;
```

Mỗi lookup được chấp nhận → cộng thêm **một line** (8 byte). Khi có branch mà lookup
chưa được grant, địa chỉ nhánh vẫn được chốt (vì `addr_i` chỉ hợp lệ 1 chu kỳ khi
`branch_i` cao).

Lưu ý: `prefetch_addr_q` **không** ép align xuống ranh giới line — offset trong line
được giữ lại để fill buffer biết beat nào cần trước.

---

## 3. Tầng IC0

`ibex_icache.sv:243-284`

### 3.1 Điều kiện phát lookup

```systemverilog
lookup_throttle  = (fb_fill_level > 2);                      // FB_THRESHOLD = NUM_FB-2
lookup_req_ic0   = req_i & ~&fill_busy_q & (branch_i | ~lookup_throttle) & ~ecc_write_req;
lookup_addr_ic0  = branch_i ? addr_i : prefetch_addr_q;
lookup_index_ic0 = lookup_addr_ic0[10:3];
```

* `~&fill_busy_q` — phải còn ít nhất 1 fill buffer trống.
* `lookup_throttle` — khi ≥3 buffer đang hoạt động (không stale) thì ngừng prefetch
  suy đoán; **branch vẫn được ưu tiên** vì đó là fetch thật cần ngay.
* `~ecc_write_req` — chu kỳ sửa ECC chiếm dụng port RAM.

### 3.2 Trọng tài port RAM

```systemverilog
lookup_grant_ic0  = lookup_req_ic0;                                    // ưu tiên CAO NHẤT
fill_grant_ic0    = fill_req_ic0 & ~lookup_req_ic0 & ~inval_write_req & ~ecc_write_req;
lookup_actual_ic0 = lookup_grant_ic0 & icache_enable_i & ~inval_block_cache;
```

Thứ tự ưu tiên: **lookup > fill > invalidate > ecc_write**? Không hẳn — đọc kỹ:

```systemverilog
tag_req_ic0   = lookup_req_ic0 | fill_req_ic0 | inval_write_req | ecc_write_req;
tag_index_ic0 = inval_write_req ? inval_index_q   :     // ưu tiên 1
                ecc_write_req   ? ecc_write_index :     // ưu tiên 2
                fill_grant_ic0  ? fill_index_ic0  :     // ưu tiên 3
                                  lookup_index_ic0;     // ưu tiên 4
tag_write_ic0 = fill_grant_ic0 | inval_write_req | ecc_write_req;
```

Trên **địa chỉ/ghi**, thứ tự thật là `inval > ecc_write > fill > lookup`.
Nhưng `lookup_req_ic0` đã bị chặn bởi `~ecc_write_req`, và `inval_block_cache` đã
chặn `lookup_actual_ic0`. `fill_grant_ic0` bị chặn bởi cả ba. Kết quả nhất quán.

Data RAM dùng **cùng** index/banks/write với tag RAM:
```systemverilog
data_req_ic0 = lookup_req_ic0 | fill_req_ic0;
data_index_ic0 = tag_index_ic0;  data_banks_ic0 = tag_banks_ic0;  data_write_ic0 = tag_write_ic0;
```

### 3.3 Dữ liệu tag ghi

```systemverilog
fill_tag_ic0 = {(~inval_write_req & ~ecc_write_req),        // bit valid
                fill_ram_req_addr[31:11]};                   // 21 bit tag
```

→ Khi invalidate hoặc sửa ECC, bit valid = 0 (và tag = 0 vì `fill_ram_req_addr` khi đó là 0).

### 3.4 Sinh ECC

`ibex_icache.sv:286-315` — **[BẬT]** (SEC_CM: `ICACHE.MEM.INTEGRITY`)

```systemverilog
// Tag: dùng lại primitive (28,22) bằng cách zero-pad
tag_ecc_input_padded = {{22-22{1'b0}}, fill_tag_ic0};       // = fill_tag_ic0 (đúng 22 bit)
prim_secded_inv_28_22_enc tag_ecc_enc (...);
tag_wdata_ic0 = {tag_ecc_output_padded[27:22], tag_ecc_output_padded[21:0]};

// Data: mỗi beat 32-bit riêng
for (bank = 0; bank < 2; bank++)
  prim_secded_inv_39_32_enc data_ecc_enc (.data_i(fill_wdata_ic0[bank*32 +: 32]),
                                          .data_o(data_wdata_ic0[bank*39 +: 39]));
```

Với `IC_TAG_SIZE = 22` thì phần pad bằng 0 bit — primitive được dùng vừa khít.
`ASSERT_INIT(ecc_tag_param_legal, IC_TAG_SIZE <= 27)`.

---

## 4. Tweak Infection (SEC_CM: `ICACHE.MEM.ADDR_INFECTION`)

`ibex_icache.sv:318-440` — **[BẬT]** vì `ICacheTweakInfection = SecureIbex = 1`.

### 4.1 Mục đích

Ngăn kẻ tấn công **hoán đổi dòng cache** (address swap / row-hammer trên SRAM):
nếu dữ liệu bị đọc từ địa chỉ RAM sai thì tweak un-XOR sẽ không khớp → ECC báo lỗi.

### 4.2 Data RAM

```systemverilog
data_address_ic0 = inval_write_req ? '0 :          // không tweak khi invalidate
                   ecc_write_req   ? '0 :          // không tweak khi đang sửa lỗi
                   fill_grant_ic0  ? fill_ram_req_addr :
                                     lookup_addr_ic0;
data_tweak_ic0   = data_address_ic0[31:3];          // bỏ offset trong line

// Trải rộng tweak 29-bit thành vector 78-bit (2 beat × 39 bit)
for (i = 0; i < 2; i++)
  data_tweak_lw_ic0 |= (78'({data_tweak_ic0, 3'b000}) << (i * (32 + 7)));

ic_data_wdata_o  = data_wdata_ic0 ^ data_tweak_lw_ic0;       // XOR khi GHI
```

Phía đọc, tweak được **pipeline sang IC1** bằng một flop riêng (enable `data_req_ic0`):

```systemverilog
always_ff: if (data_req_ic0) data_tweak_ic1 <= data_tweak_ic0;
hit_data_ecc_ic1 |= ic_data_rdata_i[way] ^ data_tweak_lw_ic1;    // un-XOR khi ĐỌC
```

### 4.3 Tag RAM

Tweak của tag dùng **index** thay vì địa chỉ đầy đủ (vì tag chính là phần địa chỉ cao):

```systemverilog
tag_tweak_lw_ic0 |= (28'(tag_index_ic0) << (i * (8 + 6)));    // IC_INDEX_W + IC_TAG_ECC_SIZE
ic_tag_wdata_o    = tag_wdata_ic0 ^ tag_tweak_lw_ic0;
tag_rdata_ic1[way]= ic_tag_rdata_i[way] ^ tag_tweak_lw_ic1;
always_ff: if (tag_req_ic0) tag_index_ic1 <= tag_index_ic0;
```

> **Chi tiết tinh tế:** khi `inval_write_req` hoặc `ecc_write_req`, tweak **data** bị ép 0
> nhưng tweak **tag** thì không (vẫn dùng `tag_index_ic0` = `inval_index_q`). Điều này nhất
> quán vì đọc lại cũng dùng `tag_index_ic1` tương ứng.

---

## 5. Tầng IC1

`ibex_icache.sv:494-655`

### 5.1 So khớp tag

```systemverilog
tag_match_ic1[way]   = (tag_rdata_ic1[way][21:0] == {1'b1, lookup_addr_ic1[31:11]});
tag_invalid_ic1[way] = ~tag_rdata_ic1[way][21];
tag_hit_ic1          = |tag_match_ic1;
```

`lookup_addr_ic1` được flop khi `lookup_grant_ic0` (`ibex_icache.sv:466-490`).
`lookup_valid_ic1` được flop từ `lookup_actual_ic0` **vô điều kiện** mỗi chu kỳ.

### 5.2 Mux dữ liệu hit

```systemverilog
always_comb begin
  hit_data_ecc_ic1 = '0;
  for (way = 0; way < 2; way++)
    if (tag_match_ic1[way]) hit_data_ecc_ic1 |= ic_data_rdata_i[way] ^ data_tweak_lw_ic1;
end
```

OR-mux one-hot (không phải mux nhị phân) → nếu cả hai way cùng "hit" (do lỗi ECC tag
làm hit giả) thì dữ liệu bị trộn — được xử lý ở §5.4.

### 5.3 Chọn way thay thế

```systemverilog
lowest_invalid_way_ic1[0]   = tag_invalid_ic1[0];
lowest_invalid_way_ic1[w]   = tag_invalid_ic1[w] & ~|tag_invalid_ic1[w-1:0];

round_robin_way_ic1[0]      = round_robin_way_q[1];      // xoay vòng 2 bit
round_robin_way_ic1[1]      = round_robin_way_q[0];
always_ff: if (lookup_valid_ic1) round_robin_way_q <= round_robin_way_ic1;

sel_way_ic1 = |tag_invalid_ic1 ? lowest_invalid_way_ic1 : round_robin_way_q;
```

Reset `round_robin_way_q = 2'b01`. Xoay **mỗi lookup hợp lệ**, không chỉ khi miss →
gọi là "pseudorandom" trong comment.

### 5.4 Kiểm tra & sửa ECC

`ibex_icache.sv:538-650`

```systemverilog
// Tag ECC cho CẢ HAI way (không điều kiện hit)
for (way) prim_secded_inv_28_22_dec(...) → tag_err_ic1[way]

// Data ECC chỉ trên dữ liệu đã mux (way hit)
for (bank = 0..1) prim_secded_inv_39_32_dec(hit_data_ecc_ic1[bank*39 +: 39]) → data_err_ic1

ecc_err_ic1 = lookup_valid_ic1 & (((|data_err_ic1) & tag_hit_ic1) | (|tag_err_ic1));
```

**Lý do bất đối xứng:** tag RAM được khởi tạo toàn bộ lúc reset (FSM invalidate ghi
tag invalid có ECC đúng) nên ECC tag **luôn** phải đúng. Data RAM **không** được khởi tạo
→ dữ liệu ở way chưa từng fill có ECC rác, nên chỉ kiểm khi tag hợp lệ và hit.

Cơ chế sửa lỗi = **invalidate**:

```systemverilog
ecc_correction_ways_d  = {2{|tag_err_ic1}} |                      // lỗi tag → xoá CẢ HAI way
                         (tag_match_ic1 & {2{|data_err_ic1}});    // lỗi data → xoá way hit
ecc_correction_write_d = ecc_err_ic1;

always_ff: ecc_correction_write_q <= ecc_correction_write_d;      // trễ 1 chu kỳ
always_ff: if (ecc_err_ic1) {ecc_correction_ways_q, ecc_correction_index_q}
                            <= {ecc_correction_ways_d, lookup_index_ic1};

ecc_write_req = ecc_correction_write_q;   // chiếm port RAM ở IC0 chu kỳ sau
ecc_error_o   = ecc_err_ic1;              // → alert_minor_o
```

Xoá **cả hai way** khi lỗi tag để: (a) tránh X-propagation từ `data_err_ic1` trên hit giả,
(b) tránh cùng một line được cấp phát 2 lần (hit thật + hit giả).

Dữ liệu bị lỗi ECC **không** được trả về IF: `fill_hit_ic1[fb]` có điều kiện `~ecc_err_ic1`
→ fill buffer sẽ đi đường external request thay vì dùng dữ liệu cache.

---

## 6. Fill buffer (4 bộ)

`ibex_icache.sv:682-990`. Mỗi fill buffer theo dõi **một line** đang được lấy về.

### 6.1 Cấp phát

```systemverilog
fill_alloc_sel[0] = ~fill_busy_q[0];
fill_alloc_sel[i] = ~fill_busy_q[i] & (&fill_busy_q[i-1:0]);    // chọn buffer thấp nhất rỗi
fill_alloc[i]     = fill_alloc_sel[i] & lookup_grant_ic0;       // mỗi lookup cấp 1 buffer
fill_busy_d[i]    = fill_alloc[i] | (fill_busy_q[i] & ~fill_done[i]);
```

Ma trận tuổi `fill_older_d[i] = (fill_alloc[i] ? fill_busy_q : fill_older_q[i]) & ~fill_done`
— khi cấp phát, ghi lại bitmask "những buffer nào đang bận (tức già hơn tôi)".

### 6.2 Bốn bộ đếm mỗi buffer

| Bộ đếm | Rộng | Ý nghĩa |
|---|---|---|
| `fill_ext_cnt_q` | 2 bit | Số request bus **đã được grant** |
| `fill_rvd_cnt_q` | 2 bit | Số beat **đã nhận** từ bus |
| `fill_out_cnt_q` | 2 bit | Số beat **đã gửi** ra IF |
| (`fill_ram_done_q`) | 1 bit | Đã ghi line vào RAM cache chưa |

Khởi tạo khi `fill_alloc`:
* `fill_ext_cnt_d = {1'b0, fill_spec_done}` — nếu request suy đoán đã được grant thì đếm 1.
* `fill_rvd_cnt_d = 0`
* `fill_out_cnt_d = {1'b0, lookup_addr_ic0[2]}` — **bắt đầu từ beat chứa PC**,
  không phải beat 0! Đây là cơ chế *critical-word-first* ở mức xuất ra IF.

Bit MSB của bộ đếm (`[1]`) = "đã hoàn tất" (đếm tới 2 = `IC_LINE_BEATS`).

### 6.3 Request suy đoán

```systemverilog
fill_spec_req  = (~icache_enable_i | branch_i) & ~|fill_ext_req;
fill_spec_done = fill_spec_req & instr_gnt_i;
fill_spec_hold = fill_spec_req & ~instr_gnt_i;

instr_req  = ((~icache_enable_i | branch_i) & lookup_grant_ic0) | (|fill_ext_req);
instr_addr = |fill_ext_req ? fill_ext_req_addr : lookup_addr_ic0[31:2];
instr_addr_o = {instr_addr, 2'b00};
```

Khi **branch** hoặc **cache bị tắt**, I$ phát request ra bus **ngay ở IC0**, song song
với lookup tag — giảm 1 chu kỳ trễ nếu miss. Nếu sau đó IC1 báo hit
(`fill_hit_ic1`), request đã phát vẫn phải nhận rvalid nhưng dữ liệu bị bỏ qua
(`fill_data_en[fb][b]` có điều kiện `~fill_hit_q[fb]`).

### 6.4 Điều kiện giải phóng buffer

```systemverilog
fill_done[fb] = (fill_ram_done_q | fill_hit_q | ~fill_cache_q | (|fill_err_q))  // ghi RAM xong
              & (fill_out_done | fill_stale_q | branch_i)                        // xuất xong
              & fill_rvd_done;                                                   // bus xong
```

Ba điều kiện phải **cùng** thoả:
1. Line đã ghi vào cache **hoặc** hit **hoặc** không cần cache **hoặc** có lỗi bus.
2. Đã xuất đủ beat ra IF **hoặc** đã stale (bị branch cắt) **hoặc** đang có branch.
3. Tất cả request bus đã nhận đủ rvalid.

### 6.5 Stale (bị branch huỷ)

```systemverilog
fill_stale_d[fb] = fill_busy_q[fb] & (branch_i | fill_stale_q[fb]);
```

Khi có branch, **mọi** buffer đang bận trở thành stale. Buffer stale:
* Không xuất dữ liệu ra IF nữa (`fill_out_req` có `~fill_stale_q`).
* Vẫn tiếp tục nhận rvalid (giao thức bus bắt buộc).
* Vẫn ghi line vào cache nếu `fill_cache_q` (dữ liệu vẫn hữu ích cho lần sau).
* Có thể huỷ request bus chưa phát: `fill_ext_done_d` có nhánh
  `(~fill_cache_q & (branch_i | fill_stale_q | fill_ext_beat[fb][1]))` —
  nhưng **chỉ khi không cache**, và **không thể huỷ khi đang chờ grant**
  (`~fill_ext_hold_q[fb]`).

### 6.6 Trọng tài theo tuổi

Tất cả đều là one-hot:

```systemverilog
fill_ext_arb[fb]  = fill_ext_req[fb]  & ~|(fill_ext_req  & fill_older_q[fb]);
fill_ram_arb[fb]  = fill_ram_req[fb]  & fill_grant_ic0 & ~|(fill_ram_req & fill_older_q[fb]);
fill_rvd_arb[fb]  = instr_rvalid_i & fill_rvd_exp[fb] & ~|(fill_rvd_exp & fill_older_q[fb]);
fill_data_sel[fb] = ~|(fill_busy_q & ~fill_out_done & ~fill_stale_q & fill_older_q[fb]);
fill_out_arb[fb]  = fill_out_req[fb] & fill_data_sel[fb];
```

`fill_rvd_arb` là điểm mấu chốt: bus trả về **đúng thứ tự**, nên beat đến luôn thuộc
về buffer già nhất còn chờ.

### 6.7 Ba nguồn dữ liệu xuất ra IF

```systemverilog
fill_data_reg[fb] = ... & ((fill_rvd_beat[fb] > fill_out_cnt_q[fb]) | fill_hit_q | |fill_err_q);
fill_data_hit[fb] = fill_busy_q[fb] & fill_hit_ic1[fb] & fill_data_sel[fb];
fill_data_rvd[fb] = ... & (fill_rvd_beat[fb] == fill_out_cnt_q[fb]) & fill_data_sel[fb];

line_data   = |fill_data_hit ? hit_data_ic1 : fill_out_data;
output_data = |fill_data_rvd ? instr_rdata_i : line_data_muxed;
```

| Nguồn | Khi nào | Độ trễ |
|---|---|---|
| `hit_data_ic1` | Hit cache ở IC1 ngay chu kỳ này | 2 chu kỳ (IC0→IC1) |
| `instr_rdata_i` | Beat vừa về từ bus và đúng beat cần | 0 chu kỳ thêm (**bypass**) |
| `fill_data_q[fb]` | Dữ liệu đã đệm trong buffer | 1 chu kỳ thêm |

Đường bypass `fill_data_rvd` cực kỳ quan trọng: dữ liệu miss được chuyển thẳng tới IF
**cùng chu kỳ** rvalid về, không mất chu kỳ đệm.

### 6.8 Theo dõi lỗi bus

```systemverilog
fill_err_d[fb][b] = (fill_rvd_arb[fb] & instr_err_i & (fill_rvd_off[fb] == b))
                  | (fill_busy_q[fb] & fill_err_q[fb][b]);
```

Lỗi được ghi nhận **theo từng beat**. Line có lỗi ở bất kỳ beat nào sẽ **không** được ghi
vào cache (`fill_ram_req` có `~|fill_err_q[fb]`).

Khi xuất: `fill_out_err |= (fill_err_q[i] & ~{2{fill_hit_q[i]}})` — bỏ qua lỗi tích luỹ
từ request suy đoán nếu sau đó hoá ra là hit.

---

## 7. Skid buffer & căn chỉnh đầu ra

`ibex_icache.sv:1040-1200`. Đây là phần thay thế `ibex_fetch_fifo` khi có I$.

### 7.1 Vấn đề

Bus cấp **32-bit/beat** nhưng lệnh có thể là 16-bit (compressed) hoặc 32-bit,
và có thể **lệch hàng nửa-từ**. Cần:
* Lệnh 32-bit tại `addr[1]=1` → ghép nửa cao word N với nửa thấp word N+1.
* Lệnh 16-bit tại `addr[1]=1` → chỉ cần nửa cao word N.

### 7.2 Skid buffer (16 bit)

```systemverilog
skid_data_d = output_data[31:16];                       // luôn lưu nửa CAO
skid_en     = data_valid & (ready_i | skid_ready);
skid_ready  = output_addr_q[1] & ~skid_valid_q & (~output_compressed | output_err);

skid_complete_instr = skid_valid_q & ((skid_data_q[1:0] != 2'b11) | skid_err_q);
output_ready = (ready_i | skid_ready) & ~skid_complete_instr;
```

`skid_ready` = "tôi có thể nạp skid buffer" — đúng khi PC lệch nửa-từ, skid chưa đầy,
và lệnh không phải compressed (tức cần nửa sau).

`skid_complete_instr` = "skid buffer một mình đã đủ một lệnh compressed" —
khi đó không cần dữ liệu mới từ fill buffer.

### 7.3 Vòng đời `skid_valid_q`

```systemverilog
skid_valid_d = branch_i ? 1'b0 :                                     // branch xoá skid
  (skid_valid_q ? ~(ready_i & ((skid_data_q[1:0] != 2'b11) | skid_err_q))
                : (data_valid & (
                      (output_addr_q[1] & (~output_compressed | output_err))   // branch vào
                                                        // lệnh 32-bit lệch hàng
                    | (~output_addr_q[1] & output_compressed & ~output_err & ready_i)
                  )));                                  // lệnh compressed làm lệch luồng
```

Hai cách nạp skid:
1. **Branch tới địa chỉ lệch nửa-từ** với lệnh 32-bit → nửa cao của word hiện tại là
   nửa **thấp** của lệnh, phải giữ lại chờ word sau.
2. **Lệnh compressed ở nửa thấp** làm luồng lệch sang nửa cao → nửa cao được giữ làm
   khởi đầu lệnh kế.

Skid buffer chỉ được giải phóng khi nó chứa một lệnh compressed hoàn chỉnh và IF pop nó.

### 7.4 Bộ đếm địa chỉ đầu ra

```systemverilog
output_addr_en   = branch_i | (ready_i & valid_o);
addr_incr_two    = output_compressed & ~err_o;
output_addr_incr = output_addr_q[31:1] + {29'd0, ~addr_incr_two, addr_incr_two};  // +2 hoặc +4
output_addr_d    = branch_i ? addr_i[31:1] : output_addr_incr;
addr_o           = {output_addr_q, 1'b0};
```

`output_addr_q` lưu **[31:1]** (địa chỉ nửa-từ), bit 0 luôn 0.

### 7.5 Mux nửa-từ

```systemverilog
// nửa thấp: chọn theo output_addr_q[1]
for (i = 0; i < 2; i++)
  if (output_addr_q[1] == i) output_data_lo |= output_data[i*16 +: 16];

// nửa cao: nửa kế tiếp, có quấn vòng sang word sau
for (i = 0; i < 1; i++)
  if (output_addr_q[1] == i) output_data_hi |= output_data[(i+1)*16 +: 16];
if (&output_addr_q[1]) output_data_hi |= output_data[15:0];   // quấn: lấy nửa thấp word MỚI

rdata_o = {output_data_hi, (skid_valid_q ? skid_data_q : output_data_lo)};
```

Khi `output_addr_q[1] == 1` và skid hợp lệ: nửa thấp lệnh lấy từ skid (word cũ),
nửa cao lấy từ `output_data[15:0]` (word mới) → ghép chính xác lệnh 32-bit lệch hàng.

### 7.6 Tín hiệu valid và lỗi ra IF

```systemverilog
output_valid = skid_complete_instr                       // skid đủ 1 lệnh compressed
             | (data_valid & (~output_addr_q[1]          // căn hàng word
                            | skid_valid_q               // hoặc skid có nửa thấp
                            | output_err                 // hoặc có lỗi (không cần chờ nửa sau)
                            | (output_data[17:16] != 2'b11)));  // hoặc nửa cao là compressed

err_o       = (skid_valid_q & skid_err_q) | (~skid_complete_instr & output_err);
err_plus2_o = skid_valid_q & ~skid_err_q;    // lỗi nằm ở nửa SAU
valid_o     = output_valid;
```

`output_data[17:16] != 2'b11` — kiểm tra 2 bit thấp của **nửa cao** word: nếu ≠ `11` thì
lệnh ở nửa cao là compressed, không cần word tiếp theo.

---

## 8. FSM Invalidate

`ibex_icache.sv:1199-1290`

```
         ┌──────────────┐
reset ──►│ OUT_OF_RESET │  nếu ~ic_scr_key_valid_i → ic_scr_key_req_o = 1
         └──────┬───────┘
                ▼
     ┌──────────────────────┐
     │  AWAIT_SCRAMBLE_KEY  │  chờ ic_scr_key_valid_i
     └──────────┬───────────┘  khi có: inval_index_d = 0
                ▼
     ┌──────────────────────┐
     │     INVAL_CACHE      │  inval_write_req = 1, inval_index++ mỗi chu kỳ
     │                      │  ghi tag invalid vào cả 2 way
     └───┬──────────────┬───┘
         │ &inval_index │ icache_inval_i mới → xin key mới, quay lại AWAIT
         ▼              └──────────────────┐
     ┌──────────────┐                      │
     │  INVAL_IDLE  │◄─────────────────────┘
     │ inval_block_ │  icache_inval_i → ic_scr_key_req_o=1, → AWAIT_SCRAMBLE_KEY
     │  cache = 0   │
     └──────────────┘
```

Đặc điểm:

* `inval_block_cache` mặc định **1**; chỉ về 0 ở `INVAL_IDLE` khi không có yêu cầu mới.
  → Trong suốt quá trình invalidate, không có lookup nào được thực hiện thật
  (`lookup_actual_ic0 = 0`) và không có fill nào được ghi (`fill_cache_new = 0`).
* **Mọi** lần invalidate đều xin **key scramble mới** → mỗi lần `fence.i`, nội dung
  cache cũ trở nên không thể giải mã được. Đây là biện pháp chống side-channel
  qua cache.
* 256 chu kỳ để quét hết `inval_index` (8 bit).
* `busy_o = inval_active | (|(fill_busy_q & ~fill_rvd_done))` — CPU không được ngủ
  khi đang invalidate.

`icache_inval_i` đến từ `ibex_id_stage.icache_inval_o` ← `ibex_decoder.icache_inval_o`,
được set bởi lệnh **`FENCE.I`** (`ibex_decoder.sv:704-728`).

`icache_enable_i` đến từ bit `icache_enable` của CSR `CPUCTRLSTS`
(`ibex_cs_registers.sv:1970-1972`).

---

## 9. Chính sách cấp phát

`ibex_icache.sv:656-680`. Với `BranchCache = 0` (mặc định):

```systemverilog
fill_cache_new = icache_enable_i & ~inval_block_cache;    // cache MỌI miss
fill_cache_d[fb] = (fill_alloc[fb] & fill_cache_new)
                 | (fill_cache_q[fb] & fill_busy_q[fb] & icache_enable_i & ~icache_inval_i);
```

Nếu cache bị tắt hoặc invalidate **giữa chừng** khi buffer đang bận, `fill_cache_q`
bị xoá → line không được ghi vào RAM.

(Tuỳ chọn `BranchCache = 1` chỉ cache line đích của branch + 2 line kế — không dùng ở đây.)

---

## 10. Tóm tắt đường tới hạn (critical path) tiềm năng

1. `ic_data_rdata_i` → un-tweak XOR → mux one-hot theo `tag_match_ic1` →
   `prim_secded_inv_39_32_dec` → `hit_data_ic1` → `fill_data_d` / `line_data` →
   `line_data_muxed` → `output_data_lo/hi` → `rdata_o`.
2. `instr_rdata_i` → `output_data` (bypass) → mux nửa-từ → `rdata_o` →
   (tầng IF) compressed decoder → decoder ID. Đây thường là đường dài nhất khi
   `ICache=1` vì nó xuyên qua cả hai module trong một chu kỳ.
3. `fill_ext_req` → `fill_ext_arb` (cây ưu tiên theo tuổi, 4 mục) → `fill_ext_req_addr`
   → `instr_addr_o`.
