#!/usr/bin/env bash
# Cài toolchain để build/lint/synth Ibex.
#
# Môi trường đã dò: Ubuntu 26.04, có apt-get + pip3, KHÔNG có nix,
# sudo yêu cầu xác thực tương tác (nên script này phải chạy thủ công).
#
#   bash doc/dungpc/scripts/install_tools.sh            # cài tất cả
#   bash doc/dungpc/scripts/install_tools.sh python     # chỉ venv + fusesoc
#   bash doc/dungpc/scripts/install_tools.sh apt        # chỉ gói hệ thống (cần sudo)
#   bash doc/dungpc/scripts/install_tools.sh osscad      # chỉ OSS CAD Suite (không cần sudo)
#   bash doc/dungpc/scripts/install_tools.sh toolchain  # chỉ RISC-V GCC (không cần sudo)
set -euo pipefail

VENV="${IBEX_VENV:-$HOME/.ibex-venv}"
OPT="${IBEX_OPT:-$HOME/opt}"
WHAT="${1:-all}"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# ---------------------------------------------------------------- python
# fusesoc là build system của repo (Makefile gọi nó). Không cần root.
install_python() {
  log "venv + fusesoc  ->  $VENV"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --upgrade pip
  # Bám theo python-requirements.txt nhưng bỏ nhánh riscv-dv (nặng, chỉ cần cho UVM DV)
  "$VENV/bin/pip" install \
    "fusesoc==2.4.3" pyyaml mako packaging junit-xml pathlib3x typing-utils \
    "typeguard~=2.13" portalocker "pydantic>=2" svg.py hjson "mistletoe>=0.7.2" \
    "premailer<3.9.0" GitPython argparse
  "$VENV/bin/fusesoc" --version
  echo "Kích hoạt bằng:  source $VENV/bin/activate"
  echo
  echo "LƯU Ý: flake.nix:189 ghi rằng các file .core trong repo cần *bản fork lowRISC*"
  echo "của fusesoc. fusesoc 2.4.3 upstream (pin trong python-requirements.txt) đủ cho"
  echo "'--setup', nhưng nếu gặp lỗi parse .core thì đó là nguyên nhân."
}

# Nếu muốn đủ bộ cho UVM DV regression (nặng hơn nhiều):
#   "$VENV/bin/pip" install -r python-requirements.txt

# ------------------------------------------------------------------- apt
# Verilator/gtkwave/srecord từ apt. CẦN SUDO — chạy tay, nhập mật khẩu.
install_apt() {
  log "apt-get (cần sudo)"
  sudo apt-get update
  sudo apt-get install -y \
    verilator gtkwave srecord \
    build-essential cmake pkg-config git curl \
    libelf-dev zlib1g-dev libboost-all-dev \
    autoconf automake libtool flex bison \
    device-tree-compiler
  verilator --version
}

# -------------------------------------------------------------- oss-cad
# Không cần sudo. Một tarball gồm yosys, verilator, iverilog, sv2v, surelog,
# nextpnr, GTKWave... Đây là cách nhanh nhất để có yosys (apt Ubuntu thường
# quá cũ cho flow syn/ của Ibex) và là đường thay thế nếu không có sudo.
install_osscad() {
  log "OSS CAD Suite  ->  $OPT/oss-cad-suite   (~1 GB tải về)"
  mkdir -p "$OPT"
  local date_tag url tarball
  date_tag="$(curl -fsSL https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest \
              | grep -oP '"tag_name":\s*"\K[^"]+')"
  url="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${date_tag}/oss-cad-suite-linux-x64-${date_tag//-/}.tgz"
  tarball="$OPT/oss-cad-suite.tgz"
  echo "Tải: $url"
  curl -fL --progress-bar -o "$tarball" "$url"
  tar -xzf "$tarball" -C "$OPT"
  rm -f "$tarball"
  echo "Kích hoạt bằng:  source $OPT/oss-cad-suite/environment"
  echo "(script này đặt PATH; chạy trong shell riêng vì nó ghi đè PATH khá mạnh)"
}

# ------------------------------------------------------- riscv toolchain
# Cần để biên dịch phần mềm chạy trên Simple System (hello_test, CoreMark).
# Ibex 'small' là RV32IMC -> lấy bản multilib rv32.
install_toolchain() {
  log "RISC-V GCC (lowRISC prebuilt)  ->  $OPT/riscv"
  mkdir -p "$OPT/riscv"
  local url="https://github.com/lowRISC/lowrisc-toolchains/releases/download/20220210-1/lowrisc-toolchain-gcc-rv32imcb-20220210-1.tar.xz"
  echo "Tải: $url"
  curl -fL --progress-bar -o /tmp/rv32-toolchain.tar.xz "$url"
  tar -xJf /tmp/rv32-toolchain.tar.xz -C "$OPT/riscv" --strip-components=1
  rm -f /tmp/rv32-toolchain.tar.xz
  echo "Kích hoạt bằng:  export PATH=\"$OPT/riscv/bin:\$PATH\""
  "$OPT/riscv/bin/riscv32-unknown-elf-gcc" --version | head -1
}

case "$WHAT" in
  python)    install_python ;;
  apt)       install_apt ;;
  osscad)    install_osscad ;;
  toolchain) install_toolchain ;;
  all)
    install_python
    install_osscad
    install_toolchain
    log "Còn lại: chạy TAY (cần mật khẩu sudo)"
    echo "    bash $0 apt"
    ;;
  *) echo "Không rõ: $WHAT  (python|apt|osscad|toolchain|all)"; exit 1 ;;
esac

cat <<'EOF'

--------------------------------------------------------------------
Kiểm tra sau khi cài:

  source ~/.ibex-venv/bin/activate
  source ~/opt/oss-cad-suite/environment      # yosys, verilator, sv2v
  export PATH="$HOME/opt/riscv/bin:$PATH"

  cd <repo>
  make test-cfg                    # in cờ fusesoc của IBEX_CONFIG=small
  make lint-core-tracing           # lint Verilator
  make build-simple-system         # elaborate + build mô hình Verilator
  make run-simple-system           # chạy hello_test

Lấy danh sách module thật sự có trong netlist (đối chiếu phân tích tĩnh Vòng 1):

  fusesoc --cores-root=. run --target=sim --setup --build \
      lowrisc:ibex:ibex_simple_system $(./util/ibex_config.py small fusesoc_opts)
  grep -c . build/lowrisc_ibex_ibex_simple_system_0/sim-verilator/*.d
  # hoặc dựng cây phân cấp:
  verilator --lint-only -Wno-fatal --top-module ibex_top \
      -f rtl/ibex_core.f rtl/ibex_top.sv --dump-tree
--------------------------------------------------------------------
EOF
