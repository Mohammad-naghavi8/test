#!/bin/bash

set -e

USERNAME="${USERNAME:-desktop}"
DISPLAY="${DISPLAY:-:1}"

VNC_PORT="${VNC_PORT:-5901}"

# Railway automatically provides PORT
NOVNC_PORT="${PORT:-8080}"

VNC_GEOMETRY="${VNC_GEOMETRY:-1920x1080}"
VNC_DEPTH="${VNC_DEPTH:-24}"

HOME_DIR="/home/${USERNAME}"
VNC_DIR="${HOME_DIR}/.vnc"

echo "======================================"
echo " Ubuntu XFCE Railway Desktop"
echo "======================================"
echo "User       : ${USERNAME}"
echo "Display    : ${DISPLAY}"
echo "Resolution : ${VNC_GEOMETRY}"
echo "VNC Port   : ${VNC_PORT}"
echo "Web Port   : ${NOVNC_PORT}"
echo "======================================"

mkdir -p "${VNC_DIR}"

chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}"

# ------------------------------------------------------------
# VNC password
# ------------------------------------------------------------

if [ -z "${VNC_PASSWORD:-}" ]; then
    echo "ERROR: VNC_PASSWORD is not set."
    exit 1
fi

echo "Creating VNC password..."

su - "${USERNAME}" -c \
    "printf '%s\n' '${VNC_PASSWORD}' | vncpasswd -f > '${VNC_DIR}/passwd'"

chmod 600 "${VNC_DIR}/passwd"

# ------------------------------------------------------------
# Remove old VNC session
# ------------------------------------------------------------

su - "${USERNAME}" -c \
    "vncserver -kill ${DISPLAY}" >/dev/null 2>&1 || true

rm -f \
    "/tmp/.X${DISPLAY#:}-lock" \
    "/tmp/.X11-unix/X${DISPLAY#:}"

# ------------------------------------------------------------
# Start VNC
# ------------------------------------------------------------

echo "Starting TigerVNC..."

su - "${USERNAME}" -c "
    vncserver ${DISPLAY} \
        -geometry ${VNC_GEOMETRY} \
        -depth ${VNC_DEPTH} \
        -rfbport ${VNC_PORT} \
        -localhost no \
        -SecurityTypes VncAuth
"

# ------------------------------------------------------------
# Start noVNC
# ------------------------------------------------------------

echo "Starting noVNC on port ${NOVNC_PORT}..."

exec websockify \
    --web=/usr/share/novnc \
    "0.0.0.0:${NOVNC_PORT}" \
    "localhost:${VNC_PORT}"
