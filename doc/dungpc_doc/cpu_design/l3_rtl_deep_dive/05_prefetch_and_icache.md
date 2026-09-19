# 05 — Deep dive prefetch buffer và I-cache

## 1. Hai implementation loại trừ nhau

IF instantiate `ibex_icache` khi `ICache=1`, ngược lại dùng
`ibex_prefetch_buffer`. Cả hai xuất cùng abstract stream: valid/data/address/
error và nhận ready/branch redirect.

FX1 chỉ dùng prefetch; OpenTitan là reference duy nhất trong scope dùng cache.

## 2. Prefetch composition

`ibex_prefetch_buffer` dùng fetch FIFO để:

- giữ outstanding instruction requests;
- ghép instruction 32-bit bắt đầu tại halfword offset 2;
- buffer response khi ID back-pressured;
- discard stale words sau branch redirect;
- chuyển bus error đúng halfword.

Request address word-aligned trong bus, còn stream address giữ bit 1 để chọn
halfword.

## 3. Redirect contract

`branch_i` + `addr_i` là authoritative new stream. Outstanding response cũ vẫn
có thể đến và phải được nhận/discard theo FIFO bookkeeping. Không được dùng
external bus cancellation trừ khi protocol định nghĩa rõ; Ibex xử lý stale
response nội bộ.

**Invariant I-FE-01:** Outstanding count không âm/overflow và stale response
không trở thành instruction valid sau redirect.

## 4. I-cache geometry

Constants trong `ibex_pkg`:

- 4 KiB total;
- 2 ways;
- line 64 bit = 2 bus beats;
- 256 indices/way;
- four fill buffers, throttle threshold two.

Tag chứa valid; ECC mở rộng tag/data widths khi enabled. Physical RAMs ở top.

## 5. Hit path

Fetch address tách index/tag/beat. Tag/data reads đi qua one-cycle RAM behavior;
ways match valid+tag. Selected beat tạo 32-bit stream. Replacement và branch
redirect phải giữ association address/data.

**Critical candidate:** RAM output → ECC decode → tag compare/way select → fetch
data/valid.

## 6. Miss/fill path

Fill buffer theo dõi line address, requested beats, returned data/error và target
RAM write. Multiple fill buffers cho phép miss/redirect overlap có giới hạn.
Demand word có thể được trả từ fill path trước khi toàn line commit nếu control
cho phép.

Throttling ngăn tạo nhiều fill hơn storage/ordering có thể chịu. External bus vẫn
in-order theo assumptions của cache implementation.

## 7. Invalidate FSM

States:

- `OUT_OF_RESET`;
- `AWAIT_SCRAMBLE_KEY`;
- `INVAL_CACHE`;
- `INVAL_IDLE`.

Scrambled cache không được coi contents hợp lệ trước key và invalidate. Invalidate
đi qua mọi index/way validity state; fetch busy phản ánh quá trình này.

## 8. ECC and tweak infection

Tag dùng SECDED 28/22 và mỗi 32-bit data beat dùng 39/32 trong OpenTitan setup.
Line RAM width là hai encoded beats. Tweak infection XOR/mix address-derived
information vào stored representation để address substitution gây ECC/tag
failure thay vì dữ liệu hợp lệ sai vị trí.

ECC error tạo cache error/alert; sửa được hay không phải đọc primitive semantics,
không suy từ tên `ecc_error` duy nhất.

## 9. Scramble key lifecycle

Cache phát `ic_scr_key_req`, nhận key-valid và RAM top nhận key/nonce. New key
đòi invalidate vì ciphertext cũ không giải mã dưới key mới. Request/key handshake
phải đồng bộ với clock gating và cache busy.

## 10. Error semantics

Bus error được gắn beat/fill. Cross-word instruction có thể nhận error ở nửa
hai; stream phải giữ `err_plus2`. ECC/tag faults không được biến thành silent
miss nếu policy yêu cầu alert.

## 11. Configuration differences

| Feature | OpenTitan | FX1 |
|---|---|---|
| Front end | I-cache | prefetch buffer |
| ECC | tag+data | none in absent cache |
| Scramble | active | absent |
| Runtime cache CSR | meaningful | tie/ignored behavior |
| Fill/invalidate FSM | active | absent |

## 12. Assertions and open items

- FIFO request/response accounting.
- Stable request until grant.
- Fill buffer allocation uniqueness.
- Cache RAM request validity.
- ECC error-to-alert propagation.

**Open O-FE-01:** L4 should determine exact miss/refill latency rather than
copying expected cycles from documentation. **Open O-FE-02:** FX1 must verify
firmware does not depend on cache-control timing/status.

## 13. L4 handoff

Prefetch: aligned/cross-word fetch, redirect with outstanding response, grant/
response delay, bus error first/second half. Cache: hit, cold miss, fill overlap,
invalidate, new scramble key, ECC injection.

## 14. Source anchors

- [`rtl/ibex_prefetch_buffer.sv`](../../../../rtl/ibex_prefetch_buffer.sv)
- [`rtl/ibex_fetch_fifo.sv`](../../../../rtl/ibex_fetch_fifo.sv)
- [`rtl/ibex_icache.sv`](../../../../rtl/ibex_icache.sv)
- [`rtl/ibex_pkg.sv`](../../../../rtl/ibex_pkg.sv)

