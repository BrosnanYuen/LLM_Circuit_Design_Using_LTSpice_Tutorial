#!/bin/sh
set -e

LTSPICE_URL="${1:?usage: install-ltspice.sh <msi-url>}"
LTSPICE_DIR="$WINEPREFIX/drive_c/ADI/LTspice"

curl -fsSL -o /tmp/LTspice64.msi "$LTSPICE_URL"
xvfb-run -a wineboot --init
xvfb-run -a wine msiexec /i /tmp/LTspice64.msi /qn 'APPDIR=C:\ADI\LTspice'
test -f "$LTSPICE_DIR/LTspice.exe"

mkdir -p /tmp/ltspice-probe
cat > /tmp/ltspice-probe/probe.net <<'EOF'
* ltspice probe
V1 in 0 1
R1 in 0 1k
.op
.end
EOF

cd /tmp/ltspice-probe
xvfb-run -a wine "$LTSPICE_DIR/LTspice.exe" -Run -b probe.net
test -f /tmp/ltspice-probe/probe.log
test -f "$WINEPREFIX/drive_c/users/root/AppData/Local/LTspice/lib/cmp/standard.bjt"

rm -rf /tmp/ltspice-probe /tmp/LTspice64.msi
