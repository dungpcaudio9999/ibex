# 03 — Build và configuration

BASE-01; EVD-02 là chạy Python generator option, EVD-03 là audit manifest, EVD-04 là thử khởi động build thất bại do thiếu executable. **Active elaborated configuration: UNKNOWN (OQ-01/OQ-02)**.

## Điểm vào và compile intent

| Target | Top khai báo | Công dụng | Kết quả phiên này |
|---|---|---|---|
| `lowrisc:ibex:ibex_simple_system`, `sim` | `ibex_simple_system` | Verilator mặc định; C++/DPI/ELF | Không khởi động FuseSoC được |
| `lowrisc:ibex:ibex_top:0.1`, `lint` | `ibex_top` | Verilator lint, SYNTHESIS/RVFI | NOT-RUN |
| `lowrisc:ibex:ibex_core:0.1`, default/lint | `ibex_core` | Core không gồm RF/TRVK wrapper | NOT-RUN |
| `dv/uvm/core_ibex/Makefile` | core testbench | Regression + ISS | NOT-RUN |
| `dv/formal/Makefile` | formal harness | Sail/Jasper hoặc Yosys/rIC3 | NOT-RUN |

Các `.core` chứa fileset phụ thuộc và tùy chọn `tool_verilator`, `tool_vivado`, `fileset_partner`. `ibex_pkg.core` liệt kê `ibex_pkg.sv` rồi `ibex_cheriot_pkg.sv`; `ibex_core.core` liệt kê CHERIoT EX cùng các module pipeline; `ibex_top.core` thêm RF/TRVK/lockstep và PULP common cells. Chưa có expanded include path, filelist, library resolution hoặc output generator của một build thành công.

Simple System sim dự kiến dùng `--trace`, `--trace-fst`, `--trace-structs`, `--trace-params`, `--unroll-count 72`; C++17 và link pthread/util/elf. Các flag này là khai báo trong file, không chứng minh FST được tạo.

## Ma trận cấu hình ưu tiên

| Tham số | small intent | Simple RTL default | opentitan intent | Ý nghĩa |
|---|---|---|---|---|
| BaseIsa | RV32I | RV32IorCHERIoT | RV32IorCHERIoT | Generate capability hardware và TRVK |
| cheriot_enable_i | Không có trong YAML | IbexMuBiOff | Tín hiệu integration, không có trong YAML | Runtime mode khác compile-time BaseIsa |
| RV32E | 0 | 0 | 0 | 32 GPR RV32I; dual mode thay đổi cách dùng RF |
| RV32M | Fast | Fast | SingleCycle | Tổ chức nhân/chia; không suy ra mọi phép chia một cycle |
| RV32B | None | None | OTEarlGrey | Decoder/ALU bitmanip |
| RV32ZC | Zca | ZcaZcbZcmp | ZcaZcbZcmp | Có/không Zcb/Zcmp và expanded instructions |
| RegFile | FF | FF | FF | Các backend latch/FPGA là cấu hình khác |
| BranchTargetALU / WritebackStage | 0 / 0 | 0 / 0 | 1 / 1 | Datapath branch; pipeline hai/ba tầng |
| ICache / ECC / Scramble | 0 / 0 / 0 | 0 / 0 / 0 | 1 / 1 / 1 | Prefetch thay cache; RAM integrity/key service |
| BranchPredictor | 0 | 0 | 0 | Nhánh dự đoán không được khảo sát động |
| SecureIbex / DbgTriggerEn | 0 / 0 | 0 / 0 | 1 / 1 | Lockstep, ECC, dummy và debug trigger |
| PMPEnable / Granularity / Regions | 0 / 0 / 4 | 0 / 0 / 4 | 1 / 0 / 16 | Regions=4 không có nghĩa PMP active khi Enable=0 |
| MHPMCounterNum / Width | 0 / 40 | 0 / 40 | 10 / 32 | Extra HPM, không loại bỏ cycle/instret |

Đủ tám cấu hình YAML được lưu trong EVD-03; những cấu hình maxperf/PMP/cache/predictor khác chưa chạy. Không kế thừa nhãn “supported/Green” trong tài liệu thành verification status cho local CHERIoT changes.

## FND-BUILD-01 — Đường truyền BaseIsa chưa nhất quán

**Statement:** generator `util/ibex_config.py small fusesoc_opts` phát `--BaseIsa=ibex_pkg::BaseIsaRV32I`; manifest Simple System không khai báo/chọn field BaseIsa, trong khi RTL Simple System lấy default từ macro `BASE_ISA`, mặc định dual ISA. `ibex_top.core` và tracing core có field `BaseIsa` kiểu vlogdefine, nhưng điều đó không tự chứng minh `BASE_ISA` của top sim nhận cùng giá trị.

**Support:** SUPPORTED cho sự khác biệt văn bản [RTL:ESTABLISHED; STATIC:ESTABLISHED]; ảnh hưởng đến parser/build cụ thể INFERRED, chưa có FuseSoC để quan sát. **Applies:** BASE-01, đường build Simple System từ named configs. **Assumptions:** không có override ngoài snapshot; ASM-CFG-01. **Depends on:** YAML, config.py, ba `.core` và RTL top/wrapper. **Freshness:** CURRENT.

**Impact:** HIGH cho lựa chọn ISA/topology; không được gọi source default là `small`. **Evidence:** EVD-02 (`config_small.log`), EVD-03 (`core_manifests`, `config_fields_not_declared`), `examples/simple_system/rtl/ibex_simple_system.sv:29,63,209,315`. **Remaining uncertainty:** hành vi option parser, define expansion, parameter cuối và hierarchy; OQ-02. **Review:** chưa được reviewer độc lập duyệt; không có finding bị thay thế.

## FND-BUILD-03 — UVM enum macros không khớp consumer

**Support:** SUPPORTED [STATIC:ESTABLISHED; RTL:ESTABLISHED], BASE-01. Chạy trực tiếp generator với đúng prefix/hierarchy mà `dv/uvm/core_ibex/scripts/ibex_cmd.py` yêu cầu cho VCS sinh `IBEX_CFG_BaseIsa`, `IBEX_CFG_RegFile`, `IBEX_CFG_RV32ZC`. Trong test top, các macro đọc là `IBEX_CFG_BASE_ISA`, `IBEX_CFG_REG_FILE`; không có consumer `IBEX_CFG_RV32ZC` hoặc forwarding RV32ZC ở parameter/instance block đã đọc. Macro SystemVerilog phân biệt hoa/thường.

EVD-09 giữ lệnh và stdout. Đây là mismatch nguồn cụ thể: không có bằng chứng những option này thay được default tương ứng tại test top qua đường đang xét. Actual compiler preprocessing/active configuration còn UNKNOWN; không khẳng định một regression cụ thể đã dùng sai params khi chưa chạy. Cấu hình small Zca và test wrapper default ZcaZcbZcmp vì vậy cần kiểm lại cùng BaseIsa. Nối vào OQ-02, CHG-01; kiểm mọi simulator/options stage khi sửa, không chỉ Simple System.

## Macro, generate và mô hình

| Điều kiện | Tác động nguồn | Rủi ro diễn giải |
|---|---|---|
| `RVFI`, `RISCV_FORMAL` | Xuất retirement interface; RISCV_FORMAL định nghĩa RVFI | Có trace không đồng nghĩa có ISS checker |
| `VERILATOR` | Clock/reset sim qua IO; assertion header chọn dummy macros | Thêm `--assert` không khôi phục macro đã bị loại |
| `SYNTHESIS` | Dummy assertion, loại một số simulation code | Lint target này không là functional assertion run |
| `YOSYS` | Assertion macro backend riêng; formal memory assumptions mạnh hơn | Proof model thay đổi theo define |
| `DII_SIM` | Fetch FIFO có nhánh lấy instruction injection | Không chứng minh đường fetch RAM bình thường |
| `DV_FCOV_DISABLE` | Loại instrumentation functional coverage | Đếm macro không phải số obligation active |
| `BASE_ISA`, `RV32M`, `RV32B`, `RV32ZC`, `RegFile` | Giá trị enum qua macro ở sim wrapper | Phải kiểm tra chính xác tên/case và consumer |
| `FPGA_XILINX` | Chọn một số pragma/implementation | Không dùng kết quả generic làm timing FPGA |

Top default `MemECC=SecureIbex`; local `Lockstep`, `ResetAll`, RF ECC/dummy có quan hệ với SecureIbex. TRVK được generate theo **BaseIsa**, không theo runtime `cheriot_enable_i`. `CheriotRevBitmapAddrWidth=11`, base bitmap mặc định 0; top đặt NumOutstanding TRVK=2 dù module riêng default=4. Cần kiểm tra range assertion (Stage 10), không thay những giá trị này bằng default module trong báo cáo capacity.

## Gate và bước tiếp theo

G-02 LIMITED. Muốn có execution baseline: thống nhất cấu hình ở boundary; chạy setup để có filelist/defines/dependency mapping; elaborate cả RV32I và dual-mode; lưu parameter/hierarchy dump; kiểm tra assertion backend; build firmware/ISS đúng ISA; sau đó mới chạy baseline và so trace. Những bước này chưa được báo là thành công. Không sửa manifest trong nhiệm vụ phân tích.
