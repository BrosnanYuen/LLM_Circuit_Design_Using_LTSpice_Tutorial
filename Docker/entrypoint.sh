#!/usr/bin/env bash
set -euo pipefail

export MCP_HOME="${MCP_HOME:-/opt/mcp}"
export SYMBOLIC_MATH_MCP_DIR="${SYMBOLIC_MATH_MCP_DIR:-$MCP_HOME/symbolic_math_mcp}"
export BLTSPICE_MCP_DIR="${BLTSPICE_MCP_DIR:-$MCP_HOME/bltspice_mcp}"
export SYMBOLIC_MATH_MCP_PORT="${SYMBOLIC_MATH_MCP_PORT:-8753}"
export BLTSPICE_MCP_PORT="${BLTSPICE_MCP_PORT:-7543}"
export MCP_BIND_HOST="${MCP_BIND_HOST:-0.0.0.0}"
export WINEPREFIX="${WINEPREFIX:-/opt/wineprefix}"
export WINEDEBUG="${WINEDEBUG:--all}"
export KICAD_SHARE="${KICAD_SHARE:-/usr/share/kicad/}"
export LTSPICE_EXE="${LTSPICE_EXE:-$WINEPREFIX/drive_c/ADI/LTspice/LTspice.exe}"
export LTSPICEFOLDER="${LTSPICEFOLDER:-$WINEPREFIX/drive_c/ADI/LTspice}"
export LTSPICEEXECUTABLE="${LTSPICEEXECUTABLE:-LTspice.exe}"
export WINEFOLDER="${WINEFOLDER:-$WINEPREFIX}"
export WINEEXECUTABLE="${WINEEXECUTABLE:-wine}"

render_configs() {
  python3 - <<'PY'
import json
import os
import sys
from pathlib import Path

home = Path(os.environ["MCP_HOME"])
symbolic_dir = Path(os.environ["SYMBOLIC_MATH_MCP_DIR"])
bltspice_dir = Path(os.environ["BLTSPICE_MCP_DIR"])
symbolic_port = int(os.environ["SYMBOLIC_MATH_MCP_PORT"])
bltspice_port = int(os.environ["BLTSPICE_MCP_PORT"])
bind_host = os.environ["MCP_BIND_HOST"]
ltspice_exe = os.environ["LTSPICE_EXE"]
kicad_share = os.environ["KICAD_SHARE"]

symbolic_common = {
    "mcp_server_name": os.environ.get("SYMBOLIC_MATH_MCP_NAME", "Symbolic Math MCP Server"),
    "yaml_must_have": ["axioms:", "calculations:"],
    "max_requests": int(os.environ.get("SYMBOLIC_MATH_MCP_MAX_REQUESTS", "24")),
    "total_timeout": float(os.environ.get("SYMBOLIC_MATH_MCP_TOTAL_TIMEOUT", "6000")),
}

ltspice_wine_dir = str(Path(os.environ["WINEPREFIX"]) / "drive_c/users/root/AppData/Local/LTspice/")
ltspice_windows_dir = "C:\\users\\root\\AppData\\Local\\LTspice\\"

bltspice_common = {
    "mcp_server_name": os.environ.get("BLTSPICE_MCP_NAME", "BLTSpice MCP Server"),
    "wine_path": os.environ.get("WINE_PATH", "/usr/bin/wine"),
    "ltspice_path": ltspice_exe,
    "enable_extra_tools": True,
    "timeout": int(os.environ.get("BLTSPICE_TIMEOUT", "600")),
    "convert_settings": {
        "ltspice_windows_path": ltspice_windows_dir,
        "ltspice_wine_path": ltspice_wine_dir,
        "custom_search_paths": [str(bltspice_dir / "testfiles")],
        "minimum_dist": 32,
        "wire_pin_out_dist": 16,
        "grid_size": 16,
        "autoplace_iter": 12,
        "ltspice_version": 4.1,
        "voltage_must_have_dc": True,
        "kicad_path": kicad_share,
    },
}

def write(path, payload):
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

write(
    symbolic_dir / "config.http.json",
    {**symbolic_common, "mcp_server_url": f"http://{bind_host}:{symbolic_port}"},
)
write(
    symbolic_dir / "config.stdio.json",
    {**symbolic_common, "mcp_server_url": "stdio://"},
)
write(
    bltspice_dir / "config.http.json",
    {**bltspice_common, "mcp_server_url": f"http://{bind_host}:{bltspice_port}"},
)
write(
    bltspice_dir / "config.stdio.json",
    {**bltspice_common, "mcp_server_url": "stdio://"},
)
print(f"rendered MCP configs under {home}", file=sys.stderr)
PY
}

check_port() {
  python3 - "$1" <<'PY'
import socket
import sys

port = int(sys.argv[1])
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    sock.bind(("0.0.0.0", port))
except OSError as exc:
    raise SystemExit(f"error: port {port} is already in use: {exc}")
finally:
    sock.close()
PY
}

start_xvfb() {
  if [ -z "${DISPLAY:-}" ] && command -v Xvfb >/dev/null 2>&1; then
    Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp >/tmp/xvfb.log 2>&1 &
    export DISPLAY=:99
    sleep 1
  fi
}

serve() {
  render_configs
  check_port "$SYMBOLIC_MATH_MCP_PORT"
  check_port "$BLTSPICE_MCP_PORT"
  start_xvfb

  local symbolic_pid bltspice_pid status=0
  "$SYMBOLIC_MATH_MCP_DIR/.venv/bin/python" "$SYMBOLIC_MATH_MCP_DIR/run_server.py" \
    --config "$SYMBOLIC_MATH_MCP_DIR/config.http.json" &
  symbolic_pid=$!

  (cd "$BLTSPICE_MCP_DIR" && exec "$BLTSPICE_MCP_DIR/.venv/bin/python" -m bltspice_mcp \
    --config "$BLTSPICE_MCP_DIR/config.http.json") &
  bltspice_pid=$!

  trap 'kill -TERM "$symbolic_pid" "$bltspice_pid" 2>/dev/null || true' INT TERM

  set +e
  wait -n "$symbolic_pid" "$bltspice_pid"
  status=$?
  set -e

  kill -TERM "$symbolic_pid" "$bltspice_pid" 2>/dev/null || true
  wait "$symbolic_pid" "$bltspice_pid" 2>/dev/null || true
  return "$status"
}

symbolic_stdio() {
  render_configs
  start_xvfb
  exec "$SYMBOLIC_MATH_MCP_DIR/.venv/bin/python" "$SYMBOLIC_MATH_MCP_DIR/run_server.py" \
    --config "$SYMBOLIC_MATH_MCP_DIR/config.stdio.json"
}

bltspice_stdio() {
  render_configs
  start_xvfb
  cd "$BLTSPICE_MCP_DIR"
  exec "$BLTSPICE_MCP_DIR/.venv/bin/python" -m bltspice_mcp \
    --config "$BLTSPICE_MCP_DIR/config.stdio.json"
}

case "${1:-serve}" in
  serve)
    shift || true
    serve "$@"
    ;;
  symbolic-math-mcp | symbolic-math-mcp-stdio)
    shift || true
    symbolic_stdio "$@"
    ;;
  bltspice-mcp | bltspice-mcp-stdio)
    shift || true
    bltspice_stdio "$@"
    ;;
  shell | bash)
    shift || true
    exec bash "$@"
    ;;
  *)
    exec "$@"
    ;;
esac
