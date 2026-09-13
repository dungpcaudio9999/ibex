# Instrumentation thử nghiệm, không phải evidence PASS của production

Harness `top_tb_with_forced_rmw.sv` có force vào `hit_data_ecc_ic1`, nơi RTL dùng
always_comb và phép `|=`. Log/VCD no-fault `secure_cache.cache` xuất hiện minor
cycle277, internal279. VCD tại2765ns có hit-data bằng OR giá trị trước với giá
trị hiện tại dù raw RAM/tweak đúng. Đây là artifact được dùng để xác định vì sao
không thể dùng baseline đó cho fault-injection coverage.

Trước thử nghiệm này, force trực tiếp `ic_data_rdata[0]` gây C++ compilation
failure trên Verilator5.020. Signature quan sát từ tool output:
`cannot convert 'VlUnpacked<VlWide<3>, 2>' to 'WDataOutP'`.
Full build log của lần array-force đó đã bị runner ghi đè khi đổi điểm inject;
không coi build log hiện có trong thư mục này là log nguyên gốc của array failure.

Harness cuối đã chuyển force tới packed scrambled RAM `data_bank.rdata_o`;
no-fault control và fault10 cuối nằm ở thư mục cha, có source snapshot riêng.
Các artifact ở đây giữ giá trị lịch sử và không được tính là lỗi RTL xác nhận.
