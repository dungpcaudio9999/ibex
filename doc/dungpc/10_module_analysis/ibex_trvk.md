# Module — ibex_trvk

BASE-01; [source](../../../rtl/ibex_trvk.sv), [PULP fork](../../../vendor/pulp_common_cells/rtl/stream_fork.sv), [join](../../../vendor/pulp_common_cells/rtl/stream_join_dynamic.sv), [FIFO](../../../vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_sync.sv). Top instantiate NumOutstanding=2, RevBitmapAddrWidth=11, base0, MemECC từ top. Module standalone default NumOutstanding=4 không phải value tại top.

## Trách nhiệm, state và invariant accounting

TRVK interposes data bus để clear tag của loaded capability đã revoked. Payload/error downstream forward; bitmap result ảnh hưởng tag và error alert riêng.

| State | Update/reset | Ý nghĩa contract |
|---|---|---|
| Alignment FIFO, Width1/Depth2/Pass0 | Push fork-accepted addr[2], pop upstream response; reset empty | Một entry cho mỗi accepted word access |
| Response FIFO, Pass1/Depth2 | Push downstream rvalid, pop khi join ready; reset empty | Giữ response khi bitmap chưa tới; external response không có ready |
| ptr_storage_q/valid_q | Capture tagged aligned response khi trả upstream; reset0 | Low capability word dùng ghép metadata word sau |
| revbm_outstanding_q | Set req&&gnt, clear response accepted, clear priority; reset0 | Chỉ một lookup, không phát lặp sau grant |
| Fork internal state | Nhớ nhánh đã handshake | Tránh gửi trùng khi alignment/downstream nhận khác cycle |

`INV-trvk-01`: delivered upstream response có alignment entry; nguồn AlignValidOnRsp_A. `INV-trvk-02`: downstream rvalid không overflow response FIFO; DsRspFifoNoOverflow_A. Hai statement là safety obligations chưa proof; cần accounting fork/outstanding/reset để discharge, không chỉ nhìn equal FIFO depths.

## Lookup và tag

Pointer response phải tagged và addr[2]=0. Word tiếp tagged addr[2]=1, pointer_valid, response_valid, non-sealing và cap_base trong bitmap range tạo revbm_req_required. Fork giữ metadata identity; bitmap address=`base + word_index*4`, bit_select từ heap offset/8 mod32.

`revbm_revoked = selected_bit | revbm_err | any_ECC_error`. `upstream_tag=(revbm_rvalid ? !revoked : 1) & response.tag`. Vì rvalid bitmap có thể tác động tag ngay, unsolicited bitmap response là vi phạm contract, không được bỏ qua như “response không match ID”. upstream_err chỉ theo downstream err; bitmap lỗi không tự chuyển thành bus-error cho capability load.

**FND-CHERI-02:** Top TRVK có hai alignment/response slots nhưng chỉ một bitmap outstanding; hai response capability phải consecutive, in-order, pointer trước metadata. **Support:** SUPPORTED [RTL:ESTABLISHED], BASE-01 TRVK/ibex_top:1275; ASM-CAP-01/02. Mất bitmap service có thể giữ metadata response vô hạn; eventual service không bảo đảm một fixed latency.

## Quantitative và parameter boundaries

Width11→word-address-width9, 512×32 bits=2 KiB bitmap→128 KiB heap. ASSERT_INIT yêu cầu word-address width trong1…26, tương đương byte-address width3…28; bitmap base word-aligned, heap base 8-byte aligned. Không kiểm exhaustively mọi legal NumOutstanding/depth/width; zero/one-depth variants cần verify primitive semantics khi dùng.

`Pass1` response FIFO có bypass, `Pass0` alignment FIFO có state latency riêng; earliest upstream response còn phụ thuộc alignment-valid và lookup. Không đặt latency cố định cho mọi capability load. Out-of-range/sealing bỏ lookup, không tự zero tag.

## Test/property plan và change impact

Chưa chạy SVA/RTL. Cần witnesses tagged low/high pair, stalled second word, FIFO full, simultaneous pop/push, bitmap grant delayed, bit0/31, base/end/range underflow, ECC single/double errors, reset khi lookup pending; negative unsolicited response và mixed pair phải bị checker phát hiện. `RevbmRspOnlyWhenOutstanding_A` đặt contract response sau grant, không zero-latency bitmap.

Nếu thay capacity, downstream throughput hoặc pair protocol, phải xem fork partial-handshake state và FIFO overflow khi bitmap dừng; nếu đổi heap map phải đồng bộ revocation writer/firmware/memory tags. Nếu thay error policy phải cập nhật tag oracle, LSU fault behavior, top alerts và security requirements. OQ-01/05/06/07/12; FLOW-CAP-01.
