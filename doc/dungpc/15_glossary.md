# 15 — Thuật ngữ và namespace

| Từ | Nghĩa trong repository/báo cáo |
|---|---|
| BASE-01 | Snapshot source commit+hash+patch của phiên 2026-09-08 |
| CFG-*-intent / CFG-*-source | Ý định YAML / cấu hình suy từ source, chưa active elaboration |
| Active | Chỉ dùng không điều kiện khi có compile/elaboration evidence; phiên này còn UNKNOWN |
| IF / ID/EX / WB | Fetch; decode/execute; writeback logic/tầng pipeline tùy parameter |
| Architectural instruction / bus word | Một instruction có thể tạo hai word requests; không gộp hai capacity |
| Req / gnt / rvalid | Phát request / accept / response completion; không là ready/valid một channel duy nhất |
| Host / device | Tên RTL bus; tương ứng manager/subordinate, giữ signal names nguyên bản |
| Outstanding / discard / flush | Accepted chưa response / response phải drain nhưng bỏ data / hủy pipeline contents |
| RVFI / DII | Retirement observation / direct instruction injection; không tự là correctness checker |
| PMP / Smepmp | Region protection và machine security configuration; có gating theo CHERIoT mode |
| MuBi | Multi-bit control; IbexMuBiOn=0101, Off=1010 trong ibex_pkg |
| CHERIoT / BaseIsa | Capability extension/runtime mode / lựa chọn phần cứng compile-time |
| cap_t / decoded_cap_t | Metadata compressed35 bits trong RF / working112 bits; pointer32 tách riêng |
| PCC / SR / sentry | Program counter capability / system register permission / sealed control-transfer capability form |
| TRVK / revbm | Temporal revocation filter / bitmap service qua port riêng |
| Tag / integrity | Capability validity / ECC check bits; không là transaction IDs |
| mtime / mtimecmp | Counter64 / deadline64 của timer mẫu; IRQ sticky |
| SPEC:DECLARED | Tài liệu/comment xác định intent, không chứng minh RTL tuân thủ |
| RTL:ESTABLISHED | Fact scoped từ source semantics; cần nói rõ chưa elaborate |
| STATIC:ESTABLISHED | Named static extraction/check result; ở đây path/config audit, không semantic lint |
| SIM:OBSERVED | Named execution observation; EVD-06/07 **chỉ Python model**, không HDL |
| FORMAL:NOT-RUN | Chưa chạy property; không phải bounded pass/proof |
| SUPPORTED / INFERRED / ASSUMED / UNKNOWN | Mức support riêng với evidence kind/result, không trộn confidence thành tool status |
| CURRENT / NEEDS-RECHECK / SUPERSEDED | Freshness theo baseline/dependency |

Namespaces ổn định: REQ yêu cầu phân tích tái dựng; FND phát hiện; EVD artifact/check; ASM giả định; INV lập luận bất biến; PROP property formal; FLOW luồng; EXP thí nghiệm; OQ câu hỏi mở; CHG thay đổi giả định; WVR waiver (phiên này không cấp WVR).

Area tags: BUILD/CFG cấu hình, ARCH kiến trúc, BOOT khởi động, IF fetch, LSU memory unit, MEM map, TMR timer, IRQ ngắt, CLK/PWR clock/power, CSR thanh ghi điều khiển, CHERI/CAP/TRVK capability, SEC security, DV verification. Identifier không được tái dùng khi kết luận thay đổi; giữ record lịch sử và liên kết supersedes nếu cần.
