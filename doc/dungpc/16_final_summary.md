# 16 — Kết luận phân tích

**Đã hoàn tất bộ phân tích mã nguồn với giới hạn được ghi rõ; chưa xác nhận kiến trúc active bằng elaboration hoặc hành vi bằng mô phỏng RTL.** Baseline `8031c7dde749bb9d62391e5befbe55f1c014a171`, ngày 2026-09-08. Nguồn tracked không được sửa. Kết quả áp dụng cho snapshot/dependency/hash trong Stage1, không cho mọi phiên bản Ibex.

## Hệ thống đã xác định

Repository có CPU Ibex RV32 với các phần mở rộng CHERIoT ở decoder/EX/CSR/RF/LSU/TRVK. `ibex_top` bao RF, gate, cache RAM/security và data filtering quanh `ibex_core`; Simple System thêm shared dual-port RAM1MiB, data bus một host/ba devices, timer và simulator MMIO. Pipeline có hai tầng hoặc ba tầng theo WritebackStage. Cache/secure/PMP/ISA chọn bằng cấu hình; BaseIsa compile-time khác cheriot_enable runtime.

Luồng được tài liệu hóa: boot; fetch-stall/branch/FENCE.I; aligned/split LSU; timer trap/return; WFI/wakeup; tagged capability revocation; bus/PMP/ECC/error recovery. Stage10 phân tích sâu10 nhóm module, có state/handshake/invariant/limits/change impact.

## Findings ảnh hưởng quyết định

| ID | Kết luận có bằng chứng | Giới hạn / tác động |
|---|---|---|
| FND-BUILD-01 | Generator phát BaseIsa; Simple manifest thiếu field; RTL đọc BASE_ISA default dual | Chưa biết option parser/elaboration kết quả; cần sửa/chốt đường config trước claim small |
| FND-BUILD-02 | src_files.yml chứa3 paths không tồn tại | Chưa xác định consumer; không kết luận mọi target fail |
| FND-BUILD-03 | UVM generator enum macros khác tên consumer; RV32ZC không được forward tại test top | Có stdout generator, chưa có compiler/hierarchy xác nhận actual params |
| FND-ARCH-01 | Dual RF chia sẻ upper registers với cap metadata | Mode-switch protocol chưa được xác nhận |
| FND-BUS-01 | Bus demo chỉ đúng với response sau một cycle | Không dùng như bus variable-latency tổng quát |
| FND-MEM-01 | Instruction RAM alias modulo1MiB, data bus decode chặt hơn | Wrapper simulation behavior, chưa là product contract |
| FND-BOOT-01 | Simple boot entry0x100080, trap base0x100000 RV32 | Chưa có ELF/run để thấy execution |
| FND-IF-01 | Prefetch2 outstanding, FIFO3 words và clear priority | Khác số instructions và khác ICache path |
| FND-LSU-01 | Split/cap có2 word accesses; req_done khác resp_valid | Có pending response dù LSU FSM IDLE |
| FND-TMR-01 | Timer IRQ sticky; compare-write clear thắng kể cả BE0 | Python model đã kiểm recurrence, RTL chưa chạy |
| FND-IRQ-01 | NMI→fast→external→software→timer; fast index thấp ưu tiên | Debug/exception priority còn có điều kiện riêng |
| FND-CSR-01 | CSR write gate bởi illegal/access policy, thêm PCC.SR trong cap mode | Không đồng nhất với sideband trap/save updates |
| FND-CLK-01 | Wake từ ungated IRQ/debug logic, core_sleep=~clock_en | Test gate override/CDC/reset/physical chưa được xác nhận |
| FND-SEC-01 | CHERIoT mode On gate PMP errors về0 | Không claim PMP cộng thêm protection trong mode này |
| FND-CHERI-01/02 | Simple/UVM mode Off; formal RV32I; TRVK cần tagged pair+bitmap service | Chưa có CHERIoT end-to-end evidence |
| FND-DV-01/02 | Verilator macro assertions rỗng; formal có model/assumption hạn chế | Không suy ra pass/proof của local secure/capability behavior |

Support của các facts nguồn là SUPPORTED/RTL:ESTABLISHED theo cấu hình điều kiện; hệ quả runtime chưa đo được giữ INFERRED/UNKNOWN. Không phát hiện một RTL bug có counterexample chạy HDL trong phiên này. Những khác biệt source/document/config và rủi ro integration không được nâng thành “chip sai” khi chưa có scope/requirement phù hợp.

## Kiểm tra đã thực hiện

Hash3.694 files; inventory8 named configs/33 RTL files; config generator small/opentitan exit0; audit tồn tại/path/field; firmware make dry-run exit0. Thử launch FuseSoC/Verilator bị thiếu executable, không có compiler diagnostics. Arithmetic Python model có10 timer edges/12 address cases, dương exit0; negative comparator cố ý fail cạnh5 exit1 đúng kỳ vọng. Logs/commands/results/checksums nằm trong evidence.

Các số này không phải test coverage, số assertion pass hoặc performance. Python model và negative check không thực thi DUT SystemVerilog. Không có waveform, RTL simulation, semantic lint, formal result, STA/CDC/RDC hoặc silicon measurement mới.

## Gate assessment

| Gate | Status | Lý do |
|---|---|---|
| G-01 source/dependency baseline | MET | Revision, patch rỗng, hashes, lock declarations |
| G-02 active configuration | LIMITED | Thiếu elaboration và BaseIsa propagation còn mở |
| G-03 architecture/state/flow depth | MET trong scope nguồn | Có mapping hai boundaries, contracts và10 module records |
| G-04 evidence/uncertainty | MET | Tách source, model-only, unrun verification và assumptions |
| G-05 reproducibility | MET | Scripts/logs, artifact manifest và validation report |
| G-06 decision-blocking unknowns được đóng/chấp thuận | NOT-MET | OQ vẫn OPEN; chưa có review/waiver của owner |

Analysis work status **COMPLETE-WITH-LIMITATIONS**. Objective “active architecture understanding” **LIMITED**; design verification/sign-off **chưa được establish**. Không có sự chấp thuận rủi ro từ người dùng được suy diễn trong kết luận.

## Việc cần làm tiếp theo theo thứ tự phụ thuộc

1. Chốt target/config và đường BaseIsa; dựng môi trường build, capture preprocessing/hierarchy/parameter và chạy firmware baseline RV32.
2. Xác nhận checker backend/enable/reset/trigger; chạy positive và negative có tác động đến DUT, lưu pending-obligation/end-of-test evidence.
3. Cho CHERIoT: xác định ISA/model revision, mode transition contract, tagged memory và revocation bitmap service; kiểm permissions/bounds/tag/error/reset/forwarding.
4. Trước tích hợp thực: thay/định nghĩa lại bus demo nếu cần wait states, chốt instruction address decode/MMIO/timer contract, thực hiện clock/reset/CDC/RDC/STA theo target.
5. Rebaseline cả dependency, generators, firmware và checker/model khi thay đổi; dùng [change impact](14_change_impact.md) và [OQ register](13_open_questions.md).
