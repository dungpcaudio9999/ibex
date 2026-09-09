# Module — ibex_register_file_ff

BASE-01; [source](../../../rtl/ibex_register_file_ff.sv), RegFileFF branch ở top. Trách nhiệm: hai read ports combinational, một write port ở cạnh lên; chứa architectural register data và metadata theo mode. Params RV32E/DataWidth/DummyInstructions/BaseIsa/CapWidth/zero values.

## Storage và mode

Plain RV32I/E dùng register array; x0 đọc architectural zero, dummy instructions có cách dùng physical x0 riêng. Dual BaseIsa có `rf_data` cho nửa register thấp và `rf_shared` dùng làm x16–x31 data khi runtime Off hoặc metadata capability khi On. Readcap Off trả CapWordZeroVal; On dùng cap metadata với xử lý x0. Compare runtime mode là đầy đủ MuBiOn, không chỉ bit0.

Với dual, RV32E=0, DummyInstructions=0, DataWidth=32, CapWidth=35: 15 data words ở low GPR, shared x16 có 32-bit special storage, 15 metadata words ×35 bit. Tổng stored data/cap flop bits theo nhánh nguồn là `15*32 + 32 + 15*35 = 1037`, chưa tính decoder/mux/physical overhead. Đây là đếm logical bits của cấu hình cụ thể, **không là area synthesis**. Plain RV32I không dummy là31×32=992 data bits. Các width ECC/dummy/backend khác phải tính lại.

Reset FF branches đặt WordZeroVal/CapWordZeroVal cho storage instantiated. Không áp dụng điều này cho RAM hoặc các pipeline flops không reset, cũng không mặc định latch/FPGA backend tương đương timing.

## Invariants và corner

`INV-rf-01`: architectural x0 đọc zero values cho instruction không dummy, dù dummy storage có thể bị ghi. SUPPORTED có điều kiện từ mux/zero branches; cần distinguish data0 và cap0. Assertion/negative test chưa chạy.

`INV-rf-02`: data và cap write của một architectural destination cùng identity/mode. INFERRED từ decoder/gating, chưa proof. Đổi mode không di chuyển/migrate nội dung shared tự động; data ghi x17 ở RV32I có thể ảnh hưởng storage dùng cap register1 khi switch. Không được coi runtime switch là no-op an toàn. ASM-MODE-01/OQ-07.

`CapWidthGTEDataWidth` là parameter assertion cho dual branch. Với ECC widths phải kiểm mapping thực tế của top/shadow; không lấy default35 so với mọi possible DataWidth39 rồi kết luận cả thiết kế lỗi.

Read-after-write timing là combinational read trên flop state + ID/WB forwarding ở ngoài; same-cycle pre-edge read không tự nhận post-edge write. Load-use hazard nằm ở ID, không do RF giải quyết.

## Validation/change impact

Cần tests x0/x15/x16/x31, RV32E illegal high registers, RV32/CHERIoT Off/On, dummy writes, cap data pairing, reset và illegal MuBi; negative corruption cả cap và integer data. Không có RTL run trong phiên này.

Sửa storage sharing/width/reset ảnh hưởng area, decode, ECC packing, lockstep delay/comparison, RVFI cap fields và mode-switch trust. Đổi backend phải kiểm port latency/clock gating/synthesis mapping, không chỉ functional truth table. FND-ARCH-01; OQ-01/06/07/08/11.
