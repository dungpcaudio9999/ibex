# 12 — Thí nghiệm, dự đoán và kết quả

BASE-01; tool/script/source hashes trong evidence manifests. Tất cả lệnh chạy từ root repository; Python 3.14.4, PyYAML6.0.3. Không randomization; seed NOT-APPLICABLE cho **các kiểm tra thực sự đã chạy**. RTL simulation, semantic lint/elaboration, formal, CDC/RDC/STA đều NOT-RUN.

## EXP-01 — Named configuration emission

Câu hỏi: option nào generator phát cho small/opentitan? Dự đoán từ known_fields: BaseIsa được đưa vào cả hai, small=RV32I và opentitan=dual. Lệnh `python3 util/ibex_config.py small fusesoc_opts` và tương tự `opentitan`. Actual: cả hai exit0; log [small](evidence/config_small.log), [opentitan](evidence/config_opentitan.log). Dự đoán khớp.

EVD-02 [STATIC:ESTABLISHED — kiểm tra generator option], scope chỉ text output của Python; không chứng minh FuseSoC chấp nhận option hay HDL parameter được apply. FND-BUILD-01/OQ-02. Input YAML/script đều hash ở EVD-01.

## EXP-02 — Manifest và source inventory

Câu hỏi: named fields và entry paths có đồng bộ? Dự đoán sau đọc source: BaseIsa thiếu ở manifest Simple; src_files.yml có các đường dẫn cũ. Lệnh `python3 doc/dungpc/evidence/source_audit.py`; actual exit0, tìm **8 cấu hình, 33 file RTL .sv, 25.816 dòng**, field BaseIsa không khai báo ở Simple manifest và ba missing paths được liệt kê ở Stage2. [Audit](evidence/source_audit.json), log EVD-03.

Đây là PyYAML/regex/path existence check, không SV parser hay clean lint. Exit0 nghĩa script chạy xong, **không phải dự án sạch lỗi**. Chưa biết consumer file cũ hoặc option parser behavior. FND-BUILD-01/02, OQ-02/03.

## EXP-03 — Thử thiết lập execution baseline

Câu hỏi: có thể launch build target tại môi trường này không? Dự đoán sau PATH probe: FuseSoC/Verilator không tồn tại trong PATH. Lệnh chính:

```bash
fusesoc --cores-root=. run --target=sim --setup --build-root=doc/dungpc/evidence/build/simple_system lowrisc:ibex:ibex_simple_system
```

Actual: **không khởi chạy process**, FileNotFoundError, exit_status=null; [setup log](evidence/simple_system_setup.log), version logs. EVD-04 [STATIC:NOT-RUN] cho build/elaboration. Đây là tool limitation tái lập được, không phải compile error của RTL và không phải successful bring-up. OQ-01.

## EXP-04 — Firmware build intent

`make -n -C examples/sw/simple_system/hello_test`: dự đoán print RISC-V compile/link/objcopy/srec commands; actual exit0, đúng dự đoán. [Log](evidence/firmware_dry_run.log), EVD-05 [STATIC:ESTABLISHED — dry-run command plan]. No ELF/no runtime outcome. Linker RAM+stack nằm trong data RAM từ kiểm tra nguồn; chưa có linked section overflow evidence.

## EXP-05 — Timer/address/bitmap arithmetic model

Câu hỏi: timer sticky khác level comparator ở đâu, instruction/data map khác nhau thế nào, bitmap width11 phủ bao nhiêu heap? [Model script](evidence/model_experiments.py) thực hiện phương trình hữu hạn đã đọc từ source, không instantiate HDL.

Dự đoán **trước chạy**: IRQ sau 10 cạnh = `[1,0,0,1,1,1,0,1,0,1]`; viết mtime lùi không clear, compare-write clear kể cả BE0; ba addresses 0x80/0x100080/0x200080 alias instruction index, chỉ data0x100080 thuộc RAM; bitmap2KiB phủ128KiB heap.

`python3 doc/dungpc/evidence/model_experiments.py`: actual exit0, `PREDICTIONS-MATCH-MODEL`, 10 timer edges, 12 address cases, covered_heap_bytes131072. [Full trace](evidence/model_positive.json), EVD-06 [SIM:OBSERVED **abstract Python model only**].

| Cạnh | Pre-state t/cmp/irq | Write offset/data/BE | Post-state t/cmp/irq |
|---|---|---|---|
| 1 | 0/0/0 | Không | 1/0/1 |
| 2 | 1/0/1 | 8/100/F | 2/100/0 |
| 3 | 2/100/0 | 0/150/F | 150/100/0 |
| 4 | 150/100/0 | Không | 151/100/1 |
| 5 | 151/100/1 | 0/0/F | 0/100/1 |
| 6 | 0/100/1 | Không | 1/100/1 |
| 7 | 1/100/1 | 8/1/F | 2/1/0 |
| 8 | 2/1/0 | Không | 3/1/1 |
| 9 | 3/1/1 | 8/0/0 | 4/1/0 |
| 10 | 4/1/0 | Không | 5/1/1 |

Giá trị t/cmp là decimal, offset và BE là hex. Model dùng defined two-state integers, arithmetic mask64; không mô hình hóa X, event scheduling, reset metastability, RAM collision, hoặc proof equivalence giữa Python và SystemVerilog. Dự đoán behavior RTL vẫn dựa source reasoning và cần run thật; FND-TMR-01/MEM-01, OQ-01/10.

## EXP-06 — Negative comparison

`python3 doc/dungpc/evidence/model_experiments.py --corrupt-check` lật observed IRQ bit tại cạnh5 ngay trước comparison. Dự đoán: nonzero exit và mismatch cạnh5. Actual exit1, `EXPECTED-NEGATIVE-DETECTED`, edge5; [trace âm](evidence/model_negative.json), EVD-07 [SIM:OBSERVED — chỉ model/comparator]. Positive trace được giữ file riêng nên không bị negative overwrite.

Kết luận: comparison này phát hiện corruption đó. Không sửa DUT/source, không phải RTL mutation hay đánh giá đầy đủ checker effectiveness.

## EXP-11 — Đối chiếu UVM enum macro emission

Trong bước rà soát cuối, generator được chạy thêm với invocation tương ứng `ibex_cmd.py`:

```bash
python3 util/ibex_config.py small vcs_opts --ins_hier_path core_ibex_tb_top --string_define_prefix IBEX_CFG_
```

Dự đoán từ `SimOpts.output`: prefix nối nguyên tên field, tạo `IBEX_CFG_BaseIsa` và `IBEX_CFG_RegFile`, không tự chuyển thành uppercase/snake case. Actual exit0, đúng dự đoán; còn phát `IBEX_CFG_RV32ZC`. Test top đọc `IBEX_CFG_BASE_ISA`/`IBEX_CFG_REG_FILE` và không forward RV32ZC ở parameter block đã đọc. EVD-09 [STATIC:ESTABLISHED — generator output + source comparison], [log](evidence/uvm_vcs_options.log), FND-BUILD-03.

Không chạy VCS và chưa có preprocessed DUT. Đây là mismatch tên option/consumer, actual hierarchy còn OQ-02; không dùng observation này làm bằng chứng một simulation đã chạy sai cấu hình.

## Các thí nghiệm RTL kế tiếp — NOT-RUN

| ID | Câu hỏi/dự đoán | Stimulus/quan sát/acceptance cần thiết | Ràng buộc trước chạy |
|---|---|---|---|
| EXP-07 | Req giữ tới grant, branch drain old response; không retire old PC | Delayed grant/response, branch/full/upper-half; xem req/addr/discard/IF valid/RVFI | Active config + enabled checker; ASM-BUS-01 |
| EXP-08 | LSU split giữ data/error đúng và không tạo duplicate | Offset0…3/type/sign, cả ordering gnt2/rvalid1, lỗi từng word; byte-memory scoreboard | WB0/1, reset epoch, end drain |
| EXP-09 | TRVK tag clear khi revoked/error, không overflow | Tagged pair, bitmap stall/bit/error/ECC, unsolicited response, reset pending; data-cap oracle | Mode On + memory tags/bitmap service + spec revision |
| EXP-10 | Wake và reset không mất obligation; timer RTL khớp contract | WFI+IRQ/global masks/test_en, reset pending, 10-edge timer trace và rollover | Root/gated domains, SVA activation, CDC/RDC scope |

Không ghi command-line giả cho harness chưa được xây. Cần chọn/build harness và lưu exact commands/tool/seed/source, cover triggers/negative behavior trước khi chuyển NOT-RUN thành OBSERVED/PROVED. Các tests trên không được tính vào số tests đã pass.

## Evidence run index

[run_checks.py](evidence/run_checks.py) tái chạy audit/model và ghi command/exit/expected-exit vào [check_runs.json](evidence/check_runs.json) cùng logs. EVD-08 giữ trích nguồn quan trọng, không là elaboration. [Artifact manifest](evidence/artifact_manifest.json) định danh script/log/report; không gán model observation thành RTL evidence khi trình bày kết luận.
