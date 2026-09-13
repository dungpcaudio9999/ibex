# 01 — Cấu hình và bằng chứng thực thi

## Baseline

Phân tích tại revision `fc3b3dd6` (hash đầy đủ trong [baseline](evidence/baseline.json)).
Đối chiếu `git diff 8031c7dd HEAD -- rtl ibex_configs.yaml ibex_core.core ibex_top.core
examples/simple_system` không có chênh lệch. Điều này cho phép kế thừa các dẫn chứng
nguồn cũ trong phạm vi đó; môi trường thực thi đã khác: có Verilator 5.020.

Các thí nghiệm mới sử dụng **harness trực tiếp `ibex_core` + `ibex_register_file_ff`**.
Đây là cấu hình active của harness, không phải bằng chứng build Simple System,
UVM hoặc named configuration qua FuseSoC đã hoạt động. RF thật được instantiate;
không thay RF bằng mảng trong testbench. Mảng `shadow` chỉ quan sát cổng ghi RF.

## Ma trận active

| Tên thí nghiệm | WB | BranchTargetALU | RV32M | Ý nghĩa |
|---|---:|---:|---|---|
| small | 0 | 0 | Fast | Nền hai tầng |
| wb | 1 | 0 | Fast | Chỉ thêm tầng WB |
| bt | 0 | 1 | Fast | Chỉ thêm bộ cộng target |
| single | 1 | 1 | SingleCycle | Tương tác WB + BTALU + multiplier nhanh |
| slow | 0 | 0 | Slow | Đổi sang iterative multiplier |

Tất cả dùng BaseIsaRV32I, RV32E=0, RV32BNone, RV32Zca, RF FF, cache/predictor/
PMP/SecureIbex=0. `single` **không đồng nhất với YAML maxperf** vì vẫn giữ Zca.
`small` tái tạo các lựa chọn microarchitecture của YAML small ở core/RF boundary;
không bao gồm top clock gate. `boot_addr=0` ⇒ instruction đầu tại `0x80`.
Debug target của harness được đặt `0x40` để nằm trong ROM nhỏ.

Đường cấu hình được kiểm soát trực tiếp:

```text
run_core.py variants → verilator -GWB/-GBT/-GM → core_tb parameters
  → ibex_core parameters → IF / ID / EX / LSU / WB / CSR generate branches
RF FF được instantiate riêng; capability runtime Off.
```

Đầu file log có `CONFIG`; [build commands](evidence/small.build-command.json)
lưu source list và flags thật. Các file `Vcore_tb*.cpp` trong
`/tmp/ibex-microarchitecture/<config>` là sản phẩm elaboration/build, có thể tái tạo.
XML elaboration và bản trích hierarchy/parameters được giữ trong evidence cho
cả 5 cấu hình, ví dụ [WB hierarchy](evidence/wb.hierarchy.json).
File dependency thực tế của Verilator và hash bao gồm headers/primitive được
autoload được lưu tại [source dependencies](evidence/source_dependencies_sha256.json).
Không dùng `rtl/ibex_core.f` như filelist đầy đủ: nó thiếu package/module mới.

## Memory contract của harness

- Instruction/data là hai memory độc lập, 1024 word mỗi memory; địa chỉ index
  `[11:2]`. Không mô phỏng address map hoặc collision của SRAM trong SoC.
- Mỗi `req && gnt` tạo đúng một response, theo thứ tự; độ trễ tối thiểu một cycle.
- D1: grant mỗi cycle, response sau 1 cycle. D4: grant chỉ khi cycle chia hết cho
  3, response sau 4 cycle. **D4 đồng thời đổi grant và response**, nên không dùng
  chênh lệch D1/D4 để cô lập riêng một nguyên nhân.
- Read data lấy tại grant; store cập nhật byte lanes tại grant nếu transaction
  không được gán lỗi. Store đã accepted có thể có side effect trước retirement.
- Stimulus/response và cửa grant được đổi ở falling edge, DUT lấy ở rising edge.
  Trace `C` ghi giá trị trước NBA của cạnh lên; số cycle bắt đầu sau reset.
- Reset chỉ ở đầu core tests. Không có kiểm chứng reset giữa outstanding requests.

## Phân cấp bằng chứng

`SOURCE`: biểu thức/state đọc trực tiếp. `INFERRED`: hệ quả có giả định đã ghi.
`SIM`: quan sát thực tế có command/log/checker. `NOT-RUN`: chưa thực thi.

`--assert` không bật lại macro assertion của RTL: header
[prim_assert.sv](../../../vendor/lowrisc_ip/ip/prim/rtl/prim_assert.sv#L102)
chọn dummy macros khi `VERILATOR`. Các `$fatal` rõ ràng trong harness và checker
Python mới là checker thực sự ở đợt chạy này. Không gọi các run là formal proof,
ISA compliance hoặc regression đầy đủ.

## Nguồn

- [core parameters](../../../rtl/ibex_core.sv#L18), [YAML](../../../ibex_configs.yaml#L18).
- [harness](scripts/core_tb.sv), [runner/program encodings](scripts/run_core.py).
- [build/config gaps cũ](../13_open_questions.md): active harness giải quyết một
  phần OQ-01; không tự đóng OQ-02 về named config/UVM/FuseSoC.
