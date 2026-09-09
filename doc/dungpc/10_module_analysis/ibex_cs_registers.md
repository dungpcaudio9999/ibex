# Module — ibex_cs_registers và PMP boundary

BASE-01; [CSR](../../../rtl/ibex_cs_registers.sv), [PMP](../../../rtl/ibex_pmp.sv), [core integration](../../../rtl/ibex_core.sv#L1570), [register map](../08_registers_and_interrupts.md).

CSR sở hữu privilege, mstatus/mie/mtvec/mepc/mcause/mtval, counters, debug/PMP settings và capability CSR/PCC. Input CSR operation là read/write/set/clear + address/operand/enable; controller có sideband save_cause/mret/dret/boot init. Không có req/gnt bus hay response queue tại CSR interface nội bộ; ID sequencing bảo đảm operation-enable đúng instruction/cycle.

## State, reset và priority

Current privilege reset M; mstatus stored MPP reset U, MIE0/MPIE1 — hai khái niệm khác nhau. IRQ pending mip là combinational, không reset-latched. MIE reset0 nên timer set sau reset không đủ để tạo maskable trap. Trap lưu privilege/PC/cause, tắt MIE và giữ MPIE; mret khôi phục theo saved privilege/NMI stack; DRET dùng DCSR privilege.

Operation SET/CLEAR tạo write_data bằng read value OR/AND mask; illegal privilege/debug/RO write gate `csr_we_int`. Sideband save/restore có priority case riêng sau xử lý software write; CHERIoT sentry set/clear MIE kết hợp ở mstatus path. Không dùng generic register-file test chỉ so readback để kiểm những race này.

Counters có index/event/width/update riêng. Full PMP/counter/debug field WARL và security CSR policy chưa được exhaustively kiểm; Stage 8 chỉ chọn subset theo flow. Source `ibex_csr`/counter và DV CSR model là các consumers cần recheck khi sửa.

## FND-SEC-01 — PMP không phải lớp kiểm bổ sung luôn bật trong CHERIoT

**Support:** SUPPORTED [RTL:ESTABLISHED]. BASE-01 core, `g_pmp_cheriot_gate`: khi BaseIsa dual và cheriot_enable On, pmp_req_err của I/I2/D bị ép0; address gating cũng có nhánh CHERIoT. Vì vậy bật PMPEnable trong YAML **không chứng minh** memory permission của CHERIoT được bảo vệ bởi PMP đồng thời. Việc chủ đích thay PMP bằng capability checks cần ISA/threat-model validation, OQ-06/07.

RV32 PMP path có ba access channels ở core: instruction PC, instruction PC+increment cho spanning instruction, data. PMP module xét TOR/NA4/NAPOT, privilege và MSECCFG; lowest-numbered matching region quyết định; unmatched default phụ thuộc M/U, MMWP/MML. Debug address access có exemption kiểm trong PMP. Không gán tất cả region mặc định allow hay deny cho mọi mode.

## Invariants và kiểm chứng

`INV-csr-01`: illegal CSR write không cập nhật state qua software write-enable. SUPPORTED bởi `csr_we_int` gate, nhưng một sideband trap cùng cycle vẫn có thể cập nhật state; property “mọi CSR bất biến khi illegal” là sai phạm vi.

`INV-csr-02`: irq_pending=OR(mip & mie), dù core đang gated; SUPPORTED combinational source. Không khẳng định live IRQ luôn được xử lý trong N cycles vì controller và environment assumptions.

`INV-pmp-01`: lowest-index matching PMP region có quyền quyết định RV32 check. SUPPORTED từ access_fault_check loop có matched guard; formal coverage chưa chạy. Cần mode/region overlap/lock/granularity/straddle/error tests.

Change impact: thay CSR address/reset/side effect cần update enum, docs, software headers/assembly, CSR model, UVM coverage, Spike/Sail model/cutpoints, debug dump và CHERIoT capability CSR conversion. Đổi PMP gating phải kiểm không phát memory side effects khi access bị từ chối. Flows BOOT/IRQ/CAP/ERR; OQ-01/05/06/07/09.
