FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    DISPLAY=:1 \
    VNC_PORT=5901 \
    NOVNC_PORT=6080 \
    VNC_GEOMETRY=1920x1080 \
    VNC_DEPTH=24 \
    USERNAME=desktop \
    HOME=/home/desktop

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xfce4 \
        xfce4-goodies \
        xubuntu-icon-theme \
        xfce4-terminal \
        tigervnc-standalone-server \
        tigervnc-tools \
        novnc \
        websockify \
        dbus-x11 \
        x11-utils \
        x11-xserver-utils \
        x11-apps \
        xterm \
        sudo \
        vim \
        nano \
        curl \
        wget \
        git \
        net-tools \
        iproute2 \
        procps \
        ca-certificates \
        tzdata \
        openssl \
        firefox \
    && rm -rf /var/lib/apt/lists/*

RUN useradd \
        --create-home \
        --shell /bin/bash \
        --uid 1000 \
        ${USERNAME} \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" \
        > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

RUN mkdir -p /home/${USERNAME}/.vnc \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} \
    && chmod 700 /home/${USERNAME}/.vnc

RUN cat > /home/${USERNAME}/.vnc/xstartup <<'EOF'
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce

xrdb "$HOME/.Xresources" 2>/dev/null || true

exec dbus-launch --exit-with-session startxfce4
EOF

RUN chmod +x /home/${USERNAME}/.vnc/xstartup \
    && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.vnc/xstartup

RUN ln -sf /usr/share/novnc/vnc.html \
    /usr/share/novnc/index.html

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 6080

VOLUME ["/home/desktop"]

WORKDIR /home/desktop

ENTRYPOINT ["/entrypoint.sh"]
