# 02 — Inventory và thứ tự đọc

Phạm vi BASE-01. [source_audit.json](evidence/source_audit.json) liệt kê từng file RTL, số dòng, declaration, macro/ifdef và cấu hình; đây là **text inventory**, không phải parser SystemVerilog, coverage hoặc hierarchy elaborate. Đếm được 33 file `.sv` trực tiếp trong `rtl/`, 25.816 dòng kể cả comment/blank; số này không bao gồm vendor và không có nghĩa tất cả cùng active.

| Nhóm | Nguồn | Vai trò và nguồn gốc | Lựa chọn cần xác nhận |
|---|---|---|---|
| Package | `rtl/ibex_pkg.sv`, `rtl/ibex_cheriot_pkg.sv` | Enum, CSR, cache shape; kiểu capability/hàm bounds | `.core` khai báo thứ tự package trước consumer |
| IP wrapper | `rtl/ibex_top.sv` | RF, gate, RAM, lockstep, TRVK, alert | Tùy BaseIsa/RegFile/SecureIbex/ICache |
| Core | `rtl/ibex_core.sv` | Kết nối pipeline, PMP, CSR, LSU, RVFI | Boundary khác top vì RF/cache RAM ở ngoài |
| Trace wrapper | `rtl/ibex_top_tracing.sv`, tracer/pkg | RVFI → trace mô phỏng | `RVFI`; không phải module debug/JTAG |
| Front end | IF, prefetch, fetch_fifo, compressed_decoder, branch_predict | Fetch, align/decompress, flush, prediction | Cache thay prefetch; DII_SIM thay dữ liệu quan sát |
| Execute/control | ID, decoder, controller, EX, ALU, multdiv | Decode, hazard, state multi-cycle, PC recovery | WB, RV32M/B/ZC, branch target ALU |
| State/data | LSU, WB, CSR/counter, RF FF/latch/FPGA | Giao dịch bộ nhớ và architectural state | RF implementation, ECC, capability mode |
| Capability | cheriot_ex, cheriot_pkg, trvk | Permission/bounds, hai-word capability, revocation | BaseIsa dual và runtime MuBi |
| Security/cache | icache, lockstep, dummy_instr, PMP | Cache, redundancy, quyền truy cập, dummy | Không gộp thành một chế độ bật/tắt duy nhất |
| Simple System | `examples/simple_system/rtl/ibex_simple_system.sv` | Wrapper mô phỏng của repo | Top ứng viên `sim`, không phải SoC chip đầy đủ |
| Shared | `shared/rtl/bus.sv`, `ram_2p.sv`, `timer.sv`, `sim/simulator_ctrl.sv` | Bus demo, RAM adapter, MMIO; mã nội bộ | Devices cần phản hồi đúng một cycle |
| Primitives | `vendor/lowrisc_ip/ip/prim*` | Vendored, gồm các file generated và backend generic | Cần giải virtual core/generator; xem lock/hash |
| PULP | `vendor/pulp_common_cells/rtl` | Vendored fork/join dùng bởi TRVK | Có dependency `pulp-platform:common_cells:common_cells` |
| Core DV | `dv/uvm/core_ibex`, `dv/cosim` | Agent memory/IRQ, RVFI, Spike scoreboard, tests | Model/ISA/seeds/simulator chưa chạy |
| Unit DV | `dv/cs_registers`, `dv/uvm/icache` | CSR model; cache plan/coverage | Không thay thế core regression |
| Formal | `dv/formal`, `formal/icache`, `formal/data_ind_timing` | Sail trace equivalence; bộ SVA lưu trữ | Harness khác nhau, kết quả chưa chạy |
| Software | `examples/sw/simple_system`, `dv/.../directed_tests` | crt0, linker, headers, test firmware | Chưa build image nào |
| Physical | `syn/`, `shared/rtl/fpga`, `lint/` | Tcl/Yosys/STA, primitive mapping, FPGA clock, waiver | Không có netlist/report được tạo trong baseline |
| Build | `.core`, `ibex_configs.yaml`, `util/ibex_config.py`, `Makefile`, `flake.*` | Target/config/dependency intent | Không dùng file tồn tại làm bằng chứng active |

## Top và luồng dependency ứng viên

Đọc `examples/simple_system/ibex_simple_system.core` → `ibex_simple_system_core.core` → `ibex_top_tracing.core` → `ibex_top.core` → `ibex_core.core`, `ibex_pkg.core`, primitives/PULP. Đây là **đồ thị khai báo**, không phải hierarchy dump. Target `ibex_core` thiếu những khối wrapper mà tích hợp `ibex_top` có.

## FND-BUILD-02 — Danh sách nguồn cũ có đường dẫn không tồn tại

**Support:** SUPPORTED. **Scope/evidence:** BASE-01, nội dung `src_files.yml`, EVD-03 [STATIC:ESTABLISHED — kiểm tra tồn tại đường dẫn]. Có ba entry thiếu: `rtl/ibex_counters.sv`, `shared/rtl/prim_assert.sv`, `rtl/ibex_core_tracing.sv`.

Nguồn hiện hữu có `ibex_counter.sv`, assertion header ở vendor và `ibex_top_tracing.sv`. Không tự thay tên vì có thể khác dependency và boundary. `rtl/ibex_core.f` cũng là danh sách ngắn không bao gồm các dependency CHERIoT/core hiện tại. Chưa chứng minh consumer nào còn dùng hai danh sách cũ; không kết luận tất cả build target hỏng, hoặc những file này được upstream xác nhận deprecated. OQ-03.

## Ưu tiên

P0: cấu hình thực tế, gate/reset, LSU/controller/WB, TRVK và assertion selection — sai ở đây làm thay đổi nghĩa giao dịch hoặc làm kết quả kiểm tra mất giá trị. P1: fetch/flush, CSR/PMP/interrupt và RF mode sharing. P2: cache/ECC/lockstep và numeric helpers ở mức boundary; cần phân tích sâu hơn khi chọn các tính năng này. [Module index](10_module_analysis/README.md) nêu rõ phần nào đã đọc sâu.

Không có bằng chứng để đánh dấu một file globally unused/deprecated. Những khối không chọn trong `CFG-small-intent` chỉ là nhánh tắt có điều kiện, chưa phải kết luận từ elaboration.
