#!/usr/bin/env bash
# Mo waveform Ibex (cau hinh opentitan) bang Verdi voi signal file co san.
#
#   ./open_waves.sh                              -> mo test mac dinh
#   ./open_waves.sh <test>.<seed>                -> mo test khac
#   ./open_waves.sh /duong/dan/waves.fsdb        -> mo FSDB bat ky
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RC="$HERE/ibex_opentitan.rc"
DV="$(cd "$HERE/../../../dv/uvm/core_ibex" && pwd)"
DEFAULT_TDS="riscv_arithmetic_basic_test.1"

ARG="${1:-$DEFAULT_TDS}"
if [[ "$ARG" == *.fsdb ]]; then
  FSDB="$ARG"
else
  FSDB="$DV/out/run/tests/$ARG/waves.fsdb"
fi

if [[ ! -f "$FSDB" ]]; then
  echo "Khong tim thay FSDB: $FSDB" >&2
  echo "Chay test voi WAVES=1 truoc, vi du:" >&2
  echo "  cd $DV && make IBEX_CONFIG=opentitan SIMULATOR=vcs ISS=spike \\" >&2
  echo "       TEST=riscv_arithmetic_basic_test SEED=1 WAVES=1" >&2
  exit 1
fi

echo "FSDB : $FSDB"
echo "RC   : $RC"
exec verdi -nologo -ssf "$FSDB" -sswr "$RC" "${@:2}" &
