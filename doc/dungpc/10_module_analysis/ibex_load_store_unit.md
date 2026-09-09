# Module — ibex_load_store_unit

BASE-01; [source](../../../rtl/ibex_load_store_unit.sv). Core→LSU nhận req/type/sign/addr/data/cap; external bus req/gnt/rvalid; outputs riêng req_done, resp_valid, rdata_valid và errors. Params BaseIsa/MemECC/MemDataWidth, runtime MuBi. Flows LSU/CAP/ERR.

## State và ownership

| State/register | Chức năng |
|---|---|
| ls_fsm_cs/ns | Address-phase/split/capability request sequencing |
| addr_last_q | Fault address/AGU base cho phần thứ hai |
| data_we/type/sign/offset q | Metadata gắn response với instruction |
| rdata_q[31:8] | Fragment để realign load, không là FIFO response tổng quát |
| handle_misaligned_q | Request thứ hai/offset sequencing |
| pmp_err_q/lsu_err_q/cheriot_err_q | Lỗi được ghi nhớ qua các phần |
| resp_is_cap/resp_lc_clrperm | Capability/permission conversion response context |
| cap_rx_fsm | CRX_IDLE → WAIT_RESP1 → WAIT_RESP2 |
| cap_lsw_data/tag/err | Low capability word để kết hợp high word |

FSM/reset/cap-response/error state reset explicit về IDLE/zero. Control/payload registers khác cần xét enable/valid, không dùng idle như data-valid.

## FSM chính

- IDLE nhận architectural request; aligned được grant có thể vẫn next=IDLE mặc dù đang chờ final response. Local CHERIoT error đặt error context mà không phát data_req.
- WAIT_GNT giữ request aligned; WAIT_GNT_MIS chờ grant1 split; WAIT_RVALID_MIS vừa chuẩn bị second request vừa chờ response1.
- Nếu grant2 đến trước response1 → WAIT_RVALID_MIS_GNTS_DONE; nếu response1 trước grant2 → WAIT_GNT; khi phần address cần thiết xong → IDLE và chờ final response ở pipeline.
- CTX_WAIT_GNT1/CTX_WAIT_GNT2/CTX_WAIT_RESP sequencing hai word capability; cap_rx_fsm riêng đánh dấu response1/response2. Các state CTX có nhánh khi mode Off, vì vậy mode switch khi outstanding là OQ-07 chứ không một transaction-cancel contract được chứng minh.

## Datapath và corner

Word misaligned khi offset!=0; halfword split chỉ offset=3; byte không split. External addr luôn align word. Byte-enable/rotate chọn những lane chứa dữ liệu; response sign/zero-extend theo type. Capability load lắp pointer + metadata/tag bằng package function; lỗi word đầu phải đi cùng word sau, không mất khi latencies khác nhau.

`data_or_pmp_err` kết hợp remembered bus/PMP/CHERIoT errors; `lsu_resp_valid=all_resp & state==IDLE`. `lsu_rdata_valid` thêm !store,!error,!integrity_error. `load_resp_intg_err`/store integrity path riêng để tránh feedthrough critical từ rdata→data_req theo comment nguồn. Lỗi bus phần đầu split vẫn phải drain giao dịch phần sau; không có atomic rollback.

## INV-lsu-01 và INV-lsu-02

`INV-lsu-01`: `data_req -> data_addr[1:0]==0`. SUPPORTED từ assign và assertion `IbexDataAddrUnaligned`, chưa FORMAL proof/run. Áp dụng defined input controls, BASE-01 mọi nhánh phát req.

`INV-lsu-02`: accepted architectural request có đúng final completion/data hoặc error, không lẫn context với instruction sau. INFERRED composition LSU + ID/WB. Giả định ASM-BUS-01/RST-01/MODE-01; capacity tối đa hai bus beats không phải hai architectural instructions tự do. Kiểm accepted count, response order, low/high tag/data và reset discard count độc lập với FSM DUT.

Busy chỉ `(ls_fsm_cs != IDLE)` nên không làm sole outstanding monitor. No bound nếu gnt/rvalid vắng. Không dùng model timer/address EVD-06 làm bằng chứng LSU chạy.

## Checks và change impact

Nguồn có type/offset-known, legal-state, addr-aligned và “cap disabled when mode Off” assertions. Trigger/activation đều NOT-RUN; cần cover tất cả ordering grant2/response1, delayed grant, first/second errors, PMP split across boundary, BE/sign types, capability revoked/bad tag và reset ở từng FSM.

Đổi req_done, error suppression, split hoặc MemDataWidth ảnh hưởng ID/WB, EX AGU, controller mtval, TRVK alignment slots, RVFI memory metadata, ISS memory notification và firmware MMIO safety. Phải retest WB0/WB1, BaseIsa RV32I/dual runtime Off/On, ECC Off/On. OQ-01/05/06/07/12.
