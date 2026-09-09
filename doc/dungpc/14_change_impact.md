# 14 — Change impact và kế hoạch kiểm lại

BASE-01. Stage này CONDITIONAL, thực hiện ở mức **đánh giá thay đổi giả định** để phục vụ người đọc. Không sửa RTL/build/firmware; không có proposed patch được triển khai hay regression được báo pass. Mọi thay đổi bên dưới cần yêu cầu cụ thể và baseline mới nếu thực hiện.

## CHG-01 — Thống nhất BaseIsa configuration path

Motivation: FND-BUILD-01. Required behavior: một option chọn ISA phải tới đúng top parameter và giữ cùng giá trị tới core/RF/TRVK/tracer. Direct: util/ibex_config.py, YAML, Simple/core/top/tracing `.core`, sim/DV top macro naming. Indirect: generated filelist/defines, hierarchy, memory/tag widths, UVM cfg/ISS ISA strings và formal selection.

Review compile-time enum macro so với vlogparam của từng tool; đừng chỉ thêm field rồi mặc định consumer đúng tên. Hardware/software observable difference có thể là ZC/base ISA, shared RF và TRVK path; cần ghi intended mode rõ. Clock/reset/TRVK latency có thể đổi nếu nhánh generate đổi; không xem đây là purely cosmetic build fix.

Validation: setup/preprocess/elaborate RV32I/dual; dump value ở từng instance; small/opentitan/WB0/WB1; build/run cùng firmware RV32 trong runtime Off; mode On cần image/harness riêng. So expanded dependency/primitive và active assertions. Không cần equivalence giữa RV32I-only và dual topology như thể chúng bit-identical; chọn externally equivalent RV32 scope nếu đó là mục tiêu. Rollback nếu option silently ignored, hierarchy không đúng hoặc RV32 regression đổi ngoài intended behavior. OQ-01/02/06.

## CHG-02 — Dùng bus/RAM Simple System cho integration mới

Trigger: thêm peripheral có wait states, nhiều host, hoặc yêu cầu instruction decode/error thực. Direct: shared bus/RAM wrapper/Simple address decode; indirect LSU/TRVK outstanding, arbiter, response metadata, firmware/linker/header/testbench.

Bus hiện không giữ nhiều response ownership cho arbitrary latency. Thêm variable-latency device cần request acceptance contract và queue/selection tới completion; không chỉ thay rvalid delay. Nếu sửa instruction aliases, firmware vector/boot/error tests phải đổi; code từng “chạy được” ngoài RAM map có thể trap.

Timing risk: ready/grant combinational loops, arbitration starvation; reset risk: pending state bị mất; software risk: side effects split MMIO, lỗi khác trước. Validation: stalled devices, back-to-back different target, decode miss, two hosts contention, reset pending, byte writes/read-after-write/collision. Rollback nếu request được grant không có đúng một response, routing sai target, starvation trái contract hoặc boot image hợp lệ không chạy. OQ-10/12.

## CHG-03 — Bật CHERIoT/đổi capability layout hoặc TRVK

Direct: cheriot_pkg/ex, decoder, CSR/PCC, RF sharing, LSU two-word path, TRVK bitmap/address/capacity. Transitive: top widths/ECC packing/lockstep vectors, RVFI/tracer/ISS, memory tags, revocation writer/firmware, heap map, reset/mode protocol.

Required behavior phải lấy từ ISA/threat model đã chọn; PMP đang được bypass trong mode On, nên capability checks là trust boundary chính. Thay REGCAP_W không chỉ đổi một typedef: memory encoding không chứa correction bits giống RF, ECC padding/code width và cap vector packing cần xem lại.

Validation: bounds/exponent/overflow/seal/permission, load/store tag, revoked/out-of-range/sealing bitmap cases, FIFO full/stalls/errors/reset, data+cap forwarding WB0/WB1, mode switch khi quiescent và tests từ chối unsupported transition. Independent oracle thay vì copy package functions. Không dùng plain RV32 Sail proof chứng minh behavior này. Rollback nếu authority tăng trái spec, tag/error fail-open, response/context mismatch hoặc regress RV32 mode. OQ-06/07/09/12.

## CHG-04 — Đổi timer clear/IRQ hoặc bật assertion backend

Timer semantics: sửa sticky→level hoặc BE0-write không-clear là behavioral change, cần update REQ-TMR-01, C driver/handler assumptions, model expected timeline và RTL tests. Check mtime rollover, compare halfwrites, reset IRQ, interrupt reassert và software trap return.

Assertion backend: sửa vendor header/defines cần giữ provenance/patch vendoring; đảm bảo SV constructs được tool hỗ trợ, reset disabling và trigger reachable. Run một positive và một targeted negative thật, đối chiếu `DV_ASSERT_CTRL` và relax_cosim_check. Lint pass không thay assertion pass; không tự xóa waiver/silence checker để hết lỗi.

Equivalence có thể dùng cho refactor giữ nguyên logic; không mong equivalence strict qua thay đổi semantics có chủ đích. Rollback nếu comparator/harness mất khả năng phát hiện lỗi, macro vẫn rỗng hoặc phần mềm bị interrupt storm. OQ-05/10.

## Transitive re-baselining

| Input thay đổi | Finding/flow phải NEEDS-RECHECK |
|---|---|
| YAML/.core/config generator/tool defines | BUILD-01, ARCH-01, mọi active topology claim |
| Primitive FIFO/fork/header/gate | CHERI-02, CLK-01, DV-01, CAP/PWR flows |
| Package cap/CSR/PMP hoặc firmware/linker | SEC-01, CSR-01, BOOT-01, MEM-01, CAP/IRQ flows |
| Testbench/ISS/Sail/cutpoints/constraints | DV-02 và mọi proof/checker support; physical claims nếu phát sinh |

Giữ findings BASE-01 như evidence lịch sử. Tạo CHG/BASE mới, artifact hashes/logs và outcome actual. Không đánh dấu stale evidence thành CURRENT chỉ vì RTL chính không có diff.
