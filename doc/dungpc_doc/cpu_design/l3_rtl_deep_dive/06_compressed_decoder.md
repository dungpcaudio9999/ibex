# 06 — Deep dive compressed decoder

## 1. Contract

`ibex_compressed_decoder` nhận fetch word/address context và luôn trả instruction
32-bit cho main decoder, kèm:

- instruction có compressed hay không;
- illegal compressed encoding;
- expansion lifecycle cho Zcmp;
- original 16-bit instruction phục vụ trap/RVFI.

## 2. Basic Zca mapping

Decoder phân vùng theo quadrant `instr[1:0]` và funct fields. Lệnh hợp lệ được
rewrite thành equivalent 32-bit base instruction. Reserved encodings, register
constraints và immediate-zero constraints tạo `illegal_instr_o`.

Không phải mọi 16-bit pattern đều illegal chỉ vì output 32-bit có opcode lạ;
legality được quyết định trong compressed decoder trước main decoder.

## 3. RV32ZC parameter levels

- `RV32Zca`: base compressed mappings.
- `RV32ZcaZcbZcmp`: thêm Zcb và macro push/pop/move expansion.

OpenTitan active full level; FX1 chỉ Zca. Generate/constant conditions phải ngăn
Zcb/Zcmp encodings được chấp nhận ở FX1.

## 4. Zcmp state

FSM enum:

```text
CmIdle
CmPushStoreReg
CmPushDecrSp
CmPopLoadReg
CmPopIncrSp
CmPopRetRa
CmPopZeroA0
CmMvSecondReg
```

Push/pop instruction được phát thành chuỗi load/store/add/jump micro-ops. Internal
register index/counters đi qua list đã encode.

## 5. Expansion metadata

`instr_exp_e` phân biệt:

- `INSTR_NOT_EXPANDED`;
- `INSTR_EXPANDED`;
- `INSTR_EXPANDED_COMMIT`;
- `INSTR_EXPANDED_LAST`.

Controller dùng metadata để giữ atomicity với interrupt/exception; performance
counter/RVFI dùng để không đếm sai macro instruction.

## 6. Handshake and state update

FSM chỉ tiến khi input valid và downstream thực sự chấp nhận micro-op. Assertion
`IbexPushPopFSMStable` yêu cầu state không đổi khi `valid_i=0`. `flush_expanded_i`
đưa state về idle khi exception redirect, tránh tiếp tục macro cũ.

**Invariant I-CDEC-01:** Mỗi architectural Zcmp instruction hoặc hoàn tất toàn
chuỗi theo commit policy, hoặc bị flush mà không phát micro-op hậu kỳ.

## 7. Fault implications

Micro-op load/store có thể fault giữa chuỗi. Controller/CSR phải báo PC và
instruction theo macro semantics; partial memory effects của push/pop phụ thuộc
ISA atomicity contract và expansion commit markers. Đây là vùng cần đối chiếu
spec, không chỉ source.

## 8. Assertions

- State encoding hợp lệ/stable khi no valid.
- Register-list progression hợp lệ.
- Expansion output consistency.
- Illegal encodings không phát side effect hợp lệ.
- Flush về idle.

## 9. Findings

- **Fact F-CDEC-01:** FX1 không active Zcmp FSM behavior dù source/state tồn tại.
- **Fact F-CDEC-02:** Zca vẫn bắt buộc trong named FX1 profiles; compressed không
  thực sự “off”.
- **Open O-CDEC-01:** Firmware build flags phải đúng Zca-only, nếu không Zcb/Zcmp
  binary sẽ trap.
- **Open O-CDEC-02:** L4 cần fault/interrupt ở từng vị trí push/pop cho OpenTitan.

## 10. L4 handoff

Test all legal Zca classes, reserved patterns, cross-word 32-bit versus 16-bit,
Zcmp push/pop lists, downstream stall, flush giữa expansion và interrupt pending.

Signals: state, valid/ready, output instruction, illegal, expansion enum/original,
register-list counters.

## 11. Source anchors

- [`rtl/ibex_compressed_decoder.sv`](../../../../rtl/ibex_compressed_decoder.sv)
- [`rtl/ibex_pkg.sv`](../../../../rtl/ibex_pkg.sv)

