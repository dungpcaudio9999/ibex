# 07 — Load-store unit và writeback

## 1. Phân chia trách nhiệm

`ibex_load_store_unit` chịu trách nhiệm:

- đổi request kiến trúc thành bus address phases;
- tạo byte enable và align write data;
- tách access lệch hàng thành hai giao dịch;
- ghép/sign-extend load response;
- encode/decode memory integrity;
- truyền capability qua hai word 32 bit;
- tổng hợp bus/PMP/integrity/CHERIoT error.

`ibex_wb_stage` chịu trách nhiệm:

- giữ ownership của instruction sau ID/EX;
- chờ load/store response;
- chọn nguồn RF write;
- cung cấp forwarding;
- phát retirement pulses.

## 2. Data-side protocol

Address phase:

```text
data_req_o + address/control -> data_gnt_i
```

Response phase:

```text
data_rvalid_i + data/error/tag
```

Grant không phải response. LSU lưu control cần thiết sau grant vì response có
thể về nhiều chu kỳ sau và input decode lúc đó đã thuộc instruction khác.

## 3. Byte enable và alignment

Địa chỉ xuất ra bus luôn word aligned; `data_be_o` chọn byte hữu hiệu. Với word
hoặc halfword lệch biên, phần đầu và phần sau có byte-enable khác nhau.

Write data được rotate theo `data_addr[1:0]`. Load data dùng saved offset/type và
phần dữ liệu đầu tiên để realign, sau đó sign- hoặc zero-extend.

Capability access luôn word aligned ở từng beat và dùng byte-enable `1111`.

## 4. LSU main FSM

Các state:

| State | Ý nghĩa |
|---|---|
| `IDLE` | nhận request mới hoặc chờ response cuối |
| `WAIT_GNT_MIS` | chờ grant phần đầu access lệch |
| `WAIT_RVALID_MIS` | chờ response phần đầu, đồng thời có thể phát phần hai |
| `WAIT_GNT` | chờ grant request thường/phần hai |
| `WAIT_RVALID_MIS_GNTS_DONE` | phần hai đã grant, còn chờ response phần đầu |
| `CTX_WAIT_GNT1` | capability beat 1 chưa grant |
| `CTX_WAIT_GNT2` | phát/chờ grant capability beat 2 |
| `CTX_WAIT_RESP` | cả beat đã grant, chờ response còn lại |

FSM cho phép overlap hợp lệ giữa response phần đầu và grant phần hai. Đây là
nguồn dễ gây off-by-one khi sửa protocol.

## 5. Access lệch hàng

Ví dụ load word tại địa chỉ `A...01`:

1. request word-aligned `A...00`, lấy byte 1..3;
2. lưu phần response đầu;
3. yêu cầu ID/EX tăng effective address;
4. request `A...04`, lấy byte 0;
5. ghép thành 32-bit theo little endian;
6. chỉ báo response khi đủ cả hai phần.

PMP được kiểm riêng cho từng địa chỉ. Nếu phần hai fault, `addr_last_o` phải chỉ
đúng địa chỉ gây lỗi để đưa vào `mtval`.

## 6. PMP error khác bus error

PMP error có thể chặn request trước khi external bus grant. Vì vậy LSU không
được chờ một grant/response sẽ không bao giờ tới. Nó lưu `pmp_err_q` và coi đó
như completion có lỗi trong FSM.

Bus error đi cùng response; integrity error được tính từ data+check bits. Các
nguồn cuối được gộp nhưng vẫn có output riêng để controller phân loại load/store
và lỗi integrity response.

## 7. Capability load/store hai beat

Capability memory representation dài 64 bit trên bus 32 bit:

- beat 1 chứa pointer/data word;
- beat 2 chứa metadata nén;
- tag đi kèm để xác định capability hợp lệ.

Main LSU FSM quản lý request; `cap_rx_fsm` song song quản lý response:

```text
CRX_IDLE -> CRX_WAIT_RESP1 -> CRX_WAIT_RESP2 -> CRX_IDLE
```

LSU lưu word/tag/error đầu, nhận word thứ hai rồi gọi conversion function để tạo
`cap_t`. Permission của capability vừa load có thể bị giảm theo authority của
load (`CTAG`, `SD_LM`, `GL_LG`).

Invariant quan trọng: hai response của một capability phải liên tiếp, đúng thứ
tự và thuộc cùng requester theo assumption của thiết kế/integration.

## 8. Memory integrity

Nếu `MemECC=1`:

- store data đi qua `prim_secded_inv_39_32_enc`;
- load response đi qua decoder 39/32;
- uncorrectable/correctable indication được đưa vào error/alert path theo thiết
  kế.

Nếu tắt, datapath chỉ còn 32 bit và integrity logic bị generate out. Đối với FX1
DEV/PROD, verification cần có testcase riêng chứng minh tie-off và external bus
mapping đúng.

## 9. `lsu_req_done` và `lsu_resp_valid`

Hai tín hiệu không đồng nghĩa:

- `lsu_req_done`: LSU đã nhận đủ request/address phases để ID có thể nhường
  instruction cho WB;
- `lsu_resp_valid`: toàn bộ operation đã có response hoặc fault và có thể kết
  thúc kiến trúc.

WB stage cho phép hai mốc tách nhau. Không có WB stage, ID phải giữ instruction
đến `lsu_resp_valid`.

## 10. WB valid/ready

Khi WB bật:

```text
wb_valid_d = (en_wb && ready_wb) || (wb_valid && !wb_done)
ready_wb   = !wb_valid || wb_done
```

- `OTHER` thường done ngay trong một chu kỳ;
- load/store giữ WB đến `lsu_resp_valid`;
- CHERIoT load/store cũng giữ WB kể cả decoder classification ban đầu khác.

WB full tạo back-pressure về ID qua `ready_wb`.

## 11. RF write mux

Có hai nguồn:

1. result đã lưu từ ID/EX hoặc CHERIoT EX;
2. load data/capability trực tiếp từ LSU.

Assertion `RFWriteFromOneSourceOnly` yêu cầu one-hot-or-zero. Nếu hai nguồn cùng
enable, OR mux sẽ che giấu lỗi logic bằng data trộn; assertion là bắt buộc.

## 12. Forwarding limitation

WB forward result đã flop của ALU/CSR/CHERIoT về ID. Load response không dùng
đường forward này vì data từ memory về quá muộn trong chu kỳ; load-use phải
stall và RF nhận data trước.

`rf_write_wb` vẫn lên cho outstanding load để hazard detector biết destination
sẽ được ghi trong tương lai.

## 13. Retirement

`instr_done_wb` lên khi WB valid và operation done. Performance counter chỉ tăng
khi instruction được đánh dấu countable và không kết thúc bằng LSU error.

Các speculative retire counters được dùng khi instruction hiện tại đọc counter
để giá trị thấy được phù hợp với thứ tự kiến trúc, dù pulse retire thật xảy ra ở
cuối chu kỳ.

## 14. `ResetAll` trong WB

- `wb_valid_q` luôn reset;
- với `ResetAll=1`, toàn bộ payload WB reset về giá trị xác định;
- với `ResetAll=0`, payload chỉ được ghi khi `en_wb`, còn valid=0 ngăn sử dụng
  payload chưa khởi tạo.

Trong lockstep, cần kiểm tra hai core không so sánh payload invalid trước khi
được ghi đồng nhất.

## 15. Tín hiệu nên xem

```text
lsu_req_i, data_req_o, data_gnt_i, data_rvalid_i
ls_fsm_cs, cap_rx_fsm_q
data_addr_o, data_be_o, data_we_o
handle_misaligned_q, addr_incr_req_o, addr_last_o
pmp_err_q, lsu_err_q, data_intg_err
lsu_req_done_o, lsu_resp_valid_o, lsu_rdata_valid_o
wb_valid_q, wb_instr_type_q, wb_done, ready_wb_o
outstanding_load_wb_o, outstanding_store_wb_o
rf_wdata_wb_mux_we, rf_we_wb_o, instr_done_wb_o
```

## 16. Điểm vào source

- [`rtl/ibex_load_store_unit.sv`](../../../rtl/ibex_load_store_unit.sv)
- [`rtl/ibex_wb_stage.sv`](../../../rtl/ibex_wb_stage.sv)
- [`rtl/ibex_cheriot_pkg.sv`](../../../rtl/ibex_cheriot_pkg.sv)

