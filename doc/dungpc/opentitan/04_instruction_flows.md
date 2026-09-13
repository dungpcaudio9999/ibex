# 04 — Theo một instruction qua toàn CPU

Mỗi flow dưới đây gồm instruction acceptance, resource chiếm dụng, completion
và trường hợp bị chặn. Cycle occupancy là số cạnh T có PC hợp lệ ở ID cho một
lần thực thi; không phải tổng fetch-to-retire latency. Các trace dùng đúng preset,
không chuyển cấu hình multiplier hoặc bỏ cache hardware để có số đẹp hơn.

## ALU, B và M

Instruction được frontend đưa vào IF/ID; decoder chọn RF addresses, operand mux
và operator; forwarding có thể chọn WB thay RF; EX tính result; WB giữ destination
và kết quả; RF chỉ ghi khi write qualification hợp lệ. ADD nối tiếp trong ca
arithmetic có thể ghi mỗi cycle khi fetch cung cấp đủ lệnh và không có stall.

| Instruction cụ thể | PC | ID cycles quan sát | Đường và giới hạn |
|---|---|---:|---|
| ADD | `0x88` | 1 | RF/forwarding → ALU → WB |
| MUL | `0x8c` | 1 | Fast multiplier single-cycle option; không khái quát sang MULH/DIV |
| DIV | `0x90` | 37 | ID giữ lệnh qua divider state machine |
| MULH | `0x9c` | 2 | High product có trình tự riêng trong fast M/D |
| DIV by zero, DIT off | `0x90` trong ca DIT | 2 | Early-out |
| DIV by zero, DIT on | cùng PC | 37 | Early-out timing bị loại |
| DIV nonzero, DIT off/on | cùng PC | 37/37 | Hai chế độ dùng cùng opcode/operands |

Nguồn: [EX integration](../../../rtl/ibex_ex_block.sv),
[fast M/D](../../../rtl/ibex_multdiv_fast.sv),
[ID multicycle handling](../../../rtl/ibex_id_stage.sv#L885),
[measurement data](evidence/timing.json), [arithmetic trace](evidence/rv.arithmetic.log).

`RV32BOTEarlGrey` phải được đọc từ decoder ở revision này. Ví dụ các nhánh
`RV32BOTEarlGrey || RV32BFull` có thêm shuffle/xperm/carryless operations, còn
`bcompress` chỉ ở `RV32BFull`. Không gán một compiler extension string hiện đại
chỉ dựa vào tên enum. Ca `rv.bitmanip` kiểm ANDN, CPOP, CLZ và ROL với expected
`fffffffe, 32, 31, 2`; đây là các đại diện, không phải full B compliance.
Các operator dùng intermediate ALU state có thể giữ ID nhiều cycle.
[B legality](../../../rtl/ibex_decoder.sv#L646),
[B datapath generate](../../../rtl/ibex_alu.sv#L648),
[B trace](evidence/rv.bitmanip.log).

## Branch, jump, frontend redirect

BranchTargetALU tính target song song với ALU compare; BranchPredictor=0 loại bỏ
speculative predicted-target path. Taken branch/JAL/JALR vẫn redirect frontend,
nên “target tính trong một cycle” không có nghĩa “không có bubble”. Cache/fill
còn cần xử lý request của đường cũ, instruction alignment và valid gating.

Ở DIT on, cả branch taken và not-taken trong hai ca đều chiếm 2 cycle ID.
Trường hợp not-taken vẫn thực hiện flow timing điều khiển tương ứng nhưng target
kiến trúc là fall-through. Ca `rv.control` kiểm không thực thi các đoạn bị bỏ qua,
đúng link register JAL/JALR và completion marker. Đây là directed redirect
coverage; không phải exhaustive mọi redirect tại mọi fill-buffer occupancy.
[ID branch flow](../../../rtl/ibex_id_stage.sv#L900),
[IF PC selection](../../../rtl/ibex_if_stage.sv),
[control trace](evidence/rv.control.log).

## Scalar load/store và lỗi split access

EX cộng base/offset; PMP và LSU quyết định request hợp lệ; LSU giữ request tới
grant. WB giữ context của instruction trong khi đợi response. Load ráp bytes,
sign/zero extends rồi mới ghi RD; store không ghi RD nhưng vẫn có completion/error
để điều khiển precision. Một word unaligned có thể cần hai aligned bus beats.

Ca D4 tại `0x94` store word ở address `0x203`: grant cycle 30 cho address `0x200`,
BE `8`; grant cycle 33 cho `0x204`, BE `7`. Load lại tại `0x98` có hai grant cycle
39 và 42, destination x5 ghi `0x56` ở cycle 46. Cùng mô hình kiểm lỗi ở beat thứ
nhất và thứ hai; các oracle MEPC/MTVAL nằm trong results, không chỉ kiểm có trap.
[LSU](../../../rtl/ibex_load_store_unit.sv), [D4 memory trace](evidence/rv.memory_d4.log),
[first-beat error](evidence/rv.error_split_load_first.log),
[second-beat error](evidence/rv.error_split_load_second.log).

PMP kiểm trước khi đưa data request ra bus. Hai ca ghi locked NAPOT deny ở region
0 và 15 cùng chặn load `0x200`: cause 5, MEPC `0x94`, MTVAL `0x200`, không D/B
transaction. Region 15 quan trọng vì chứng minh preset có đủ region cao và CSR
packing đúng; chưa bao phủ mọi TOR/NA4/NAPOT/overlap/privilege permutation.
[PMP](../../../rtl/ibex_pmp.sv), [region15 trace](evidence/rv.pmp_region15.log).

## Zca/Zcb/Zcmp: instruction nguồn khác micro-operation

Frontend nhận 16-bit encoding rồi mở rộng sang đường decode thông thường. Với
Zcmp, expander còn giữ register list, stack offset và FSM; nhiều load/store/ADDI
nội bộ dùng cùng PC nguồn. Không được đếm mỗi RVFI record thành một `cm.push`
hay cho debug dừng ở giữa các phase bị cấm.

Ca `rv.zcmp` đặt SP `0x300`, RA 55, thực hiện push/pop RA, sau đó Zcb zext.b:
SP khôi phục `0x300`, RA vẫn 55, x8=`0xff`. Ca debug/IRQ kiểm các boundary riêng
trong [05_interactions](05_interactions.md). Trong mode CHERIoT On, encoding
Zcmp này illegal: cause 2 tại PC `0x80`, không data transfer. RTL cấm để tránh
thực hiện scalar stack sequence bỏ qua capability/tag semantics.
[Compressed/Zcmp decoder](../../../rtl/ibex_compressed_decoder.sv#L615),
[Zcmp trace](evidence/rv.zcmp.log), [CHERIoT illegal trace](evidence/cap.zcmp_illegal.log).

## Capability: completion kéo dài tới qualification của tag

Một CLC phải kiểm capability dùng làm địa chỉ: tag, permissions, bounds và các
điều kiện access tương ứng. LSU lấy hai word payload; đường CHERIoT giải nén
metadata và TRVK kiểm bitmap cho loaded capability khi cần. RD/tag hợp lệ chỉ
được công bố sau completion/qualification của flow. CGETTAG quan sát kết quả
kiến trúc này, không đọc tag sớm ở memory response.

Ca `cap.roundtrip` D4 tạo root-derived addressing capability tại `0x200`, load
c2, store c2 ở `0x208`, load lại c4 và CGETTAG:

| Sự kiện | Root cycle | Giá trị / ý nghĩa |
|---|---:|---|
| CLC c2 hai grants | 18, 21 | `0x200`, `0x204` |
| Bitmap request | 25 | Trước c2 write |
| c2 write | 31 | Cursor `0x1000`, metadata/tag `0x17e020000` |
| CSC c2 grants | 33, 36 | Payload `0x1000`, `0x7e020000`; tags 1 |
| CLC c4 grants | 42, 45 | `0x208`, `0x20c` |
| Bitmap request / c4 write | 49 / 55 | Không công bố trước bitmap |
| CGETTAG x5 | 57 | 1 |

Đối chứng revoked bitmap và bitmap ECC error đều làm CGETTAG trả 0; cursor vẫn
có thể giữ nguyên. Một địa chỉ scalar không tagged làm capability access trap
cause 28; csetbounds length 4 rồi CLC 8 byte cũng cause 28, MEPC `0x8c`, không
request bus. Cause 28 là giá trị quan sát ở checkout này, không suy một spec
khác. [CHERIoT EX](../../../rtl/ibex_cheriot_ex.sv),
[TRVK](../../../rtl/ibex_trvk.sv), [roundtrip trace](evidence/cap.roundtrip.log),
[bounds trace](evidence/cap.bound.log).

## CSR, counters, trap/debug

CSR read/modify/write nằm trong instruction flow, nhưng trap/debug có thể là
nguồn cập nhật CSR ưu tiên hơn software write. Khi viết firmware CHERIoT cần
dùng special capability MEPCC để lấy exception PC; scalar MEPC access không
được giả định hợp lệ như mode RV32I.

Counter 3…12 có event wiring cố định: data-wait, instruction-wait, load, store,
jump, branch, taken-branch, compressed-retire, mul-wait, div-wait. Không xem
MHPMEVENT như mux event tùy ý. Ca counters đo load counter=1, high half=0,
div-wait trước DIV=0/sau DIV=36, counter13=0, event12 mask=512. 37 cycle occupancy
DIV và 36 stall events là hai đại lượng nhất quán nhưng khác định nghĩa.
[CSR implementation](../../../rtl/ibex_cs_registers.sv),
[counter trace](evidence/rv.counters.log).
