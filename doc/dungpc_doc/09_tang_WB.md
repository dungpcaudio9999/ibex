# 09 — Tầng WB (Writeback)

Tệp: `ibex/rtl/ibex_wb_stage.sv` (311 dòng). **[BẬT]** vì `WritebackStage = 1`.

WB là tầng pipeline **thứ ba**. Nó giữ kết quả của lệnh trong khi chờ phản hồi bộ nhớ,
cung cấp dữ liệu forwarding về ID, và báo hiệu hazard.

---

## 1. Vì sao cần WB stage

Không có WB (`WritebackStage = 0`): lệnh load/store phải **đứng trong ID/EX** cho tới khi
có phản hồi → chặn mọi lệnh sau, kể cả lệnh không liên quan.

Có WB: lệnh load/store chuyển sang WB ngay khi request được chấp nhận
(`lsu_req_done_i`), giải phóng ID/EX cho lệnh kế tiếp. Chỉ khi lệnh kế tiếp **đọc đúng
thanh ghi đích của load** mới phải stall (`stall_ld_hz`).

Đánh đổi: cần logic forwarding, logic hazard, và exception từ bộ nhớ trở thành
"exception từ WB" phải được ưu tiên hơn exception từ ID/EX.

---

## 2. Các thanh ghi WB

`ibex_wb_stage.sv:126-180`, enable = `en_wb_i` (= `instr_done` của ID).

Vì `ResetAll = 1` → nhánh `g_wb_regs_ra`.

| Thanh ghi | Rộng | Nguồn | Mục đích |
|---|---|---|---|
| `rf_we_wb_q` | 1 | `rf_we_id_i` | Lệnh RV32 có ghi RF không |
| `rf_waddr_wb_q` | 5 | `rf_waddr_id_i` | Địa chỉ đích |
| `rf_wdata_wb_q` | 32 | `rf_wdata_id_i` | Kết quả ALU/CSR |
| `wb_instr_type_q` | 2 | `instr_type_wb_i` | LOAD / STORE / OTHER |
| `wb_pc_q` | 32 | `pc_id_i` | PC cho `mepc` khi exception từ WB |
| `wb_compressed_q` | 1 | `instr_is_compressed_id_i` | Đếm `mhpmcounter10` |
| `wb_count_q` | 1 | `instr_perf_count_id_i` | Có tính `minstret` không |
| `wb_is_cheriot_q` | 1 | `instr_is_cheriot_i` | |
| `wb_cheriot_load_q` | 1 | `cheriot_load_i` | CLC |
| `wb_cheriot_store_q` | 1 | `cheriot_store_i` | CSC |
| `cheriot_rf_we_q` | 1 | `cheriot_rf_we_i` | |
| `cheriot_rf_wdata_q` | 32 | `cheriot_result_data` | |
| `cheriot_rf_wcap_q` | 35 | `cheriot_result_cap` | Metadata capability |
| `dummy_instr_wb_q` | 1 | `dummy_instr_id_i` | Cho phép ghi x0 |

Ngoài ra `wb_valid_q` (1 bit) là thanh ghi trạng thái chính.

---

## 3. Điều khiển valid / done

`ibex_wb_stage.sv:107-120`

```systemverilog
wb_valid_d = (en_wb_i & ready_wb_o) | (wb_valid_q & ~wb_done);

wb_done = (wb_instr_type_q == WB_INSTR_OTHER
           && ~(wb_is_cheriot_q && (wb_cheriot_load_q | wb_cheriot_store_q)))
        | lsu_resp_valid_i;

ready_wb_o      = ~wb_valid_q | wb_done;
instr_done_wb_o = wb_valid_q & wb_done;
```

Diễn giải:

* Lệnh **không** truy cập bộ nhớ → `wb_done = 1` ngay lập tức → WB chỉ chiếm 1 chu kỳ
  và `ready_wb_o` luôn 1 → không bao giờ stall ID.
* Lệnh load/store → `wb_done` chỉ khi `lsu_resp_valid_i`.
* `ready_wb_o = ~wb_valid_q | wb_done` — WB nhận lệnh mới khi đang rỗng **hoặc** đang
  hoàn tất trong chu kỳ này (back-to-back).

> **Chú thích quan trọng trong mã** (`ibex_wb_stage.sv:112-114`): `cheriot_load/store`
> không chỉ đến từ decoder mà **đã bao gồm kết quả kiểm tra bound/permission**.
> Vì vậy một CLC bị chặn bởi capability vẫn được coi là "có truy cập bộ nhớ" và
> chờ `lsu_resp_valid_i` — LSU trả về ngay trong 1 chu kỳ qua nhánh `cheriot_err`.

---

## 4. Mux ghi register file

`ibex_wb_stage.sv:181-200` và `:290-305`

```systemverilog
// Nguồn 0: kết quả ID (ALU / CSR / CHERIoT EX)
rf_wdata_wb_mux[0]    = wb_is_cheriot_q ? cheriot_rf_wdata_q : rf_wdata_wb_q;
rf_wdata_wb_mux_we[0] = (wb_is_cheriot_q ? cheriot_rf_we_q : rf_we_wb_q) & wb_valid_q;

// Nguồn 1: dữ liệu load từ LSU
rf_wdata_wb_mux[1]    = rf_wdata_lsu_i;
rf_wdata_wb_mux_we[1] = rf_we_lsu_i;

// Mux OR one-hot
rf_wdata_wb_o = ({32{rf_wdata_wb_mux_we[0]}} & rf_wdata_wb_mux[0]) |
                ({32{rf_wdata_wb_mux_we[1]}} & rf_wdata_wb_mux[1]);
rf_we_wb_o    = |rf_wdata_wb_mux_we;

// Capability
rf_wcap_wb = (wb_is_cheriot_q && ~wb_cheriot_load_q) ? cheriot_rf_wcap_q : NULL_CAP;
rf_wcap_wb_o = rf_wdata_wb_mux_we[0] ? rf_wcap_wb
             : (rf_wdata_wb_mux_we[1] ? rf_wcap_lsu_i : NULL_CAP);
```

Assertion `RFWriteFromOneSourceOnly`: `$onehot0(rf_wdata_wb_mux_we)`.

**Lý do tách hai nguồn:** `rf_wdata_lsu_i` đến từ `data_rdata_i` qua logic căn chỉnh —
rất muộn trong chu kỳ. Đưa nó qua flop WB sẽ thêm 1 chu kỳ trễ cho mọi load. Thay vào đó,
LSU ghi **trực tiếp** vào register file (`rf_we_lsu_i` bypass thanh ghi WB).

Với `CLC`, capability đến từ `rf_wcap_lsu_i` (LSU đã ghép từ 2 word); với các lệnh
CHERIoT khác, từ `cheriot_rf_wcap_q`. Điều kiện `~wb_cheriot_load_q` đảm bảo không xung đột.

---

## 5. Forwarding và hazard

`ibex_wb_stage.sv:190-217`

```systemverilog
rf_write_wb_o = wb_valid_q & (rf_we_wb_q | (wb_is_cheriot_q & cheriot_rf_we_q)
                            | (wb_instr_type_q == WB_INSTR_LOAD) | wb_cheriot_load_q);

outstanding_load_wb_o  = wb_valid_q & ((wb_instr_type_q == WB_INSTR_LOAD)  | wb_cheriot_load_q);
outstanding_store_wb_o = wb_valid_q & ((wb_instr_type_q == WB_INSTR_STORE) | wb_cheriot_store_q);

rf_wdata_fwd_wb_o = wb_is_cheriot_q ? cheriot_rf_wdata_q : rf_wdata_wb_q;
rf_wcap_fwd_wb_o  = wb_is_cheriot_q ? cheriot_rf_wcap_q  : NULL_CAP;
```

### 5.1 `rf_write_wb_o` — "WB sẽ ghi vào RF"

Bao gồm **cả** trường hợp load đang chờ dữ liệu (`WB_INSTR_LOAD`) — dù lúc này
`rf_wdata_fwd_wb_o` chưa có giá trị đúng. Điều này an toàn vì:
* Nếu lệnh ID đọc thanh ghi đó → `stall_ld_hz` chặn nó thực thi (do `outstanding_load_wb`).
* Nếu không đọc → không quan tâm.

### 5.2 `rf_wdata_fwd_wb_o` là `rf_wdata_wb_q`, **không** phải `rf_wdata_wb_o`

Comment (`ibex_wb_stage.sv:213-215`):
> "The flopped `rf_wdata_wb_q` is used rather than `rf_wdata_wb_o` as the latter includes
> read data from memory that returns too late to be used on the forwarding path."

Đây là lý do load-use hazard phải **stall** thay vì forward.

---

## 6. Bộ đếm hiệu năng

`ibex_wb_stage.sv:206-213`

```systemverilog
perf_instr_ret_wb_spec_o            = wb_count_q & wb_valid_q;
perf_instr_ret_compressed_wb_spec_o = perf_instr_ret_wb_spec_o & wb_compressed_q;

perf_instr_ret_wb_o                 = instr_done_wb_o & wb_count_q
                                    & ~(lsu_resp_valid_i & lsu_resp_err_i);
perf_instr_ret_compressed_wb_o      = perf_instr_ret_wb_o & wb_compressed_q;
```

**Bản `_spec`** (suy đoán) được dùng bởi `ibex_cs_registers` để lệnh CSR đang ở ID đọc
được giá trị `minstret` "đã bao gồm lệnh đang ở WB":

```systemverilog
// ibex_cs_registers.sv:1652-1660
mhpmcounter[2] = instr_ret_spec_i & ~mcountinhibit[2] ? minstret_next : minstret_raw;
```

Nếu lệnh ở WB sau đó bị exception, giá trị suy đoán sai — nhưng khi đó ID stage bị flush
nên lệnh đọc CSR cũng không retire. Tương tự cho `mhpmcounter[10]` (compressed).

**Bản chính** loại trừ lệnh bị lỗi bộ nhớ (`lsu_resp_err_i`).

---

## 7. Dummy instruction trong WB

`ibex_wb_stage.sv:222-245`

```systemverilog
always_ff: if (en_wb_i) dummy_instr_wb_q <= dummy_instr_id_i;
assign dummy_instr_wb_o = dummy_instr_wb_q;
```

`dummy_instr_wb_o` đi tới `ibex_register_file_ff.dummy_instr_wb_i`, cho phép ghi vào
thanh ghi vật lý x0. Assertion cấp `ibex_top` (`ibex_top.sv:1602`):
```systemverilog
`ASSERT(WaddrAZeroForDummyInstr, dummy_instr_wb && rf_we_wb |-> rf_waddr_wb == '0)
```

---

## 8. Nhánh bypass (`WritebackStage = 0`)

`ibex_wb_stage.sv:248-300` — **[TẮT]** trong cấu hình này, nhưng để đối chiếu:

```systemverilog
rf_waddr_wb_o         = rf_waddr_id_i;
rf_wdata_wb_mux[0]    = instr_is_cheriot_i ? cheriot_rf_wdata_i : rf_wdata_id_i;
rf_wdata_wb_mux_we[0] = instr_is_cheriot_i ? cheriot_rf_we_i    : rf_we_id_i;
ready_wb_o            = 1'b1;               // luôn sẵn sàng → ID không stall vì WB
outstanding_load_wb_o = 1'b0;
outstanding_store_wb_o= 1'b0;
rf_write_wb_o         = 1'b0;               // không có forwarding
rf_wdata_fwd_wb_o     = 32'b0;
instr_done_wb_o       = 1'b0;
perf_instr_ret_wb_o   = instr_perf_count_id_i & en_wb_i & ~(lsu_resp_valid_i & lsu_resp_err_i);
```

---

## 9. Ảnh hưởng của WB stage lên timing lệnh

| Lệnh | Không WB | Có WB (cấu hình này) |
|---|---|---|
| ALU | 2 chu kỳ (IF+ID) | 3 chu kỳ (IF+ID+WB), **thông lượng vẫn 1 IPC** |
| `LW` rồi lệnh độc lập | LW chiếm ID tới khi rvalid | LW sang WB ngay, lệnh sau chạy song song |
| `LW x1,..` rồi `ADD ..,x1,..` | 2 lệnh nối tiếp | stall 1+ chu kỳ (`stall_ld_hz`) |
| `SW` rồi lệnh độc lập | SW chiếm ID | SW sang WB, lệnh sau chạy ngay |
| `SW` rồi `LW` | nối tiếp | LW phải chờ (`outstanding_memory_access` → `data_req_allowed = 0`) |
| Exception bộ nhớ | Trong ID/EX | Trong WB, cần `csr_save_wb_o` và `pc_wb_o` |

Về exception, `ibex_controller.sv:834-843`:
```systemverilog
csr_save_id_o = ~(store_err_q | load_err_q | (cheriot_on & cheriot_wb_err_q));
csr_save_wb_o =   store_err_q | load_err_q | (cheriot_on & cheriot_wb_err_q);
```
→ `mepc` lấy từ `pc_wb_i` thay vì `pc_id_i` khi exception đến từ WB
(`ibex_cs_registers.sv` chọn `exception_pc` theo `csr_save_if/id/wb_i`).
