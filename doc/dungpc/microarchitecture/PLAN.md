# Kế hoạch phân tích microarchitecture Ibex

Ngày lưu: 2026-09-13. Người dùng đã yêu cầu lưu và thực hiện kế hoạch trong hội thoại.

## Mục tiêu và phương pháp

Dựng lại cách một instruction đi qua CPU ở từng chu kỳ; giải thích datapath,
FSM và control làm instruction chạy tiếp, stall, bị hủy hoặc cập nhật architectural
state. Kế thừa phân tích tổng quan trong `../`, nhưng đối chiếu lại RTL hiện tại.

## 1. Cấu hình nền

Bắt đầu từ `small`: BaseIsaRV32I, RV32MFast, Zca, register file FF,
pipeline hai tầng, không cache/predictor/PMP/SecureIbex. Xác nhận parameter từ
build/top đến module; không coi YAML là bằng chứng elaboration.

Đối chiếu từng biến thể: WB stage, BranchTargetALU, multiplier, cache/predictor,
Zcb/Zcmp, CHERIoT và SecureIbex; xem riêng các tương tác giữa tính năng.

## 2. Thứ tự phân tích

| Bước | Phạm vi | Câu hỏi phải trả lời |
|---|---|---|
| A | Pipeline/state: core, IF/ID, ID/EX, WB | Instruction và PC/operand/result nằm ở đâu; valid/ready; hoàn tất và side effect |
| B | IF, prefetch, FIFO, compressed decoder | PC selection, outstanding requests, ghép 16/32-bit, discard response sau redirect |
| C | Decoder, RF, operand mux, ALU, EX, mult/div | Opcode→control, chia sẻ tài nguyên, intermediate state và completion |
| D | ID FSM, stall, forwarding, WB | ALU dependencies, load-use, load-branch; khác biệt hai/ba tầng |
| E | LSU | AGU, byte enable, split access, grant/response, lỗi từng transaction |
| F | Controller, CSR, branch, trap, IRQ, debug, WFI | Priority, trap PC, flush, side effects của instruction trẻ |
| G | BranchTargetALU, mult/div variants, I-cache/predictor, Zcb/Zcmp | Đổi datapath/state/latency; expansion và interrupt/exception boundary |
| H | CHERIoT RF/EX/PCC/CSR/LSU/TRVK, PMP/ECC/lockstep | Metadata, bounds/permission/tag, revocation, fault handling |

## 3. Đầu ra mỗi phần

- Sơ đồ datapath/control với mux, register, feedback và control quan trọng.
- Bảng state/FSM: ý nghĩa, reset, update/hold/clear, transition và priority.
- Phương trình điều khiển cốt lõi, diễn giải từ RTL.
- Bảng chu kỳ: PC/instruction, handshake, stall, RF/memory side effect, retirement.
- Corner cases và invariants, tách kết luận nguồn khỏi điều cần kiểm chứng.
- Dẫn chứng file/dòng nguồn và cấu hình áp dụng.

## 4. Kiểm chứng

Viết dự đoán từ RTL trước, rồi đối chiếu mô phỏng các tình huống nhỏ: ALU độc lập
và phụ thuộc; load-use và load/store liên tiếp; grant/response chậm; branch/JAL/JALR;
redirect khi fetch outstanding; compressed vượt word; mult/div và toán hạng biên;
misalignment và bus error từng transaction; IRQ/debug khi memory/multdiv chờ;
capability/tag/permission/revocation khi có harness phù hợp.

Mỗi kết quả ghi cấu hình, memory contract, lệnh, log, waveform và giới hạn.
Phân biệt SOURCE (đọc RTL), INFERRED (suy luận), SIM (đã chạy), NOT-RUN.
Kiểm tra assertion activation; không dùng Python model như RTL simulation.
Simple System không mặc nhiên là harness CHERIoT: cần tagged memory và bitmap.

## 5. Tổng hợp

Lập bảng latency, throughput, branch penalty, stall sources theo cấu hình.
Giải thích trade-off cấu trúc. Không đưa Fmax/area đo được nếu chưa synthesis với
điều kiện đo thích hợp.

## 6. Deliverables và mốc review

Lưu tại `doc/dungpc/microarchitecture/`: README, các chương, sơ đồ, timing tables,
evidence và scripts/harness/lệnh/log/waveform.

1. Cấu hình nền + pipeline + fetch: mô hình và mẫu độ sâu.
2. Execution + hazard/WB + LSU + controller: luồng RV32I hoàn chỉnh.
3. Biến thể + CHERIoT/bảo vệ + hiệu năng: phạm vi source hoàn chỉnh.

Các mốc là điểm tổ chức/review tài liệu; yêu cầu tiếp theo của người dùng đã cho
phép thực hiện toàn bộ kế hoạch, không yêu cầu chờ duyệt lại giữa các đợt.

## Trạng thái hoàn tất

Toàn bộ chủ đề A–H đã được phân tích. [Đợt bổ sung](13_completion_results.md)
đối chiếu từng mục, bổ sung21 top runs và [throughput/branch penalty](14_throughput.md).
Phân tích chuyên sâu bảo vệ theo [Secure Ibex plan](../secure_ibex/PLAN.md).
