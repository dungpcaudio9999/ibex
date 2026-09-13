# Bảng số đo Secure Ibex

Tự sinh từ logs RTL bằng [script](scripts/summarize_experiments.py).

| Test | ID residence | Mult/div stall cycles |
|---|---:|---:|
| dit_off_zero | 2 | 1 |
| dit_off_nonzero | 37 | 36 |
| dit_on_zero | 37 | 36 |
| dit_on_nonzero | 37 | 36 |
| ditbranch_off_taken | 1 | 0 |
| ditbranch_off_nt | 1 | 0 |
| ditbranch_on_taken | 2 | 0 |
| ditbranch_on_nt | 2 | 0 |

| Fault test | Detector | First stable sample cycle |
|---|---|---:|
| secure.fault1 | ab | 5 |
| secure.fault2 | ab | 8 |
| secure.fault3 | rf | 103 |
| secure.fault4 | mismatch | 105 |
| secure.fault6 | pc | 100 |
| secure_dual.fault5 | mode | 100 |
| secure_dual.fault8 | rf | 102 |
| secure_dual.fault9 | ab | 16 |
| secure_offset2.fault3 | rf | 104 |
| secure_offset2.fault4 | mismatch | 106 |

Cycle label lấy root-clock counter. SAMPLE chạy negedge+1ns sau stimuli settle;
force RF/EX/PC/cap tại negedge cycle100, release110; mode invalid từ100.
Bus faults xuất hiện theo response, không ở100. Cache injection tại350..354,
first minor alert350. Đây là độ trễ của stimulus cụ thể, không bound cho mọi fault.
C/W/R ghi tại gated posedge trước state update; các vùng delta-cycle khác nhau
có thể lệch một nhãn cycle so với SAMPLE, nên dùng SAMPLE cho detector latency.

40 directed runs PASS; 31 additional analysis checks PASS.
Alert counter đếm số root cycles có alert, không phải số faults độc lập.
