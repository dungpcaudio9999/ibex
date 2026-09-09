# Module — ibex_cheriot_ex

BASE-01; [EX source](../../../rtl/ibex_cheriot_ex.sv), [package](../../../rtl/ibex_cheriot_pkg.sv), [decoder](../../../rtl/ibex_decoder.sv). Branch core `g_cheriot_ex` khi BaseIsa dual. Phân tích boundary/authorization/data-state, **chưa kiểm chứng đầy đủ ISA hoặc tất cả phép toán compressed bounds**.

## Datapath và interfaces

Đầu vào hai RF data+cap, WB data+cap forwarding, decoded operator/immediates/selects, PCC/PC và capability CSR. Outputs integer result+capability, branch target/PCC update, local error, LSU request/type/data/cap và CSR side effects. RV32 LSU path được mux qua để áp dụng mode-dependent checks.

Package `cap_t`=35 bits: 2 correction, valid tag, reserved, 6 compressed permissions, 3 otype, 4 cexp, 9 top, 9 base. Working `decoded_cap_t`=112 bits, thêm top33/base32/12 permissions. Integer pointer32 tách khỏi cap_t. Memory form dùng pointer word + metadata32/tag, không lưu trực tiếp toàn bộ112 bits.

Numeric operations gồm decode/encode permissions, expand exponent (compressed15→expanded24), bound correction/expand33 và setbounds. Top bound dùng 33-bit để biểu diễn biên vượt 32-bit; truncate sai có thể biến overflow thành quyền truy cập hợp lệ. Những hàm này cần oracle ISA độc lập, không test bằng copy cùng hàm.

## State và completion

Phần lớn EX tính combinational. State quan trọng tại đây gồm cheriot_wb_err_q/info_q reset0; WritebackStage chọn flopped error hoặc direct d. Data/cap result được ID/WB stage khác giữ. Controller/ID bảo đảm instruction executing/valid và không tái phát side effects do stalls.

`cheriot_ex_err_o` được gate bởi cheriot_exec_id và !debug_mode. LSU permission/bounds error được gửi qua lsu_cheriot_err tới local response path, không cần external data request. `lsu_req_o` chọn CHERIoT/RV32 theo instr_is_cheriot; opcode-valid và runtime enable vẫn cần decoder/ID enforcement. Không kết luận mọi opcode bất kỳ đều bị chặn chỉ từ một gate.

## Invariants, corner và limits

`INV-capex-01`: instruction không có quyền không được tạo architectural memory side effect. INFERRED composition permission checks→LSU local-error→controller/WB suppression; cần test cả bad tag, bounds, permission, sealing, alignment, CSR SR, debug mode. Bitmap revocation là cơ chế sau load ở TRVK, không phải cùng check ở EX.

`INV-capex-02`: forwarding integer value và metadata phải đến từ cùng destination instruction. INFERRED, kiểm WB0/WB1, dependent capability jump/load/setbounds, lỗi WB đụng younger EX. Không có run chứng minh.

Corner số học ưu tiên: base/top boundaries, wrap ở2^32, exact/inexact setbounds, exponent15/24, zero length, permission compression, sentry changes MIE/PCC và reserved encodings. Latency/path critical phải đo synthesis; comment “one-cycle” của non-load/store error path chỉ là giả định thiết kế scoped, không universal ISA throughput.

Chưa có normative CHERIoT ISA revision/model được chạy cho checkout; package comment nhắc spec v1.0 nhưng đó không phải compliance proof. FND-CHERI-01/SEC-01, OQ-06/07/09. Sửa cap_t/helper cần rebaseline RF/CSR/LSU/TRVK/ECC/lockstep/tracer/ISS/tests cùng nhau.
