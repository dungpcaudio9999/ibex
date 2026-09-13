# Hoàn tất kế hoạch microarchitecture — đợt bổ sung

Yêu cầu người dùng: hoàn tất các phần còn lại của PLAN.md rồi lập và triển khai
kế hoạch Secure Ibex. Giữ nguyên evidence đợt 1; evidence mới ở `evidence/extended/`.

| Mục còn thiếu | Công việc bổ sung | Điều kiện kết luận |
|---|---|---|
| Cache/predictor/Zcb/Zcmp | Instantiate top có RAM thật; directed hit/miss/invalidate, prediction/mispredict, compressed expansion | Kiểm kết quả + activity counters, phân tích cycle và state |
| Fetch error/reset outstanding | Inject instruction error; reset theo epoch memory contract | Kiểm trap PC/mtval, restart và không dùng response epoch cũ |
| Debug/IRQ/WFI | DRET, simultaneous debug/IRQ, NMI/return, sleep rồi wake ở top clock gate | Kiểm CSR/PC ordering và sleep/clock activity |
| CHERIoT end-to-end | Dual top, tagged data memory/bitmap, instruction stream hợp lệ và faults | Decoder→EX→LSU→TRVK→RF/trap có evidence |
| Throughput/branch penalty | Cửa sổ hữu hạn, loại loop termination, stall ownership | Không cộng counters chồng nhau; ghi rõ metric |
| Các nhánh bảo vệ | Xác định parameter thực tế và active paths | Chuyển phần chuyên sâu và injection sang plan Secure Ibex |

PPA/STA/CDC vật lý, exhaustive ISA conformance và formal closure không nằm trong
mục tiêu được cam kết của PLAN.md. Phải ghi ranh giới kỹ thuật của chúng, không
tự đổi thành yêu cầu tapeout. Các test khó vẫn phải thử triển khai; nếu phát hiện
RTL defect thì giữ evidence FAIL và phân tích nguyên nhân, không sửa RTL ngầm để
đánh dấu PASS. Mỗi hàng sẽ được đối chiếu trong báo cáo hoàn tất cuối đợt.

Trạng thái: đã hoàn tất các hàng ở mức phân tích/source và directed validation
được cam kết. [Báo cáo closure](13_completion_results.md) ghi test, cycle và giới hạn;
[Secure plan](../secure_ibex/PLAN.md) tiếp nhận và triển khai chuyên sâu các đường bảo vệ.
