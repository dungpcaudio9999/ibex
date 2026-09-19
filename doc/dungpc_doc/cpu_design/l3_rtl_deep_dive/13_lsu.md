# 13 — Deep dive load-store unit

## 1. Contract

LSU nhận một CPU memory operation đã qua decode/capability policy và phát một
hoặc hai 32-bit bus transactions. Nó giữ control đến khi mọi response/error đủ
để tạo một architectural completion.

## 2. Request qualification

`cpu_req_valid` là request thường hợp lệ; `cpu_req_erred`/`lsu_cheriot_err`
cho phép completion có fault mà không phát external request. `lsu_go` đánh dấu
request được nhận nội bộ; `lsu_go_goodcap` khởi động two-response capability path.

PMP error xảy ra ở address phase và có thể ngăn external grant. FSM coi registered
PMP error như grant/completion surrogate để không deadlock.

## 3. Address and byte enables

External address luôn `{effective[31:2],2'b00}`. Byte enables theo type/offset:

- byte: one-hot;
- half: two adjacent, offset 3 tách 1+1;
- word: offset 0 all bytes, offsets 1/2/3 tách 3+1, 2+2, 1+3.

Second transaction enables complement phần còn lại. Write data rotate theo
offset; second request dùng cùng rotated word với byte mask tương ứng.

## 4. Misaligned state machine

| State | Work |
|---|---|
| `IDLE` | accept new op; issue first request |
| `WAIT_GNT_MIS` | first misaligned address chưa grant/PMP complete |
| `WAIT_RVALID_MIS` | wait response 1, attempt request 2 |
| `WAIT_GNT` | wait normal hoặc second grant |
| `WAIT_RVALID_MIS_GNTS_DONE` | request 2 granted before response 1 |

FSM hỗ trợ ba ordering: response1 trước grant2, cùng cycle, hoặc grant2 trước
response1. Saved `handle_misaligned`, `addr_last`, control và partial rdata duy
trì association.

**Invariant I-LSU-01:** Mỗi split access có tối đa hai grants và completion chỉ
phát sau response/error của mọi phần đã phát.

## 5. Load data reconstruction

First response upper bytes, original offset/type/sign được register. Khi final
response đến, barrel/concatenation tạo word đúng thứ tự little-endian rồi:

- word: unchanged;
- half: sign/zero extend bit 15;
- byte: sign/zero extend bit 7.

`lsu_rdata_valid` bị gate bởi final state, read direction, no bus/PMP/CHERIoT/
integrity error.

## 6. Error accounting

`data_or_pmp_err` hợp:

- saved error phần trước;
- current bus error;
- saved/current PMP error;
- CHERIoT policy error;
- capability first-beat error.

Load/store error outputs phân direction; response integrity có outputs riêng.
`addr_last_o` update theo accepted phases để controller đặt mtval đúng failing
address.

## 7. Capability request FSM

Additional states:

- `CTX_WAIT_GNT1`;
- `CTX_WAIT_GNT2`;
- `CTX_WAIT_RESP`.

Capability luôn hai word-aligned beats. Beat 1/2 encoding phụ thuộc load/store;
store second beat lấy `cheriot_cap_to_mem`, load sets tag request semantics.
Main FSM quản request completion; `cap_rx_fsm` quản response order:

```text
CRX_IDLE -> CRX_WAIT_RESP1 -> CRX_WAIT_RESP2 -> CRX_IDLE
```

First load beat data/tag/error được saved, second beat triggers
`cheriot_mem_to_cap` và permission clearing.

## 8. Protocol assumptions

- Responses in-order.
- Capability responses consecutive for the operation.
- At most one CPU LSU operation active, though it may own two bus requests.
- Data response corresponds to previously granted request.
- Control input held until `lsu_req_done` as documented.

Violation của assumptions có thể ghép sai data mà local FSM không đủ ID để phát
hiện vì bus không mang transaction ID.

## 9. Request-done versus response-valid

```text
req_done = operation accepted/address phases finished enough to leave ID
resp_valid = final response/error makes operation architecturally complete
```

Với WB, hai mốc tách nhau. `req_done` không cho phép retire hoặc load consumer
tiến nếu response chưa có.

## 10. Memory ECC

Store data encode SECDED 39/32 when enabled. Load decoder produces corrected data
và error indicators. FX1 generates this out, but top/LSU widths and unused/tieoff
must remain consistent.

## 11. Assertions/coverage

- LSU state in legal set.
- Stable request payload until grant.
- No response without expected operation.
- Misaligned first/second ordering coverage.
- PMP error without grant coverage.
- Capability response sequencing.
- No RF write on response error.

## 12. Findings

- **Fact F-LSU-01:** Maximum two D-side outstanding comes from one split/cap op,
  not speculative independent instructions.
- **Fact F-LSU-02:** PMP denial must progress without external grant.
- **Assumption A-LSU-01:** Bus responses are in order and untagged.
- **Open O-LSU-01:** Exhaust all grant/rvalid simultaneous permutations in L4.

## 13. L4 handoff

All sizes/offsets/signs; every two-request ordering; bus/PMP error each beat;
reset/redirect while pending; CLC/CSC first/second error/tag; ECC injection for
OpenTitan; long grant/response back-pressure.

## 14. Source anchors

- [`rtl/ibex_load_store_unit.sv`](../../../../rtl/ibex_load_store_unit.sv)
- [`rtl/ibex_cheriot_pkg.sv`](../../../../rtl/ibex_cheriot_pkg.sv)

