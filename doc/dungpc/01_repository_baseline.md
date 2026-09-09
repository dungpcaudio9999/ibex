# 01 — Repository baseline BASE-01

## Nguồn và tính bất biến

Repository: `/home/dungpc9/ndmoney4porche/projects/ibex`. Revision đầy đủ: `8031c7dde749bb9d62391e5befbe55f1c014a171`. Mốc thu thập UTC: `2026-09-08T02:40:08.962878+00:00` (09:40 giờ Việt Nam).

[source_manifest.json](evidence/source_manifest.json) ghi đường dẫn, kích thước và SHA-256 của **3.694 file tracked**, bao gồm RTL, vendor, testbench, firmware nguồn, manifest, lockfile và hướng dẫn. SHA-256 của manifest: `b20bcb9c387812c51f3a04ae1ae55c2fd25a111b5142edbac6c8b029a8d628ca`.

[source_changes.patch](evidence/source_changes.patch) rỗng; SHA-256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`. Trạng thái ban đầu trước khi viết báo cáo sạch; lúc collector chụp `git status`, script/bằng chứng mới đã là untracked trong `doc/dungpc/evidence`. Chúng là đầu ra phân tích, không phải đầu vào RTL chưa được nhận diện. [git_status_initial.log](evidence/git_status_initial.log) bảo toàn điểm chụp này.

Các tham chiếu đường dẫn, module, signal và số dòng trong bộ báo cáo đều ghim vào BASE-01. Link `#L` dùng để điều hướng, không thay thế revision và digest. Analysis revision là bộ file hiện tại được định danh bằng [artifact_manifest.json](evidence/artifact_manifest.json); chưa tạo commit phân tích.

## Dependency và generator

`git submodule status --recursive` trả về rỗng, exit 0. Dependency chủ yếu vendored; không suy ra repository không có dependency từ việc không có submodule.

| Dependency | Revision khai báo trong lockfile | Giới hạn |
|---|---|---|
| lowRISC/OpenTitan primitives | `3424e7fb4bc3ac92eb640d6af070055d293bc710` | Lock mô tả upstream; hash file hiện tại mới định danh nội dung checkout |
| PULP common_cells | `63e1b679a70eca3a1d60d686bc1fa170ec08e1ab` | stream fork/join được dùng bởi TRVK |
| riscv-dv, riscv-tests, arch-tests, Spike, CoreMark | Xem `vendor_lock_declarations` trong source audit | Không build hoặc tải phiên bản khác |
| Nix/Sail/formal toolchain | `flake.lock`, `dv/formal/uv.lock` được hash | Dependency closure chưa materialize trong phiên này |

Nguồn primitive và metadata generation nằm trong `vendor/lowrisc_ip/ip/prim`, các manifest `.core`, vendor lock/description files và `util/`. Comment lockfiles nhắc quy trình vendoring, nhưng không dùng comment đó làm bằng chứng tool vendoring có sẵn hoặc đã chạy tại checkout. Không chạy lại generator RTL; vì vậy chưa có version generator đang thực thi, output generation mới hay xác nhận file sinh phù hợp input. Mọi RTL primitive có sẵn được nhận diện bằng digest; implementation thực tế phải kiểm tra sau giải dependency/elaboration.

## Host và công cụ

Linux x86-64, kernel `7.0.0-30-generic`, glibc 2.43; Python 3.14.4, PyYAML 6.0.3. Có `gcc`, `make`; không tìm thấy trong PATH: FuseSoC, Edalize package, Verilator, Icarus/vvp, Yosys/SBY, slang, Verible, GCC RISC-V. Đây là kết quả probe tại phiên này, không khẳng định chúng không thể tồn tại ở vị trí khác.

Biến ảnh hưởng cấu hình được kiểm tra: `IBEX_CONFIG_FILE`, `RISCV`, `RV32_TOOLCHAIN` đều chưa đặt. Không thu thập toàn bộ environment hoặc thông tin license. [baseline.json](evidence/baseline.json) là record máy đọc được.

## Execution baseline

**NOT-ESTABLISHED.** Không có ELF/vmem đã chọn, executable mô phỏng, waveform, coverage hay netlist tạo bởi phiên này. `SRAMInitFile` mặc định rỗng. Firmware ứng viên là `examples/sw/simple_system/hello_test`; linker là `examples/sw/simple_system/common/link.ld`.

`make -n -C examples/sw/simple_system/hello_test` trả exit 0, chỉ in kế hoạch dùng `riscv32-unknown-elf-gcc`, `objcopy` và `srec_cat`. Nó không biên dịch ELF. Cờ dự kiến `-march=rv32imc -mabi=ilp32`; chưa có ISA-compatible CHERIoT firmware.

Simple System phụ thuộc `ram_2p`/`prim_ram_2p`, simulator C++/DPI, libelf, `simutil_verilator`, `memutil_verilator`, tracer; UVM cần thêm simulator và ISS. Không dùng stub thay thế rồi ghi thành build chính thức.

## Các lệnh đã chạy và cách tái lập

Từ root repository:

```bash
python3 util/ibex_config.py small fusesoc_opts
python3 util/ibex_config.py opentitan fusesoc_opts
fusesoc --version
verilator --version
fusesoc --cores-root=. run --target=sim --setup --build-root=doc/dungpc/evidence/build/simple_system lowrisc:ibex:ibex_simple_system
make -n -C examples/sw/simple_system/hello_test
python3 doc/dungpc/evidence/source_audit.py
python3 doc/dungpc/evidence/model_experiments.py
python3 doc/dungpc/evidence/model_experiments.py --corrupt-check
```

Lệnh config thành công. Lệnh FuseSoC/Verilator không khởi chạy được: Python `FileNotFoundError`, `launch_status=TOOL-NOT-FOUND`, `exit_status=null` vì không có child process. Không ghi exit 127 giả tạo, không có lỗi compiler đã được quan sát. Model dương exit 0; âm exit 1 đúng kỳ vọng. Xem Stage 12 để hiểu ý nghĩa.

[collect_evidence.py](evidence/collect_evidence.py) tạo snapshot lần đầu và từ chối ghi đè `baseline.json`. Để tái lập snapshot, dùng checkout mới của BASE-01 và chép script vào đúng `doc/dungpc/evidence`; không xóa bằng chứng gốc. Các script audit/model có thể chạy lại nhưng sẽ ghi đè artifact riêng của chúng: nên sao chép cả checkout sang thư mục kiểm tra trước khi chạy. Không có randomization hoặc seed cho các lệnh này.

Khi công cụ có sẵn, trước tiên giải quyết OQ-02 rồi lưu lệnh thực tế, expanded file list, defines, parameter dump, primitive mapping, firmware SHA-256, compile log và kết quả chạy vào baseline mới. Tên build command phía trên là lần thử setup, không phải công thức đã được xác nhận thành công.

## Gate và re-baseline

Source baseline MET; execution baseline LIMITED/NOT-ESTABLISHED, OQ-01. Không có warning compiler hay waiver mới được áp dụng. Waiver nguồn trong `lint/` và DV chỉ là input có sẵn.

Nếu RTL không đổi nhưng YAML, `.core`, primitive, assertion header, Sail/Spike, firmware, linker hay tool thay đổi: tạo BASE mới; đánh dấu các finding phụ thuộc `NEEDS-RECHECK`. Giữ nguyên BASE-01 và kết quả lịch sử. Sau khi kiểm tra lại mới cập nhật freshness; không sửa lịch sử thành một kết quả chưa từng chạy.
