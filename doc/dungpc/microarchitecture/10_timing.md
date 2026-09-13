# 10 — Timing đo từ RTL simulation

SIM — Sinh bằng `scripts/analyze_traces.py`. Cycle lấy trước NBA của cạnh lên; `C` là pipeline/control, `W` là cổng RF write, `R` là RVFI, `D` là accepted data transaction. Số chu kỳ ID bao gồm mọi lần valid tại PC đó trước sentinel; không bao gồm fetch trước khi vào ID.

## Latency execution và thời điểm đạt signature

| Config | Bus | MUL tại 0x8c: cycles ID | MULH tại 0x9c | DIV tại 0x90 | Arithmetic: cycle ghi x31 | Memory: cycle ghi x31 |
|---|---|---:|---:|---:|---:|---:|
| small | d1 | 3 | 4 | 37 | 168 | 18 |
| small | d4 | 3 | 4 | 37 | 184 | 50 |
| wb | d1 | 3 | 4 | 37 | 169 | 15 |
| wb | d4 | 3 | 4 | 37 | 185 | 50 |
| bt | d1 | 3 | 4 | 37 | 168 | 18 |
| bt | d4 | 3 | 4 | 37 | 184 | 50 |
| single | d1 | 1 | 2 | 37 | 165 | 15 |
| single | d4 | 1 | 2 | 37 | 185 | 50 |
| slow | d1 | 5 | 33 | 37 | 199 | 18 |
| slow | d4 | 5 | 33 | 37 | 214 | 50 |

MUL/MULH ở bảng này dùng toán hạng cụ thể của chương trình. Slow MUL có early termination; không dùng số đo đó cho mọi toán hạng. Cycle signature tính cả boot/fetch/stalls, không phải CPI steady-state. D4 có cả response latency 4 và grant mỗi 3 cycle; không phải chỉ tăng latency RAM.

## Load-use, split access và side effects

### small.memory.d1

[Log gốc](evidence/small.memory.d1.log) · [Waveform gzip](evidence/small.memory.d1.vcd.gz)

| Cycle | PC ID | Valid | FSM | mem stall | load hazard | done ID | req/gnt | response | RF write | RVFI PC |
|---:|---|---:|---|---:|---:|---:|---|---:|---|---|
| 3 | 00000080 | 1 | FIRST | 0 | 0 | 1 | 0/0 | 0 | x1=00000200 | — |
| 4 | 00000084 | 1 | FIRST | 0 | 0 | 1 | 0/0 | 0 | x2=00000055 | 00000080 |
| 5 | 00000088 | 1 | FIRST | 1 | 0 | 0 | 1/1 | 0 | — | 00000084 |
| 6 | 00000088 | 1 | MULTI | 0 | 0 | 1 | 0/0 | 1 | — | — |
| 7 | 0000008c | 1 | FIRST | 1 | 0 | 0 | 1/1 | 0 | — | 00000088 |
| 8 | 0000008c | 1 | MULTI | 0 | 0 | 1 | 0/0 | 1 | x3=00000055 | — |
| 9 | 00000090 | 1 | FIRST | 0 | 0 | 1 | 0/0 | 0 | x4=00000056 | 0000008c |
| 10 | 00000094 | 1 | FIRST | 1 | 0 | 0 | 1/1 | 0 | — | 00000090 |
| 11 | 00000094 | 1 | MULTI | 1 | 0 | 0 | 1/1 | 1 | — | — |
| 12 | 00000094 | 1 | MULTI | 0 | 0 | 1 | 0/0 | 1 | — | — |
| 13 | 00000098 | 1 | FIRST | 1 | 0 | 0 | 1/1 | 0 | — | 00000094 |
| 14 | 00000098 | 1 | MULTI | 1 | 0 | 0 | 1/1 | 1 | — | — |
| 15 | 00000098 | 1 | MULTI | 0 | 0 | 1 | 0/0 | 1 | x5=00000056 | — |
| 16 | 0000009c | 1 | FIRST | 1 | 0 | 0 | 1/1 | 0 | — | 00000098 |
| 17 | 0000009c | 1 | MULTI | 0 | 0 | 1 | 0/0 | 1 | x6=00000000 | — |
| 18 | 000000a0 | 1 | FIRST | 0 | 0 | 1 | 0/0 | 0 | x31=0000007b | 0000009c |
| 19 | 000000a4 | 1 | FIRST | 0 | 0 | 0 | 0/0 | 0 | — | 000000a0 |

### wb.memory.d1

[Log gốc](evidence/wb.memory.d1.log) · [Waveform gzip](evidence/wb.memory.d1.vcd.gz)

| Cycle | PC ID | Valid | FSM | mem stall | load hazard | done ID | req/gnt | response | RF write | RVFI PC |
|---:|---|---:|---|---:|---:|---:|---|---:|---|---|
| 3 | 00000080 | 1 | FIRST | 0 | 0 | 1 | 0/0 | 0 | — | — |
| 4 | 00000084 | 1 | FIRST | 0 | 0 | 1 | 0/0 | 0 | x1=00000200 | — |
| 5 | 00000088 | 1 | FIRST | 0 | 0 | 1 | 1/1 | 0 | x2=00000055 | 00000080 |
| 6 | 0000008c | 1 | FIRST | 0 | 0 | 1 | 1/1 | 1 | — | 00000084 |
| 7 | 00000090 | 1 | FIRST | 0 | 1 | 0 | 0/0 | 1 | x3=00000055 | 00000088 |
| 8 | 00000090 | 1 | FIRST | 0 | 0 | 1 | 0/0 | 0 | — | 0000008c |
| 9 | 00000094 | 1 | FIRST | 1 | 0 | 0 | 1/1 | 0 | x4=00000056 | — |
| 10 | 00000094 | 1 | MULTI | 0 | 0 | 1 | 1/1 | 1 | — | 00000090 |
| 11 | 00000098 | 1 | FIRST | 1 | 0 | 0 | 1/1 | 1 | — | — |
| 12 | 00000098 | 1 | MULTI | 0 | 0 | 1 | 1/1 | 1 | — | 00000094 |
| 13 | 0000009c | 1 | FIRST | 0 | 0 | 1 | 1/1 | 1 | x5=00000056 | — |
| 14 | 000000a0 | 1 | FIRST | 0 | 0 | 1 | 0/0 | 1 | x6=00000000 | 00000098 |
| 15 | 000000a4 | 1 | FIRST | 0 | 0 | 0 | 0/0 | 0 | x31=0000007b | 0000009c |
| 16 | 000000a4 | 1 | MULTI | 0 | 0 | 1 | 0/0 | 0 | — | 000000a0 |

Ở WB1 cycle 7, load response đã tới và x3 được ghi nhưng dependent ADD tại 0x90 vẫn có load hazard. Cycle 8 mới execute. Đường store→load không phụ thuộc data có thể chuyển instruction tại chính response cycle. RF write và RVFI là hai mốc khác nhau.

## Redirect và memory chậm

| Config/bus | BEQ not-taken 0x84: cycles ID | BEQ taken 0x8c | JAL 0x94 | JALR 0xa0 | Cycle target 0xa8 vào ID |
|---|---:|---:|---:|---:|---:|
| small/d1 | 1 | 2 | 2 | 2 | 14 |
| small/d4 | 1 | 2 | 2 | 2 | 41 |
| bt/d1 | 1 | 1 | 1 | 1 | 13 |
| bt/d4 | 1 | 1 | 1 | 1 | 38 |
| wb/d1 | 1 | 2 | 2 | 2 | 14 |
| wb/d4 | 1 | 2 | 2 | 2 | 41 |
| single/d1 | 1 | 1 | 1 | 1 | 13 |
| single/d4 | 1 | 1 | 1 | 1 | 38 |

BTALU giảm chu kỳ chiếm ID cho taken branch/jump. Refill delay vẫn phụ thuộc fetch bus. Các giá trị target absolute trong bảng không phải branch penalty của một instruction cô lập.

## IRQ/debug giữa operation dài

| Test (wb, D4) | Cycle phát event | Cycle ghi x3 của operation đang chạy | Cycle ghi marker handler |
|---|---:|---:|---:|
| event1 | 24 | 28 | 45 |
| event2 | 24 | 28 | 36 |
| event3 | 23 | 60 | 78 |
| event4 | 23 | 60 | 69 |

event1/2: timer IRQ/debug khi load pending; event3/4: khi divider đang stall. Marker handler xuất hiện sau completion của operation đang chạy. Đây không phải đo trực tiếp latency từ IRQ đến entry: handler còn fetch và chạy instructions trước marker.
