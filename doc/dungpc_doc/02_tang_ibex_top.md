# 02 — Tầng `ibex_top`: các khối ngoài lõi

Tệp: `ibex/rtl/ibex_top.sv` (1642 dòng).
`ibex_top` **không chứa logic pipeline**; nó là tầng tích hợp gồm 7 khối con.

---

## 1. Cổng clock chính (Main clock gate)

`ibex_top.sv:298-338`

### 1.1 Cấu trúc

```systemverilog
// SecureIbex = 1 → nhánh g_clock_en_secure
prim_flop #(.Width(4), .ResetValue(IbexMuBiOff)) u_prim_core_busy_flop (
  .d_i(core_busy_d), .q_o(core_busy_q));

assign clock_en = (core_busy_q != IbexMuBiOff) | debug_req_i | irq_pending | irq_nm_i;
assign core_sleep_o = ~clock_en;

prim_clock_gating core_clock_gate_i (.clk_i, .en_i(clock_en), .test_en_i, .clk_o(clk));
```

### 1.2 Phân tích

* `core_busy_d` đến từ `ibex_core.core_busy_o`, là **MuBi 4-bit** (`IbexMuBiOn = 4'b0101`,
  `IbexMuBiOff = 4'b1010`).
* Ở chế độ secure, `clock_en` yêu cầu `core_busy_q != IbexMuBiOff` — tức **bất kỳ** giá trị
  nào khác `4'b1010` đều bật clock. Đây là hướng an toàn (fail-open on clock): glitch trên
  `core_busy_q` không thể làm treo clock ngoài ý muốn.
* Tại `ibex_core.sv:498-520`, `core_busy_o` được sinh từ **3 bản sao đệm** của
  `{ctrl_busy, if_busy, lsu_busy}` qua `prim_buf`, mỗi bit của MuBi lấy OR/NOR riêng
  một nhóm 3 bit → chống tối ưu hoá hợp nhất.
* `clk` (đã gate) cấp cho `ibex_core`, `register_file_i`, `ibex_lockstep`, `ibex_trvk`.
  RAM I$ dùng `clk_i` **chưa gate** — vì scrambling cần key update ngay cả khi lõi ngủ.

### 1.3 Điều kiện đánh thức

`debug_req_i | irq_pending | irq_nm_i` được lấy **trực tiếp từ chân/tổ hợp**, không qua flop,
để CPU thức dậy khỏi WFI ngay chu kỳ có interrupt. `irq_pending` là tổ hợp thuần
(`mip & mie`) ở `ibex_cs_registers.sv:1043-1046`.

---

## 2. Hạ tầng scrambling I-Cache

`ibex_top.sv:620-672` — khối `gen_scramble` **[BẬT]**.

### 2.1 Máy trạng thái key

Hai flop điều khiển: `scramble_key_valid_q`, `scramble_req_q`.

```systemverilog
scramble_key_valid_d = scramble_req_q ? scramble_key_valid_i :   // đang chờ key mới
                       ic_scr_key_req ? 1'b0                 :   // I$ xin key mới
                                        scramble_key_valid_q;

scramble_req_d       = scramble_req_q ? ~scramble_key_valid_i : ic_scr_key_req;
scramble_req_o       = scramble_req_q;
```

Diễn giải:

1. Reset: `scramble_key_valid_q = 1`, key = `RndCnstIbexKey` (128-bit hằng compile-time),
   nonce = `RndCnstIbexNonce`.
2. I$ (FSM invalidate) phát `ic_scr_key_req` → `key_valid` về 0, `scramble_req_o` lên 1.
3. OTP trả `scramble_key_valid_i` → key/nonce mới được nạp vào `scramble_key_q/nonce_q`,
   `scramble_req_q` về 0, `key_valid_q` lên 1.
4. I$ thấy `ic_scr_key_valid_i=1` → bắt đầu ghi toàn bộ tag RAM với tag invalid.

Điểm quan trọng: **key/nonce được nạp bất cứ khi nào `scramble_key_valid_i` lên**
(`always_ff` không điều kiện `scramble_req_q`), nhưng `scramble_key_valid_q` chỉ nhận
key mới khi đang trong pha request.

### 2.2 RAM

```systemverilog
prim_ram_1p_scr #(
  .Width(28 hoặc 78), .Depth(256), .DataBitsPerMask(=Width),
  .ReplicateKeyStream(1)   // chỉ cho data bank
  .EnableParity(0),
  .NumPrinceRoundsHalf(2), .NumAddrScrRounds(2)
) tag_bank / data_bank
```

* `NumAddrScrRounds = ICacheScramble ? 2 : 0` (`ibex_top.sv:227`).
* `DataBitsPerMask = Width` → không hỗ trợ byte-write, mọi ghi là full-word.
* `alert_o` của cả 4 RAM được OR thành `icache_alert_major_internal`
  (`ibex_top.sv:1360`).
* Assertion `ScrambleKeyAppliedAtTagBank_A` / `...DataBank_A` (`ibex_top.sv:775-792`)
  kiểm tra key tới RAM trong ≤10 chu kỳ.

---

## 3. Lockstep (`ibex_lockstep`)

`ibex_top.sv:872-1240` (instantiation) + `ibex/rtl/ibex_lockstep.sv` (750 dòng).

### 3.1 Rào tối ưu hoá

Tất cả tín hiệu vào lockstep được ghép thành một vector `buf_in` rộng `NumBufferBits`
rồi đi qua **một** `prim_buf` (`ibex_top.sv:1094-1098`). `prim_buf` có thuộc tính
`keep` (Vivado) / `size_only` (DC) để tổng hợp **không** hợp nhất logic lõi chính với lõi bóng.
Hai mảng `ic_tag_rdata` / `ic_data_rdata` (unpacked array) được đệm riêng theo từng way
(`ibex_top.sv:1101-1112`).

Danh sách tín hiệu được đệm (`ibex_top.sv:880-928`) gồm cả giao diện instr, data, RF,
I$ RAM, IRQ, debug, crash_dump, `cheriot_enable_i`, `rf_wcap`, `rf_rcap_a/b`.

### 3.2 Reset lệch pha lõi bóng

`ibex_lockstep.sv:149-236`. Với `LockstepOffset = 1` → nhánh `gen_no_reset_counter`:

```systemverilog
assign rst_shadow_set_d = IbexMuBiOn;              // lên ngay chu kỳ đầu sau reset
always_ff: enable_cmp_d <= IbexMuBiOn;             // trễ 1 chu kỳ
prim_flop u_prim_rst_shadow_set_flop  → rst_shadow_set_q
prim_flop u_prim_enable_cmp_flop      → enable_cmp_q
prim_clock_mux2 u_prim_rst_shadow_n_mux2(.clk0_i(rst_shadow_set_q[0]),
                                         .clk1_i(scan_rst_ni), .sel_i(test_en_i),
                                         .clk_o(rst_shadow_n));
```

→ lõi bóng ra khỏi reset **trễ 1 chu kỳ**; so sánh bật trễ thêm 1 chu kỳ nữa.
Ở chế độ scan (`test_en_i=1`), reset lõi bóng lấy trực tiếp từ `scan_rst_ni`.

Nếu `LockstepOffset > 1` thì dùng `prim_count` (bộ đếm dư thừa có `err_o`), và
`rst_shadow_cnt_err` cũng góp vào `alert_major_internal_o`.

### 3.3 Trễ đầu vào / đầu ra

* **Đầu vào** lõi bóng: struct `delayed_inputs_t` (`ibex_lockstep.sv:243-267`) gồm
  instr_gnt/rvalid/rdata/err, data_gnt/rvalid/rdata/rdata_tag/err, rf_rdata_a/b,
  irq_*, debug_req, fetch_enable, mcounteren_writable, ic_scr_key_valid,
  **cheriot_enable**, **rf_rcap_a/b** → shift register sâu `LockstepOffset` = 1.
* **Đầu ra** lõi chính: struct `delayed_outputs_t` (`ibex_lockstep.sv:358-380`) gồm
  instr_req/addr, data_req/we/be/addr/wdata/**tag**, ic_tag_*/ic_data_*, ic_scr_key_req,
  irq_pending, crash_dump, double_fault_seen, core_busy, **rf_wcap_wb**
  → trễ `OutputsOffset` chu kỳ.
* Đầu ra lõi bóng `shadow_outputs_d` được flop thành `shadow_outputs_q`.

### 3.4 So sánh

`ibex_lockstep.sv:730-744`:

```systemverilog
assign outputs_mismatch = (enable_cmp_q != IbexMuBiOff) &
                          (shadow_outputs_q != core_outputs_q[0]);
assign alert_major_internal_o = outputs_mismatch | shadow_alert_major_internal
                              | rst_shadow_cnt_err;
assign alert_major_bus_o      = shadow_alert_major_bus;
assign alert_minor_o          = shadow_alert_minor;
```

So sánh **toàn bộ struct** bằng một phép `!=` — tổng hợp thành cây XOR/OR.
`enable_cmp_q != IbexMuBiOff` (thay vì `== IbexMuBiOn`) → bất kỳ glitch nào trên
`enable_cmp_q` vẫn bật so sánh (fail-safe).

### 3.5 Những tín hiệu **không** được so sánh (có chủ đích)

`ibex_lockstep.sv:418-432`:

* `rf_wdata_wb_ecc`, `rf_raddr_a/b`, `rf_waddr_wb`, `rf_we_wb`,
  `dummy_instr_id/wb` — vì chúng đi thẳng vào **shadow register file**. Lỗi ở đây
  sẽ làm 7 bit ECC không khớp 32 bit data → bộ giải mã SECDED trong lõi bóng bắt được.
* `data_wdata_intg` — vì `data_wdata` đã được so sánh rồi.

### 3.6 Đầu ra shadow ra ngoài `ibex_top`

`data_req_shadow_o`, `data_we_shadow_o`, `data_be_shadow_o`, `data_addr_shadow_o`,
`data_wdata_shadow_o`, `data_wdata_intg_shadow_o`, `instr_req_shadow_o`,
`instr_addr_shadow_o`, `lockstep_cmp_en_o`. Đây là các đầu ra **combinational**
(`shadow_outputs_d`) để hệ thống bên ngoài (ví dụ bus adapter của OpenTitan) có thể
tự so sánh độc lập.

---

## 4. `ibex_trvk` — Temporal Revocation Check

`ibex/rtl/ibex_trvk.sv` (420 dòng). **[BẬT]** vì `BaseIsa == BaseIsaRV32IorCHERIoT`.

### 4.1 Vị trí

`ibex_trvk` nằm **chắn giữa** cổng data của `ibex_core` và cổng data ra ngoài
(`ibex_top.sv:1275-1320`):

```
ibex_core.data_*  ──► trvk_* (upstream)  ──[ibex_trvk]──►  data_* (downstream)  ──► bus
                                               │
                                               └──► trvk_revbm_* ──► revocation bitmap SRAM
```

Nếu `BaseIsa == BaseIsaRV32I` thì chỉ là dây nối thẳng (`ibex_top.sv:1321-1360`).

### 4.2 Nhiệm vụ

Khi CPU **load một capability** (2 word liên tiếp trên bus 32-bit), TRVK phải:

1. Nhận diện đây là capability (`downstream_tag_i = 1`).
2. Tính **base** của capability từ metadata + pointer.
3. Tra bit tương ứng trong **revocation bitmap** (1 bit cho mỗi capability 64-bit trong heap).
4. Nếu bit = 1 → **xoá tag** khi trả về CPU → capability trở thành dữ liệu thường.

### 4.3 Kiến trúc dòng chảy

```
upstream_req_i ──► stream_fork ──┬──► downstream_req_o
                                 └──► align FIFO (lưu addr[2]: word thấp/cao của cap)

downstream_rvalid_i ──► prim_fifo_sync (ds_rsp_t = {data, intg, tag, err}, Depth=2)
                                 │
                                 ▼
                       ┌──────── downstream_rsp_out ────────┐
                       │                                    │
        word thấp (addr[2]=0) → ptr_storage_q     word cao (addr[2]=1) → cap_meta
                                                             │
                                             cheriot_expand_bound33(...)  → cap_base
                                                             │
                                  revbm_cap_addr = cap_base - heap_base_addr_i
                                  revbm_bit_addr = revbm_cap_addr >> 3
                                  revbm_addr     = bit_addr[.. : 5]
                                  revbm_bit_select = bit_addr[4:0]
                                                             │
                                                    revbm_req_o ──► SRAM bitmap
                                                             │
                                  revbm_revoked = rdata[bit_select] | err | intg_err
                                                             │
          upstream_tag_o = (revbm_rvalid_i ? !revbm_revoked : 1'b1) & rsp_out.tag
```

### 4.4 Điều kiện phát yêu cầu tra bitmap

`ibex_trvk.sv:349-357`:

```systemverilog
revbm_req_required = !is_sealing_cap          &&  // không phải sealing cap
                     ptr_storage_valid_q      &&  // pointer word đã lưu và hợp lệ
                     downstream_rsp_out.tag   &&  // đúng là capability (tag=1)
                     downstream_rsp_out_valid &&
                     misalign_flag_out        &&  // đang ở word CAO của cap
                     misalign_flag_out_valid  &&
                     !revbm_out_of_range;         // base nằm trong vùng heap
```

`revbm_out_of_range` = base nằm ngoài dải bitmap
(`RevBitmapAddrWidth = 11` bit mặc định → bitmap 2 KiB → 16384 bit → phủ 128 KiB heap).

### 4.5 Đồng bộ phản hồi

`stream_join_dynamic` (`ibex_trvk.sv:171-180`) chỉ phát `upstream_rvalid_o` khi **cả**
phản hồi bus **và** (nếu cần) phản hồi bitmap đã sẵn sàng. `sel_i = {revbm_req_required, 1'b1}`
là "dynamic select": khi không cần tra bitmap thì chỉ chờ bus.

Chỉ **một** yêu cầu bitmap outstanding tại một thời điểm (`revbm_outstanding_q`).

### 4.6 Xử lý lỗi

| Nguồn lỗi | Kết quả |
|---|---|
| `revbm_err_i` (device error) | `revbm_revoked = 1` (xoá tag) **và** `revbm_device_error_o = 1` → `alert_major_bus_o` |
| ECC sai trên `revbm_rdata_i` | `revbm_revoked = 1` **và** `revbm_data_intg_error_o = 1` → `alert_major_bus_o` |

Chọn "fail-secure": lỗi đọc bitmap → coi như capability đã bị thu hồi.

### 4.7 Giả định (ghi trong header module)

> "Assumes a tagged capability load always arrives downstream as exactly two consecutive,
> uninterrupted 32-bit responses from a single, in-order requester."

Điều này được đảm bảo bởi LSU: FSM `CTX_WAIT_GNT1/GNT2/RESP` phát đúng 2 request liên tiếp.

---

## 5. Kết hợp / tách ECC dữ liệu bộ nhớ

`ibex_top.sv:355-366` và `ibex_top.sv:861-871`:

* **Đọc**: `{data_rdata_intg_i, data_rdata_i}` → `data_rdata_core[38:0]` vào lõi.
* **Ghi**: `data_wdata_core[38:0]` tách thành `trvk_wdata[31:0]` và
  `trvk_wdata_intg[6:0]` (qua `prim_buf` để giữ đường riêng biệt).
* Kiểm ECC thực tế nằm **trong lõi**: `ibex_if_stage.sv:258-282` (I-side) và
  `ibex_load_store_unit.sv:376-398` (D-side). Sinh ECC ghi nằm ở
  `ibex_load_store_unit.sv:728-736`.

Assertion cấp `ibex_top` (`ibex_top.sv:1617-1640`) độc lập giải mã lại để kiểm
`alert_major_bus_o` có bật trong ≤5 chu kỳ khi có lỗi ECC.

---

## 6. Tổng hợp alert

`ibex_top.sv:1358-1370`:

```systemverilog
icache_alert_major_internal = (|icache_tag_alert) | (|icache_data_alert);

alert_major_internal_o = core_alert_major_internal      // rf_ecc_err | pc_mismatch |
                       | lockstep_alert_major_internal  //   csr_shadow_err(=0) |
                       | icache_alert_major_internal;   //   cheriot_fatal_err |
                                                        //   cheriot_enable_mubi_err
alert_major_bus_o      = core_alert_major_bus           // lsu intg err | instr intg err
                       | lockstep_alert_major_bus
                       | trvk_revbm_data_intg_error
                       | trvk_revbm_device_error;
alert_minor_o          = core_alert_minor               // icache_ecc_error
                       | lockstep_alert_minor;
```

| Mức alert | Nguồn | Khôi phục được? |
|---|---|---|
| **minor** | Lỗi ECC I$ (đã tự sửa bằng cách invalidate way) | Có |
| **major internal** | RF ECC, PC mismatch, lockstep mismatch, MuBi `cheriot_enable` sai, `cheriot_fatal_err`, RAM I$ MuBi error | Không |
| **major bus** | ECC sai trên I-side/D-side/bitmap, lỗi device bitmap | Không |

---

## 7. Bộ theo dõi giao dịch D-side (chỉ cho assertion)

`ibex_top.sv:1430-1495`, bên trong `` `ifdef INC_ASSERT ``.
Mảng `pending_dside_accesses_q[2]` mô phỏng hàng đợi FIFO các giao dịch đã grant nhưng
chưa có rvalid. Dùng cho:

* `MaxOutstandingDSideAccessesCorrect` — không bao giờ có >2 outstanding.
* `PendingAccessTrackingCorrect` — không nhận rvalid khi không chờ.
* `IbexDataRPayloadX` — kiểm tra X trên rdata (điều kiện khác nhau giữa
  `SecureIbex=1` và `=0`: khi secure, cả write response cũng phải có rdata/intg hợp lệ vì
  `rdata_intg` vẫn được kiểm).

Ngoài ra có **predictor cho `double_fault_seen_o`** dựa trên RVFI (`ibex_top.sv:1510-1596`),
mô phỏng lại bit `sync_exc_seen` của `CPUCTRLSTS` bằng cách theo dõi `rvfi_trap`, `mret`,
và các lệnh ghi `CSR_CPUCTRLSTS`.
