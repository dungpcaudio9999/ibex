# 11 — Verification, checker và giới hạn proof

BASE-01; đây là **verification review**, không phải verification development đã hoàn tất. Không có simulator/formal run, assertion activation count, functional/code coverage hay regression result mới. Local documentation là nguồn intent; RTL/checker source là implementation evidence; trạng thái lịch sử trong README không áp dụng tự động cho baseline này.

## Environment và mô hình

Simple System dùng Verilator/C++ memory initialization/tracer và firmware MMIO halt. Không có ISS comparison chỉ vì có instruction trace. RAM/instruction errors buộc0, memory data tags=0, capability mode Off, bitmap không được phục vụ, alert outputs bỏ ngỏ; coverage của environment này hẹp hơn IP.

UVM `dv/uvm/core_ibex` có test top, memory response agents, IRQ agent, RVFI monitor và `ibex_cosim_scoreboard`. Scoreboard lấy retirement stream cùng side data-access stream; gọi Spike qua DPI. `riscv_cosim_step` so state theo PC/destination/result/trap/suppression và báo fatal khi mismatch, trừ `cfg.relax_cosim_check` hạ thành info. IRQ/debug/NMI được cập nhật vào ISS theo thứ tự; counters được set bằng pseudo-backdoor để đồng bộ, nên không xem đó là independent counter checking.

Nguồn testlist có arithmetic/random/illegal/jump/debug/WFI tests, directed tests PMP/U-mode/mcounteren; tên test `riscv_mmu_stress_test` không chứng minh DUT có MMU. Test generator, firmware, ISS/model ISA string, memory monitor sampling và simulator version cần đồng nhất. Không có seed của RTL run vì chưa chạy; không ghi seed1 dự kiến thành seed đã dùng.

UVM test top cũng tie `cheriot_enable_i=IbexMuBiOff`, và config DB `CHERIoT` lấy từ compile-time BaseIsa; cờ đó không chứng minh instruction CHERIoT runtime được exercise. Source `DV_ASSERT_CTRL` cho phép tắt nhóm checks spurious-response gồm TRVK AlignValidOnRsp_A. Một số fault tests có chủ đích kết thúc trước ISS mismatch hoặc relax checker; cần lưu state kiểm tra thực tế của run, không chỉ nhìn summary PASS.

## FND-DV-01 — Assertion macro backend vô hiệu hóa check trong Verilator

**Statement:** `vendor/lowrisc_ip/ip/prim/rtl/prim_assert.sv:102` chọn `prim_assert_dummy_macros.svh` khi `VERILATOR`, hoặc `SYNTHESIS`; file dummy định nghĩa ASSERT/ASSERT_INIT/COVER/ASSUME thành rỗng.

**Support:** SUPPORTED [RTL:ESTABLISHED], source-only conditional preprocessor semantics. **Applies:** BASE-01, file header này được resolve, define VERILATOR/SYNTHESIS có hiệu lực; actual preprocessing chưa chạy. **Assumptions:** đúng include resolution của baseline, ASM-CFG-01. **Depends on:** header/dummy implementation, include paths, target defines/tool. **Freshness:** CURRENT.

**Impact:** HIGH cho dùng sim/lint pass để khẳng định assertions pass. `--assert` không phục hồi macro đã bị preprocess thành rỗng. Không suy ra mọi checker bằng C++/UVM hoặc raw SV assertion cũng biến mất. **Evidence:** EVD-08 source excerpts + hashed source. **Uncertainty:** OQ-05; cần preprocess/activation/negative test cho build cụ thể. **Review:** chưa được duyệt độc lập; không supersede.

## Requirement-to-check matrix

Các REQ dưới đây là **reconstructed analysis requirements** từ local docs/RTL để lập kế hoạch; chưa thay thế product requirements được architect phê duyệt.

| ID / nguồn | Behavior / config | Check hiện hữu hoặc cần bổ sung | Scenario/coverage bắt buộc | Kết quả BASE-01 |
|---|---|---|---|---|
| REQ-CFG-01 — YAML/manifest | ISA/params đi đúng top | EVD-02/03 config audit; cần elaboration dump | small/dual và WB/cache boundary | Source mismatch established; elaborate NOT-RUN |
| REQ-BOOT-01 — IF/crt0 | Reset PC=boot+0x80 với aligned boot | IbexBootAddrUnaligned + PC/RVFI checker | Reset→first request→first retire | Source known; RTL NOT-RUN |
| REQ-IF-01 — prefetch/IF | Grant stall ổn định, old path bị discard | FIFO full assertions + cần instruction-address scoreboard | Branch+rvalid/full/upper-half/error | NOT-RUN |
| REQ-LSU-01 — LSU protocol | One in-order response/word; split data/error đúng | Top pending tracker, LSU align/state checks + ISS memory agent | BE/type/sign, both grant/response orderings | NOT-RUN |
| REQ-IRQ-01 — controller/CSR | IRQ priority/save/return chính xác | PipeEmptyOnIrq, IRQ agent, ISS state | Simultaneous IRQ/debug/older exception | NOT-RUN |
| REQ-TMR-01 — timer equations | Sticky IRQ/compare-write priority | Python oracle EVD-06/07; cần directed RTL MMIO checker | mtime backwards, BE0, rollover, compare expired | Model-only OBSERVED; RTL NOT-RUN |
| REQ-PWR-01 — top/CSR | Sleep/wake không mất request/response | Cần clock+transaction epoch monitor | WFI outstanding, masked IRQ, reset ungated/gated | NOT-RUN |
| REQ-CAP-01 — package/EX/RF | Capability result/permissions/bounds và mode state đúng | Cần CHERIoT ISA oracle, data+cap scoreboard | Tagged/untagged, boundary/exponent/sealing/mode switch | NOT-RUN; Simple/UVM mode Off |
| REQ-TRVK-01 — TRVK | Không mất/misassociate response, revoked→tag clear | AlignValidOnRsp_A, DsRspFifoNoOverflow_A, Revbm* + independent cap/tag oracle | Full, delayed bitmap, bad bit/ECC, unsolicited/reset | NOT-RUN |
| REQ-CSR-01 — CSR policy | Illegal access không ghi state qua CSR write | CSR model/directed U-mode/mcounteren; cần cap CSR policy check | RO/privilege/debug/PCC.SR/trap write race | NOT-RUN |
| REQ-SEC-01 — top ECC/lockstep | Error được detect/propagate, load write suppressed | NoAlertsTriggered khi normal; fault tests target alert | Data/cap/ECC/shadow faults, checker enable audit | NOT-RUN |
| REQ-MEM-01 — map/linker | Software allocation phù hợp decode; alias được hiểu | EVD-06 arithmetic map audit; cần ELF+RTL monitor | Vùng đầu/cuối/miss/MMIO and I/D alias | Source/model only |

## FND-CHERI-01 — Environment hiện có không establish CHERIoT end-to-end

**Support:** SUPPORTED cho source configuration [RTL:ESTABLISHED]. BASE-01 Simple và UVM test tops tie runtime Off; Simple memory tag0 và bitmap grant/rvalid0. Formal chọn pure RV32I. Kết luận: **không có bằng chứng** capability execution/revocation end-to-end từ các environment đã đọc hoặc từ phiên này. Không khẳng định toàn repository không thể có thêm harness/ngoại bộ nào. OQ-06; evidence EVD-08.

## Formal scope và giả định cụ thể

**FND-DV-02:** Harness `dv/formal/check/top.sv:172` chọn BaseIsaRV32I; runtime mode Off, bitmap/tags tied0. Mem protocol đặt `TIME_LIMIT=5` ở source hiện tại; `NoErr` assume !err, không response khi outstanding trước cycle=0, grants chỉ khi req. Khi YOSYS, StrictGnt/StrictRValid dùng phản hồi mạnh hơn; không dùng bound5 để mô tả mọi backend. **Support:** SUPPORTED [RTL:ESTABLISHED]; không có proof result cho baseline.

IRQ protocol NoNMI/NoFastIRQ, WFI_BOUND=20 và fairness/wakeup; top cấm debug, giữ boot constant/fetch enabled; mcounteren có assumption stub0 ở harness. `thm/riscv.proof` có Live/Liveness bị comment out. README formal có các nhận định lịch sử, TIME_LIMIT tại thời điểm viết khác5 hiện tại, và liệt kê proof holes/reset/fetch; không lấy chúng làm authoritative run log.

| Property record | Model / assumptions / giới hạn | Result |
|---|---|---|
| PROP-FORMAL-01: Wrap/Top/Load/Store/NoMem | Sail spec + generated theorem/RTL modifications của flow; RV32I harness; bounded-service/no-error assumptions; cần inventory cutpoints và chứng minh lemmas phụ thuộc | FORMAL:NOT-RUN |
| PROP-FORMAL-02: Live | Source Live comment out; cần bật có chủ đích và điều chỉnh bound theo TIME_LIMIT/WFI_BOUND, cover spec_en và tránh assume conclusion | FORMAL:NOT-RUN |
| PROP-TRVK-01: AlignValidOnRsp_A | Gated core clock, active-low reset/default disable; assumption response đúng epoch; cover tagged pair/full/bitmap wait | FORMAL:NOT-RUN |
| PROP-TRVK-02: DsRspFifoNoOverflow_A | Accepted request accounting, NumOutstanding2, downstream không rready; cần fork/queue composition | FORMAL:NOT-RUN |

Không có engine/version/depth/log/induction completion của run để gán PROVED hay BOUNDED-PASS. Engine/depth là **chưa chọn**, không dùng “depth0 pass”. Không có evidence vacuity/antecedent/cover reachability. Formal READMEs của `formal/icache` và `formal/data_ind_timing` còn ghi chưa có cách chạy các assertions đó; giữ chúng là source assets.

## End-of-test, effectiveness và coverage gaps

Run đúng cần phân biệt firmware success, trap handler halt, timeout/watchdog, UVM fatal và `$finish`; drain accepted request/response, ISS queues và final obligations trước PASS. Phiên này chưa kiểm chứng end-of-test drain của một run, nên không gán coverage phần trăm hoặc nói checker fully effective.

Negative Python EVD-07 chỉ kiểm comparison phát hiện một observed IRQ bit bị lật trong abstract model. Nó không là mutation RTL, không kiểm SVA disabled, không chứng minh Spike/capability checker sensitivity. Một negative run đúng cho REQ-TRVK/SEC phải chạm DUT/interface trong harness và chứng minh checker tương ứng đã trigger/fail.

Gap chính: active config, macro enable, memory/reset epochs, CHERIoT oracle, bitmap/tag service, secure/cache faults và formal assumption discharge. Không có waiver mới. Các waiver nguồn như `lint/verilator_waiver.vlt`, `dv/uvm/core_ibex/waivers` được snapshot nhưng chưa áp dụng/review full ruleset trong tool. OQ-01/05/06/08/09/12.
