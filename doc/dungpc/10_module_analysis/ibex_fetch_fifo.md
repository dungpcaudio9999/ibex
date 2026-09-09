# Module — ibex_fetch_fifo và ibex_prefetch_buffer

BASE-01, ICache=0, DII_SIM không bật trong lập luận. Nguồn [FIFO](../../../rtl/ibex_fetch_fifo.sv), [prefetch](../../../rtl/ibex_prefetch_buffer.sv), [IF](../../../rtl/ibex_if_stage.sv). Chức năng: tách bus fetch word khỏi delivery instruction và giữ đúng PC/error qua stall/branch.

## State và phương trình

| State | Ý nghĩa/update | Reset |
|---|---|---|
| valid_req_q/stored_addr_q | Request chưa grant, giữ payload bus | Valid0; address tùy ResetAll |
| fetch_addr_q | Địa chỉ phát tiếp theo, redirect hoặc +4 | Tùy ResetAll, boot branch khởi tạo |
| outstanding[1:0] | Grant đã nhận, chưa response | 0 |
| discard_req/branch_discard | Gắn canceled-path với response phải drain | 0 |
| FIFO valid_q[2:0] | Word buffer hiện có | 0, clear có priority |
| rdata_q/err_q | Word và lỗi đi cùng entry | Tùy ResetAll; có nghĩa khi valid |
| instr_addr_q | PC instruction đầu FIFO, +2/+4 khi consume | Tùy ResetAll, clear nhận in_addr |

Prefetch NUM_REQS=2; FIFO DEPTH=3. `fifo_ready=~&(fifo_busy | reversed_outstanding)` trừ chỗ dự trữ cho response chưa về. `valid_new_req=req_i & (fifo_ready | branch_i) & ~outstanding[1]`. Phải phân biệt “chưa grant” và “đã grant chưa response”.

FIFO có bypass khi valid_q[0]=0. Instruction 32-bit ở PC[1]=1 cần hai nửa word; compressed có thể chỉ tiêu thụ một nửa và giữ word hợp lệ. `out_valid && out_ready` là delivery instruction, `pop_fifo` là bỏ word; không phải cùng event mọi trường hợp. `err_plus2` phục vụ lỗi nửa sau instruction.

## FND-IF-01 và invariants

**FND-IF-01:** Reservation count=2 nhưng physical FIFO=3 words; clear làm valid_d=0 kể cả có incoming word. **Support:** SUPPORTED [RTL:ESTABLISHED], BASE-01 các localparam/valid_d trên; không extrapolate sang ICache.

`INV-fetch-01`: request chưa grant giữ address/request tới acceptance, kể cả branch. Lập luận: valid_req_q override địa chỉ và stored_addr chỉ capture request mới; discard_req nhớ redirect. Assumptions memory sampling/no reset epoch violation. Source-supported, không formal proof.

`INV-fetch-02`: response của old path không tạo instruction được commit sau redirect. Đây là **INFERRED end-to-end property**, phụ thuộc discard queue, FIFO clear và IF squash/controller flush; không chứng minh chỉ từ fifo_valid. Cần delayed grant/response, simultaneous branch+rvalid, compressed-boundary witness.

## Latency, corner cases và kiểm tra

Bypass có thể đưa word mới tới IF ngay trong cycle response nếu aligned/đủ hai phần và ready; không thêm một storage cycle bắt buộc. Không suy ra zero-cycle external memory response. Dưới full/reservation, request bị chặn; branch có thể bỏ qua fifo_ready nhưng không bỏ qua max outstanding bit. Stall vô hạn hợp lệ nếu môi trường không phục vụ.

Checker nguồn `IbexFetchFifoPushPopFull`, `IbexFetchFifoPushFull` bảo vệ full contract nhưng chưa activation/proof. DII_SIM dùng instruction injected nên không dùng test đó làm bằng chứng fetch RAM; CHERIoT `cheriot_force_uc_i` thay boundary handling. Các thử nghiệm cần cover empty bypass, three-word occupancy, upper-half 32-bit/error, branch+response, reset nonempty và outstanding drain.

Change impact: tăng NUM_REQS đổi reservation, width/tracker/checkers; thay pop/clear ảnh hưởng PC increments, FENCE.I, compressed decode, error PC và RVFI. Flows BOOT/IF/ERR; OQ-01/05/12.
