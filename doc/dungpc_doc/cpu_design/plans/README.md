# Kế hoạch phân tích L3 và L4

Hai kế hoạch được chốt tại đây để làm chuẩn phạm vi:

- [01_l3_rtl_deep_dive_plan.md](01_l3_rtl_deep_dive_plan.md): phân tích tĩnh
  RTL ở mức module, state, phương trình, FSM, assertion và cấu hình.
- [02_l4_cycle_accurate_plan.md](02_l4_cycle_accurate_plan.md): xác minh động
  từng chu kỳ bằng testcase, waveform, RVFI và Spike.

Thứ tự mặc định là xoắn ốc: hoàn tất L3 cho một khối, sau đó ở giai đoạn L4 sẽ
dùng checklist waveform của chính khối đó để tạo bằng chứng thực thi.

