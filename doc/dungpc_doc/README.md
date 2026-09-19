# Phân tích vi kiến trúc Ibex — cấu hình `opentitan` (bản CHERIoT-Ibex)

Tài liệu này phân tích chi tiết RTL của lõi Ibex tại `/home/dungpc/projects/cpu_fx1/ibex`,
cho **cấu hình `opentitan`** khai báo trong [`ibex_configs.yaml`](../ibex/ibex_configs.yaml).

> **Lưu ý quan trọng về phiên bản repo**
> Đây **không phải** Ibex upstream lowRISC "thuần". Đây là nhánh **CHERIoT-Ibex**
> (có thêm `ibex_cheriot_ex.sv`, `ibex_cheriot_pkg.sv`, `ibex_trvk.sv`).
> Trong repo này cấu hình `opentitan` đặt `BaseIsa = ibex_pkg::BaseIsaRV32IorCHERIoT`,
> tức lõi hỗ trợ **dual base ISA**: RV32I và CHERIoT, chuyển đổi **lúc runtime** qua
> chân `cheriot_enable_i` (multi-bit, một chiều). Toàn bộ tài liệu bám theo thực tế đó.

## Mục lục

| # | Tệp | Nội dung |
|---|-----|----------|
| 00 | [00_tong_quan_cau_hinh.md](00_tong_quan_cau_hinh.md) | Tham số cấu hình, các tham số dẫn xuất, ISA được hỗ trợ, ngân sách tài nguyên |
| 01 | [01_phan_cap_module.md](01_phan_cap_module.md) | Cây phân cấp module, sơ đồ khối, danh sách tín hiệu liên tầng |
| 02 | [02_tang_ibex_top.md](02_tang_ibex_top.md) | Tầng bọc: clock gating, register file, scrambling, RAM I$, lockstep, TRVK, alert |
| 03 | [03_tang_IF.md](03_tang_IF.md) | Tầng IF: PC mux, kiểm tra PCC, compressed decoder, dummy instr, thanh ghi IF/ID |
| 04 | [04_icache.md](04_icache.md) | I-Cache: IC0/IC1, fill buffer, skid buffer, ECC, scramble, tweak infection, FSM invalidate |
| 05 | [05_tang_ID.md](05_tang_ID.md) | Tầng ID: decoder, controller FSM, operand mux, hazard/forwarding, ID-EX FSM |
| 06 | [06_tang_EX.md](06_tang_EX.md) | Tầng EX: ALU (adder/comparator/shifter/bitmanip), Branch-Target ALU, MUL/DIV |
| 07 | [07_cheriot_ex.md](07_cheriot_ex.md) | Khối CHERIoT EX + định dạng capability + kiểm tra bound/permission |
| 08 | [08_lsu.md](08_lsu.md) | Load-Store Unit: FSM chính, FSM nhận capability, align/sign-extend, ECC |
| 09 | [09_tang_WB.md](09_tang_WB.md) | Tầng Writeback: thanh ghi WB, forwarding, outstanding load/store |
| 10 | [10_csr_pmp_counter.md](10_csr_pmp_counter.md) | CSR, SCR CHERIoT, ePMP/Smepmp, HPM counters, debug trigger |
| 11 | [11_security.md](11_security.md) | Toàn bộ biện pháp đối phó khi `SecureIbex=1` |
| 12 | [12_pipeline_timing.md](12_pipeline_timing.md) | Timing pipeline, bảng stall, hazard, exception/interrupt/debug |
| 13 | [13_mo_phong_vcs.md](13_mo_phong_vcs.md) | **Hướng dẫn mô phỏng bằng VCS** (đã chạy kiểm chứng trên máy này) |
| 14 | [14_flow_test_riscv_arithmetic_basic.md](14_flow_test_riscv_arithmetic_basic.md) | Flow test `riscv_arithmetic_basic_test`: sinh gì, test gì, kiểm tra ra sao |
| — | [verdi/](verdi/) | Verdi signal file (`.rc`) + script mở waveform — 148 tín hiệu / 16 nhóm |

## Cách đọc

* Mọi tham chiếu mã nguồn ghi dạng `tệp:dòng` để mở nhanh trong IDE. Số dòng là
  **mốc gần đúng** (± vài dòng) cho khối logic được mô tả, không phải dòng chính xác;
  hãy tìm theo tên tín hiệu/tên khối `generate` được trích dẫn kèm theo.
* Ký hiệu `_d`/`_q` theo quy ước Ibex: `_d` là giá trị tổ hợp kế tiếp, `_q` là đầu ra flop.
* Các khối `if (Param) begin : g_xxx` được đánh dấu **[BẬT]** / **[TẮT]** theo cấu hình `opentitan`.
