# Cửa sổ throughput hữu hạn

Đếm RVFI từ instruction đầu tới marker x31=123, loại toàn bộ JAL kết thúc. 
`IPC_interval=(N-1)/(cycle_last-cycle_first)` là tốc độ giữa hai mốc retirement;
không bao gồm boot/fill đầu, không phải IPC steady-state hay tổng benchmark.
Chương trình control gồm branch không taken, taken, JAL và JALR. `gap` là khoảng
RVFI giữa branch và instruction đích; `gap-1` là bubble quan sát, có thể gồm fetch stall.

| Config | Memory | N | Δcycles | IPC_interval | NT gap | taken gap | JAL gap | JALR gap |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| small | d1 | 8 | 11 | 0.636 | 1 | 3 | 1 | 1 |
| small | d4 | 8 | 33 | 0.212 | 3 | 9 | 5 | 5 |
| wb | d1 | 8 | 11 | 0.636 | 1 | 3 | 1 | 1 |
| wb | d4 | 8 | 33 | 0.212 | 3 | 9 | 5 | 5 |
| bt | d1 | 8 | 10 | 0.700 | 1 | 2 | 2 | 2 |
| bt | d4 | 8 | 30 | 0.233 | 3 | 6 | 6 | 6 |
| single | d1 | 8 | 10 | 0.700 | 1 | 2 | 2 | 2 |
| single | d4 | 8 | 30 | 0.233 | 3 | 6 | 6 | 6 |
| slow | d1 | 8 | 11 | 0.636 | 1 | 3 | 1 | 1 |
| slow | d4 | 8 | 33 | 0.212 | 3 | 9 | 5 | 5 |

D1 và D4 là hai memory contracts của [01](01_configuration.md). Không cộng
memory/load-use/ID stall counters vì cùng một chu kỳ có thể thuộc nhiều điều kiện.
ALU liên tiếp có gap=1 khi IF cung cấp đủ; WB/BT thay đổi bubble và ownership,
không biến core thành superscalar. [Script](scripts/summarize_extended.py) và
[dữ liệu](evidence/extended/throughput.json) giúp tính lại bảng.

## Branch penalty đo từ ID

Định nghĩa `P = first_valid_ID(target) - first_valid_ID(control) - 1`.
P gồm hold của control instruction và khoảng redirect/fetch tới target.
Đây là số chu kỳ mất thêm so với hai instruction ID liên tiếp; D4 còn có memory stalls.
Khác với RVFI gap: control có thể retire trễ, nên JAL RVFI gap=1 vẫn có penalty.

| Config | Memory | NT P | Taken P | JAL P | JALR P |
|---|---|---:|---:|---:|---:|
| small | d1 | 0 | 2 | 1 | 1 |
| small | d4 | 2 | 8 | 5 | 5 |
| wb | d1 | 0 | 2 | 1 | 1 |
| wb | d4 | 2 | 8 | 5 | 5 |
| bt | d1 | 0 | 1 | 1 | 1 |
| bt | d4 | 2 | 5 | 5 | 5 |
| single | d1 | 0 | 1 | 1 | 1 |
| single | d4 | 2 | 5 | 5 | 5 |
| slow | d1 | 0 | 2 | 1 | 1 |
| slow | d4 | 2 | 8 | 5 | 5 |
