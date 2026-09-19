# 08 — Deep dive `ibex_decoder`

## 1. Contract

Decoder là combinational translation từ normalized 32-bit instruction và mode
sang raw execution intent. Nó không quyết định instruction được commit ở cycle
nào; ID/controller qualify outputs.

## 2. Decode stages

Logical flow:

1. đặt safe defaults không side effect;
2. tách opcode/funct/register fields;
3. decode base RV32 class;
4. refine M/B/Zc/CHERIoT semantics theo parameters và runtime mode;
5. enforce register/address constraints;
6. tạo illegal flag nếu encoding hoặc feature không hợp lệ.

Safe-default discipline quan trọng: unrecognized instruction phải không write
RF, CSR hoặc memory trước khi trap.

## 3. Register addressing

RV32I dùng 5-bit x0..x31. RV32E hoặc CHERIoT mode giới hạn index; access upper
registers illegal. CHERIoT RF layout dùng low 4-bit physical selection và
metadata bank, nên legality phải bắt x16..x31 trước side effect.

## 4. Base instruction classes

Decoder tạo contract cho:

- LUI/AUIPC;
- JAL/JALR và branches;
- byte/half/word loads/stores;
- OP-IMM/OP ALU;
- FENCE/FENCE.I;
- SYSTEM: CSR, ECALL, EBREAK, MRET, DRET, WFI;
- M extension;
- B extension according to enum;
- CHERIoT-redefined/new opcodes.

Compressed instruction đã được expand, nên main decoder chủ yếu thấy equivalent
32-bit operation nhưng vẫn nhận metadata compressed từ IF/ID bên ngoài.

## 5. Operand/control outputs

Output categories:

- `alu_operator`, A/B mux và immediate mux;
- RF read enables và write intent;
- `branch_in_dec`, `jump_in_dec`;
- `mult_en/div_en`, select/operator/signed mode;
- LSU request/write/type/sign extension;
- CSR access/op/address;
- special instructions và legality;
- CHERIoT operation/selector bundle.

Read-enable chính xác là cần thiết cho hazard detection; một unused source bị
đánh read có thể tạo false load-use stall.

## 6. M/B parameter gating

`RV32MNone` làm M encodings illegal. Fast/slow/single-cycle không đổi ISA result,
chỉ đổi downstream implementation/latency.

`RV32BNone`, balanced/full/OTEarlGrey chọn tập operators. FX1 None phải trap mọi
bitmanip encoding; OpenTitan chấp nhận ratified và project-specific extra set.

## 7. CHERIoT runtime decode

Trong mode On:

- base I/E identity đổi;
- chỉ x0..x15;
- opcodes CHERI/AUICGP active;
- một số JAL/JALR/AUIPC/load/store semantics chuyển sang capability;
- operator bundle điều khiển `ibex_cheriot_ex`;
- RV32-only forms bị illegal theo policy.

Trong mode Off, CHERIoT outputs phải zero và RV32I semantics giữ nguyên.

**Invariant I-DEC-01:** Cùng một bit pattern có thể có semantics khác theo runtime
mode, nhưng chỉ một execution path được enable.

## 8. CSR legality split

Decoder nhận biết instruction CSR và static address fields; `ibex_cs_registers`
kiểm existence, privilege và write permissions. Vì vậy `illegal_insn` và
`illegal_csr_insn` là hai nguồn khác nhau được controller hợp nhất.

## 9. FENCE.I/cache interaction

FENCE.I được decode thành cache invalidate/control flush thay vì data-memory bus
operation. Với FX1 no-cache, architectural sequencing vẫn phải đúng dù physical
invalidate output không làm RAM work.

## 10. Assertions/review checks

- Illegal instruction ⇒ raw side effects ultimately suppressed.
- Selectors one-hot/valid where expected.
- CHERIoT outputs zero when disabled.
- M/B operations only when parameter supports.
- x16..x31 illegal under E/CHERIoT.
- CSR immediate/register-source read enables correct.

## 11. Findings

- **Fact F-DEC-01:** ISA compatibility risk của FX1 chủ yếu nằm ở `RV32BNone`
  và Zca-only, không ở M result semantics.
- **Fact F-DEC-02:** CHERIoT là runtime semantic mux trong one elaborated core.
- **Open O-DEC-01:** Cần generate exhaustive opcode legality table bằng test/
  script và so với declared `-march`.
- **Open O-DEC-02:** Firmware libraries phải audit instruction usage.

## 12. L4 handoff

Directed binary per instruction class; illegal M/B/Zcb/Zcmp; x16 register in
CHERIoT; same opcode RV32 versus CHERIoT; CSR access legality; FENCE.I no-cache.

## 13. Source anchors

- [`rtl/ibex_decoder.sv`](../../../../rtl/ibex_decoder.sv)
- [`rtl/ibex_pkg.sv`](../../../../rtl/ibex_pkg.sv)
- [`rtl/ibex_cheriot_pkg.sv`](../../../../rtl/ibex_cheriot_pkg.sv)

