# 11 — Biện pháp bảo mật (`SecureIbex = 1`)

Tổng hợp toàn bộ countermeasure được bật trong cấu hình `opentitan`, kèm tên SEC_CM
xuất hiện trong mã nguồn.

---

## 1. Bảng tổng hợp

| # | SEC_CM | Cơ chế | Tệp:dòng | Trạng thái |
|---|---|---|---|---|
| 1 | `LOGIC.SHADOW` | Lõi bóng lockstep trễ 1 chu kỳ | `ibex_top.sv:872-1240` | **BẬT** |
| 2 | `DATA_REG_SW.INTEGRITY` | ECC SECDED trên register file (chia đôi lõi chính/bóng) | `ibex_core.sv:1214-1330` | **BẬT** (qua lõi bóng) |
| 3 | `DATA_REG_SW.GLITCH_DETECT` | Shadow register file | `ibex_lockstep.sv:636-726` | **BẬT** |
| 4 | `DATA_REG_SW.SCA` | Data-independent timing (nhánh & chia) | `ibex_id_stage.sv:767-852`, `ibex_multdiv_fast.sv:426-450` | **BẬT** (runtime qua CSR) |
| 5 | `CTRL_FLOW.UNPREDICTABLE` | Dummy instruction ngẫu nhiên | `ibex_if_stage.sv:504-567`, `ibex_dummy_instr.sv` | **BẬT** |
| 6 | `PC.CTRL_FLOW.CONSISTENCY` | Kiểm tra `pc_if == pc_id + 2/4` | `ibex_if_stage.sv:659-692` | **BẬT** |
| 7 | `BUS.INTEGRITY` | ECC SECDED trên I-side và D-side | `ibex_if_stage.sv:258-282`, `ibex_load_store_unit.sv:376-398` | **BẬT** |
| 8 | `ICACHE.MEM.INTEGRITY` | ECC trên tag & data RAM I$ | `ibex_icache.sv:286-315`, `:520-615` | **BẬT** |
| 9 | `ICACHE.MEM.SCRAMBLE` | RAM I$ scramble (PRINCE + address scramble) | `ibex_top.sv:620-792` | **BẬT** |
| 10 | `ICACHE.MEM.ADDR_INFECTION` | Tweak infection (XOR địa chỉ vào dữ liệu RAM) | `ibex_icache.sv:318-440` | **BẬT** |
| 11 | `FETCH.CTRL.LC_GATED` | `fetch_enable_i` dạng MuBi 4-bit | `ibex_core.sv:640-658` | **BẬT** |
| 12 | `EXCEPTION.CTRL_FLOW.LOCAL_ESC` / `GLOBAL_ESC` | Phát hiện double fault | `ibex_cs_registers.sv:936-948` | **BẬT** |
| 13 | `CORE.DATA_REG_SW.SCA` | (nhãn của #4 ở `ibex_core.sv:195`) | | **BẬT** |
| 14 | `CHERIOT_ENABLE.CTRL.MUBI` | Kiểm tra mã hoá MuBi của `cheriot_enable_i` | `ibex_core.sv:1342-1350` | **BẬT** |
| — | `CSR.SHADOW` | Shadow copy cho CSR | `ibex_csr.sv:38-52` | **TẮT** (`ShadowCSR = 1'b0`) |
| — | (ResetAll) | Mọi flop có reset → lõi chính/bóng khởi động đồng nhất | toàn bộ RTL | **BẬT** |
| — | (Spurious response) | Chỉ xử lý phản hồi bus khi đang chờ | `ibex_core.sv:1181-1195` | **BẬT** |
| — | (Core busy MuBi) | `core_busy_o` MuBi 4-bit từ 3 bản sao đệm | `ibex_core.sv:498-520` | **BẬT** |

---

## 2. Chi tiết từng biện pháp

### 2.1 Lockstep (`LOGIC.SHADOW`)

Xem [02_tang_ibex_top.md](02_tang_ibex_top.md) §3. Tóm tắt kỹ thuật:

* `ibex_core` thứ hai chạy **cùng clock**, đầu vào trễ 1 chu kỳ, đầu ra lõi chính cũng
  trễ 1 chu kỳ để so sánh.
* Tất cả đầu vào đi qua **một** `prim_buf` rộng vài nghìn bit — rào chống hợp nhất logic
  khi tổng hợp (Vivado `keep`, DC `size_only`).
* Reset lõi bóng qua `prim_clock_mux2` để DFT bypass được.
* So sánh dùng `enable_cmp_q != IbexMuBiOff` — fail-safe.
* `rst_shadow_cnt_err` từ `prim_count` (bộ đếm dư thừa) cũng gây alert.

**Điểm yếu đã được xử lý:** nếu chỉ so sánh đầu ra, một lỗi trong register file sẽ không
bị bắt (vì RF nằm ngoài lõi). Giải pháp: shadow register file + ECC chia đôi (§2.2).

### 2.2 ECC register file (`DATA_REG_SW.INTEGRITY` + `GLITCH_DETECT`)

Kiến trúc chia đôi (xem [00_tong_quan_cau_hinh.md](00_tong_quan_cau_hinh.md) §4):

```
Lõi chính:  RegFileECC=0, RegFileDataWidth=32
            register_file_i (DataWidth=32, CapWidth=35)  ← 32 bit DATA + 35 bit CAP

Lõi bóng:   RegFileECC=1, RegFileDataWidth=39
            register_file_shadow_i (DataWidth=7, CapWidth=7)  ← 7 bit ECC + 7 bit CAP-ECC

Trong lõi bóng:
  rf_rdata_a_ecc_i = {shadow_rf_rdata_a_intg[6:0], main_rf_rdata_a[31:0]}    // 39 bit
  → prim_secded_inv_39_32_dec → rf_ecc_err_a
  rf_rcap_a_ecc_i  = {shadow_rf_rcap_a_ecc[6:0], main_rf_rcap_a[34:0]}       // 42 bit
  → zero-pad lên 64 → prim_secded_inv_64_57_dec → rf_cap_ecc_err_a
```

Điều kiện lỗi (`ibex_core.sv:1281-1292`):
```systemverilog
rf_ecc_err_a_id = (|rf_ecc_err_a | ((cheriot_enable_i == IbexMuBiOn) & |rf_cap_ecc_err_a))
                  & rf_ren_a & ~(rf_rd_a_wb_match & rf_write_wb);
rf_ecc_err_comb = instr_valid_id & (rf_ecc_err_a_id | rf_ecc_err_b_id);
```

Hai điều kiện qualify quan trọng:
1. `rf_ren_a` — chỉ kiểm khi lệnh thực sự đọc thanh ghi đó (thanh ghi chưa ghi có ECC rác).
2. `~(rf_rd_a_wb_match & rf_write_wb)` — khi dữ liệu được forward từ WB, giá trị đọc từ RF
   bị bỏ qua → không kiểm (tránh X-propagation vào đường alert).
3. Lỗi cap ECC chỉ tính khi CHERIoT bật — vì ở chế độ RV32I, `rf_shared` lưu dữ liệu
   x16–x31 chứ không phải capability, và 7 bit "cap ECC" trong lõi bóng không có nghĩa.

`WordZeroVal = SecdedInv3932ZeroWord` — giá trị reset của RF là codeword ECC **hợp lệ**
của số 0, không phải toàn 0.

### 2.3 Data-independent timing (`DATA_REG_SW.SCA`)

Bật/tắt runtime bằng `cpuctrlsts.data_ind_timing`. Ba tác động:

**(a) Nhánh luôn 2 chu kỳ** — `ibex_id_stage.sv:767-800`
```systemverilog
branch_set_raw = (BranchTargetALU && !data_ind_timing_i) ? branch_set_raw_d : branch_set_raw_q;
```
Khi DIT bật, `branch_set` đi qua flop → nhánh taken và not-taken **cùng** tốn 2 chu kỳ.

**(b) `id_fsm` luôn vào MULTI_CYCLE** — `ibex_id_stage.sv:920-935`
```systemverilog
id_fsm_d         = (data_ind_timing_i || (!BranchTargetALU && branch_decision_i))
                   ? MULTI_CYCLE : FIRST_CYCLE;
stall_branch     = (~BranchTargetALU & branch_decision_i) | data_ind_timing_i;
branch_set_raw_d = (branch_decision_i | data_ind_timing_i);
```
Chú ý `branch_set_raw_d` được set **kể cả khi branch không taken** — PC được "đặt lại"
về địa chỉ tuần tự, tạo cùng profile bus như branch taken.

**(c) Chia luôn 37 chu kỳ** — `ibex_multdiv_fast.sv:426-450`
```systemverilog
md_state_d    = (!data_ind_timing_i && equal_to_zero_i) ? MD_FINISH : MD_ABS_A;
div_by_zero_d = equal_to_zero_i;
// và:
div_change_sign = (div_sign_a ^ div_sign_b) & ~div_by_zero_q;
```
Chia cho 0 chạy đủ long division; `div_by_zero_q` chặn bước đảo dấu cuối để kết quả
vẫn đúng đặc tả (`-1`).

**Không** bảo vệ: MUL (luôn 1/2 chu kỳ, không phụ thuộc dữ liệu — vốn đã constant-time),
thời gian truy cập bộ nhớ (phụ thuộc bus, ngoài tầm kiểm soát của lõi).

**Bổ sung riêng cho CHERIoT:** `cheriot_force_uc` ở tầng IF
(`ibex_if_stage.sv:462-466`) — khi PCC chỉ cho phép fetch 2 byte, ép coi dữ liệu là
lệnh compressed thay vì chờ nửa sau → thời gian fetch không phụ thuộc bounds.

### 2.4 Dummy instruction (`CTRL_FLOW.UNPREDICTABLE`)

Xem [03_tang_IF.md](03_tang_IF.md) §6.

Ba yếu tố ngẫu nhiên từ LFSR 32-bit (`prim_lfsr` với `StatePerm` hoán vị):
1. **Khoảng cách** giữa các lần chèn (`cnt[4:0]` & mask từ CSR).
2. **Loại lệnh** (`instr_type[1:0]`): add / mul / div / and — profile công suất và thời
   gian rất khác nhau (div = 37 chu kỳ!).
3. **Toán hạng** (`op_a[4:0]`, `op_b[4:0]`) — Hamming weight khác nhau.

Seed được nạp qua CSR `SECURESEED` (`0x7C1`) và **tích luỹ XOR**:
```systemverilog
dummy_instr_seed_d = dummy_instr_seed_q ^ dummy_instr_seed_i;
```
→ phần mềm có thể liên tục bơm entropy mà không cần biết trạng thái hiện tại.

Lệnh dummy ghi vào **x0**, nhưng x0 được hiện thực là flop thật khi `DummyInstructions=1`
(`ibex_register_file_ff.sv:140-185`) — nếu x0 bị hard-wire 0 thì tổng hợp sẽ tối ưu bỏ
toàn bộ đường tính toán của lệnh dummy, vô hiệu hoá biện pháp.

```systemverilog
assign rf_data[0] = dummy_instr_id_i ? rf_data_r0_q : WordZeroVal;
```
Đọc x0 cho lệnh **thật** vẫn trả về 0.

### 2.5 Kiểm tra PC (`PC.CTRL_FLOW.CONSISTENCY`)

Xem [03_tang_IF.md](03_tang_IF.md) §8. Điểm then chốt: `prim_buf` trên
`prev_instr_addr_incr` — nếu không có, tổng hợp nhận ra `pc_if` xuất phát từ cùng bộ đếm
và tối ưu phép so sánh thành hằng.

Điều kiện bỏ qua kiểm tra: sau branch/jump/exception/interrupt/debug (`branch_req`),
sau lỗi fetch, khi chèn dummy, khi đang bung Zcmp, và sau reset.

### 2.6 ECC bus (`BUS.INTEGRITY`)

`MemECC = 1` → `MemDataWidth = 39`, dùng `prim_secded_inv_39_32`.

| Hướng | Vị trí | Xử lý lỗi |
|---|---|---|
| I-side đọc | `ibex_if_stage.sv:258-282` | `instr_intg_err_o` → `alert_major_bus_o`; cũng gộp vào `instr_err` → `ExcCauseInstrAccessFault` |
| D-side đọc | `ibex_load_store_unit.sv:376-398` | `load/store_resp_intg_err_o` → `alert_major_bus_o` **và** NMI nội bộ |
| D-side ghi | `ibex_load_store_unit.sv:728-736` | Sinh 7 bit ECC |

**Không sửa lỗi** — mọi lỗi (1 bit hay 2 bit) đều xử lý như nhau. Lý do: sửa lỗi ngầm
che giấu tấn công; báo alert an toàn hơn.

Cả hai đường đọc đều có `prim_buf` trước bộ giải mã.

**Lỗi ECC D-side không sinh exception đồng bộ** mà đi qua NMI nội bộ
(`ibex_controller.sv:393-452`) — để tránh đường feedthrough `data_rdata_i → data_req_o`.

### 2.7 ECC + Scramble + Tweak cho I$

Ba lớp chồng nhau trên cùng RAM:

```
dữ liệu logic ──► [ECC encode (39,32)] ──► [XOR tweak địa chỉ] ──► [prim_ram_1p_scr]
                                                                     ├ address scramble (2 vòng)
                                                                     └ data scramble (PRINCE 2 half-round)
```

| Lớp | Chống lại |
|---|---|
| ECC | Bit-flip (fault injection, soft error) |
| Scramble (data) | Đọc trực tiếp nội dung SRAM (probing, cold-boot) |
| Scramble (address) | Suy ra địa chỉ từ vị trí vật lý |
| Tweak infection | **Hoán đổi dòng** — đọc đúng dữ liệu nhưng từ địa chỉ sai |

Tweak infection bổ sung cho address scramble: address scramble của `prim_ram_1p_scr` là
hàm một-một, một tấn công ép địa chỉ vẫn có thể trả về dữ liệu hợp lệ về mặt ECC.
Với tweak, dữ liệu trả về sẽ bị un-XOR bằng tweak **của địa chỉ mong muốn**, không phải
địa chỉ thật → ECC báo lỗi.

Key scramble được **làm mới mỗi lần invalidate** (`fence.i`) — xem
[04_icache.md](04_icache.md) §8.

### 2.8 `fetch_enable_i` MuBi (`FETCH.CTRL.LC_GATED`)

`ibex_core.sv:640-658`

```systemverilog
prim_buf #(.Width(4)) u_fetch_enable_buf (.in_i(fetch_enable_i), .out_o(fetch_enable_buf));
// trong ibex_core:
instr_req_gated = instr_req_int & (fetch_enable_i == IbexMuBiOn);   // == 4'b0101
instr_exec      = fetch_enable_i == IbexMuBiOn;
```

Chỉ **đúng** mẫu `4'b0101` mới cho phép fetch. Mọi giá trị khác (kể cả glitch 1 bit)
→ CPU dừng. Trong OpenTitan, tín hiệu này đến từ Life-Cycle controller.

`instr_exec` cũng đi vào controller: `if (~instr_exec_i) halt_if = 1'b1;`
→ ngừng nhận lệnh mới vào ID.

Assertion `NoExecWhenFetchEnableNotOn` (`ibex_core.sv:1422-1424`) kiểm tra sau khi
fetch bị tắt, `instr_valid_id` không được lên lại và `pc_id` phải giữ nguyên.

### 2.9 Phát hiện double fault

Xem [10_csr_pmp_counter.md](10_csr_pmp_counter.md) §2.7.

Cấp `ibex_top` còn có **predictor RVFI độc lập** (`ibex_top.sv:1510-1596`) mô phỏng lại
bit `sync_exc_seen` và kiểm tra `double_fault_seen_o` bằng 3 assertion:
`DoubleFaultSinglePulse`, `DoubleFaultPulseSeenOnDoubleFault`, `DoubleFaultPulseOnlyOnDoubleFault`.

### 2.10 Kiểm tra MuBi `cheriot_enable_i`

`ibex_core.sv:1342-1350`

```systemverilog
cheriot_enable_mubi_err = instr_exec & !((cheriot_enable_i == IbexMuBiOn) ||
                                          (cheriot_enable_i == IbexMuBiOff));
`ASSERT(CheriotEnableOneWaySwitch,
        (cheriot_enable_i == IbexMuBiOn) |=> (cheriot_enable_i == IbexMuBiOn), clk_i, !rst_ni)
```

Gate bằng `instr_exec` để không báo alert trước khi hệ thống khởi tạo xong.
`cheriot_enable_i` cũng được đưa vào lockstep (`shadow_inputs_in.cheriot_enable`) nên
mọi bất nhất cũng bị bắt bởi lockstep.

**Tính một chiều** là yêu cầu bảo mật: nếu có thể tắt CHERIoT lúc chạy, kẻ tấn công
sẽ vô hiệu hoá toàn bộ mô hình bảo vệ capability.

### 2.11 Phản hồi bus giả

`ibex_core.sv:1181-1195`

```systemverilog
lsu_load_err  = lsu_load_err_raw  & (outstanding_load_wb  | expecting_load_resp_id);
lsu_store_err = lsu_store_err_raw & (outstanding_store_wb | expecting_store_resp_id);
rf_we_lsu     = lsu_rdata_valid   & (outstanding_load_wb  | expecting_load_resp_id);
```

Glitch `data_rvalid_i` khi không có giao dịch → không ghi RF, không sinh exception.

### 2.12 `core_busy_o` MuBi ba bản sao

`ibex_core.sv:498-520`

```systemverilog
prim_buf #(.Width(12)) u_fetch_enable_buf (          // 4 bit MuBi × 3 tín hiệu
  .in_i({4{ctrl_busy, if_busy, lsu_busy}}), .out_o(busy_bits_buf));

for (i = 0; i < 4; i++)
  if (IbexMuBiOn[i]) core_busy_o[i] =  |busy_bits_buf[i*3 +: 3];
  else               core_busy_o[i] = ~|busy_bits_buf[i*3 +: 3];
```

Mỗi bit của MuBi lấy từ một **nhóm 3 bit đệm riêng** → một lỗi đơn không thể tạo ra
mẫu `IbexMuBiOff` hợp lệ.

### 2.13 `ResetAll`

`ResetAll = Lockstep = 1` khiến **mọi** flop dữ liệu (kể cả các flop enable-only vốn
không cần reset) có `if (!rst_ni) <= '0`. Bắt buộc vì lõi chính và lõi bóng phải khởi
động từ trạng thái **bit-identical**; nếu có flop X sau reset thì so sánh lockstep sẽ
báo mismatch giả.

Chi phí: thêm cổng reset cho hàng trăm flop → tăng diện tích và fan-out mạng reset.

Danh sách các nhánh `g_*_ra` (reset-all) vs `g_*_nr` (no-reset) trải khắp RTL:
`ibex_if_stage.sv:589`, `ibex_icache.sv:227,455,...`, `ibex_wb_stage.sv:126`,
`ibex_fetch_fifo.sv:183,246`, v.v.

---

## 3. Ma trận alert

| Alert | Nguồn | Khôi phục |
|---|---|---|
| `alert_minor_o` | `icache_ecc_error` (lõi chính hoặc bóng) | **Có** — I$ tự invalidate way lỗi và fetch lại từ bus |
| `alert_major_internal_o` | `rf_ecc_err_comb`, `pc_mismatch_alert`, `csr_shadow_err`(=0), `cheriot_fatal_err`, `cheriot_enable_mubi_err`, lockstep mismatch, `rst_shadow_cnt_err`, MuBi error của RAM I$ | **Không** |
| `alert_major_bus_o` | `lsu_load/store_resp_intg_err`, `instr_intg_err`, `trvk_revbm_data_intg_error`, `trvk_revbm_device_error` | **Không** |

---

## 4. Những gì **không** được bảo vệ trong cấu hình này

| Hạng mục | Lý do |
|---|---|
| Shadow copy CSR | `ShadowCSR = 1'b0` hard-code ở `ibex_core.sv:197` |
| Sửa lỗi ECC (correction) | Cố ý — chỉ phát hiện, không sửa |
| Thời gian truy cập bộ nhớ | Phụ thuộc bus/interconnect bên ngoài |
| Thời gian I$ hit/miss | Không constant-time; phần mềm nhạy cảm nên tắt I$ (`cpuctrl.icache_enable = 0`) |
| Branch predictor | Không tồn tại (`BranchPredictor = 0`) — chính là điểm cộng cho bảo mật |

---

## 5. Chi phí ước lượng

| Biện pháp | Chi phí diện tích tương đối |
|---|---|
| Lockstep | **~100%** (nhân đôi lõi) |
| Shadow register file | ~22% register file (7/32 bit data + 7/35 bit cap) |
| ECC bus (I + D) | Nhỏ (2 decoder + 1 encoder 39/32) |
| ECC I$ | ~27% tag RAM (28 vs 22 bit), ~22% data RAM (78 vs 64 bit) |
| Scramble I$ | PRINCE 2 half-round × 4 bank |
| Tweak infection | Chỉ XOR + 2 flop (`data_tweak_ic1`, `tag_index_ic1`) |
| Dummy instruction | LFSR 32-bit + bộ đếm 5-bit + mux |
| PC check | 1 adder 32-bit + comparator + `prim_buf` |
| ResetAll | Cổng reset cho các flop vốn không cần |
| `core_busy` MuBi | 12 flop thay vì 1 |

Tổng: lõi `opentitan` lớn hơn đáng kể so với `maxperf` chủ yếu do lockstep.
