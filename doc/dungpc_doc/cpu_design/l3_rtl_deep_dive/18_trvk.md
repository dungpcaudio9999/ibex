# 18 — Deep dive CHERIoT tag revocation (`ibex_trvk`)

## 1. Contract

TRVK là transparent D-side interceptor, ngoại trừ capability-load response tag.
Normal request/data/error đi qua; tagged capability có thể cần bitmap lookup và
returned tag bị clear nếu revoked hoặc lookup lỗi.

## 2. Explicit assumption

RTL nêu: tagged capability load tới downstream dưới dạng đúng hai response 32-bit
liên tiếp, không xen kẽ, từ single in-order requester. Bus không có transaction
ID để TRVK tự phục hồi nếu assumption sai.

**Assumption A-TRVK-01:** Interconnect preserves grant/response order and two-beat
capability contiguity.

## 3. Upstream request fork

`stream_fork` yêu cầu cả:

- downstream request consumer ready;
- alignment FIFO ready.

Chỉ khi cả hai handshake thì upstream được grant. FIFO lưu address bit 2 để biết
word là lower/upper half của 64-bit alignment.

## 4. Downstream response FIFO

Every response packs data, integrity, tag, error vào FIFO depth
`NumOutstanding` (top passes 2). Join logic chỉ trả upstream khi response và,
nếu required, bitmap result đều available.

Assertion yêu cầu no FIFO overflow; integration phải honor back-pressure at
request level vì downstream response interface không có ready.

## 5. Pointer storage

Lower capability word được nhận diện bởi tag và alignment flag. Data saved as
pointer, cùng valid state. Metadata word sau được parse:

- compressed base mantissa;
- exponent;
- object type;
- compressed permissions.

Sealing class ảnh hưởng lookup eligibility.

## 6. Base reconstruction

TRVK mở rộng exponent, lấy address-mid từ pointer, tính correction cho base và
reconstruct absolute `cap_base`. Then:

```text
relative = cap_base - heap_base
bit_addr = relative >> log2(8 bytes/cap)
word_addr = bit_addr / 32
bit_select = bit_addr % 32
```

External bitmap address thêm `RevBitmapBaseAddr` và scale byte word address.
High bits phát hiện capability ngoài bitmap range.

## 7. Lookup qualification

Lookup required khi response là tagged capability metadata, pointer buffer valid,
not sealing capability và address nằm trong supported revocation domain/range
theo logic. One outstanding bitmap request tracked by flop; request giữ đến
grant và join chờ response.

## 8. Tag result/fail-safe

```text
upstream_tag = downstream_tag
             && !(bitmap says revoked)
             && no lookup failure
```

Device error, integrity error hoặc revoked bit được xử lý fail-closed bằng clear
tag. Data vẫn forward để software có pointer bits nhưng không còn authority.

## 9. Bitmap ECC

`MemECC=1` instantiate SECDED 39/32 decoder; error only reported khi bitmap
response valid. `MemECC=0` ignores integrity input and only device error/revoked
bit matter. Top maps both bitmap errors to major bus alert.

## 10. Join/back-pressure

`stream_join_dynamic` chọn response-only hoặc response+bitmap based on
`revbm_req_required`. Required flag phải persist qua request/response latency;
otherwise join could release capability before revocation result.

## 11. Assertions

- Alignment metadata exists for every delivered response.
- Downstream response FIFO never overflows.
- No unsolicited bitmap response.
- Bitmap request address/control stable until grant.
- Outstanding bitmap state consistent.

## 12. Boundary/error cases

- untagged data response: no lookup;
- tagged but misaligned pair: must not combine incorrectly;
- sealing capability: bypass per policy;
- outside bitmap range: tag policy must match design requirement;
- bitmap bit 0/1;
- bus error/integrity error;
- downstream error in either capability beat;
- two outstanding D-side responses.

## 13. Findings

- **Fact F-TRVK-01:** TRVK active by compile-time BaseIsa even when runtime RV32.
- **Fact F-TRVK-02:** Revocation failure clears tag and also raises bus alert for
  device/integrity errors.
- **Assumption A-TRVK-02:** Response FIFO sizing relies on top maximum outstanding=2.
- **Open O-TRVK-01:** Confirm out-of-range and sealing bypass behavior against
  FX1 security requirements.
- **Open O-TRVK-02:** Stress response ordering/back-pressure with L4 assertions.

## 14. L4 handoff

Normal data, aligned/misaligned tagged pair, revoked/nonrevoked, sealing,
out-of-range, heap underflow/overflow, bitmap grant delay, device/ECC error,
two outstanding responses và reset while lookup pending.

## 15. Source anchors

- [`rtl/ibex_trvk.sv`](../../../../rtl/ibex_trvk.sv)
- [`rtl/ibex_top.sv`](../../../../rtl/ibex_top.sv)
- [`rtl/ibex_cheriot_pkg.sv`](../../../../rtl/ibex_cheriot_pkg.sv)

