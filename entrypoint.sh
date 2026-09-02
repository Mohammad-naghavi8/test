#!/bin/bash

set -e

USERNAME="${USERNAME:-desktop}"
DISPLAY="${DISPLAY:-:1}"
VNC_PORT="${VNC_PORT:-5901}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
VNC_GEOMETRY="${VNC_GEOMETRY:-1920x1080}"
VNC_DEPTH="${VNC_DEPTH:-24}"

HOME_DIR="/home/${USERNAME}"
VNC_DIR="${HOME_DIR}/.vnc"

echo "======================================"
echo " Ubuntu XFCE Docker Desktop"
echo "======================================"
echo "User       : ${USERNAME}"
echo "Display    : ${DISPLAY}"
echo "Resolution : ${VNC_GEOMETRY}"
echo "VNC Port   : ${VNC_PORT}"
echo "noVNC Port : ${NOVNC_PORT}"
echo "======================================"

mkdir -p "${VNC_DIR}"

chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}"

# ------------------------------------------------------------
# VNC password
# ------------------------------------------------------------

if [ -n "${VNC_PASSWORD:-}" ]; then

    echo "Setting VNC password..."

    su - "${USERNAME}" -c \
        "printf '%s\n' '${VNC_PASSWORD}' | vncpasswd -f > '${VNC_DIR}/passwd'"

    chmod 600 "${VNC_DIR}/passwd"

    VNC_SECURITY="-SecurityTypes VncAuth"

else

    echo "WARNING: VNC_PASSWORD is not set."
    echo "VNC authentication will be disabled."

    VNC_SECURITY="-SecurityTypes None"
fi

# ------------------------------------------------------------
# Remove old session
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
        ${VNC_SECURITY}
"

# ------------------------------------------------------------
# HTTPS certificate
# ------------------------------------------------------------

mkdir -p /tmp/novnc

if [ ! -f /tmp/novnc/self.pem ]; then

    echo "Generating HTTPS certificate..."

    openssl req \
        -new \
        -x509 \
        -nodes \
        -days 365 \
        -subj "/CN=localhost" \
        -out /tmp/novnc/self.pem \
        -keyout /tmp/novnc/self.pem
fi

# ------------------------------------------------------------
# Start noVNC
# ------------------------------------------------------------

echo "Starting noVNC..."

exec websockify \
    --web=/usr/share/novnc \
    --cert=/tmp/novnc/self.pem \
    "${NOVNC_PORT}" \
    "localhost:${VNC_PORT}"
