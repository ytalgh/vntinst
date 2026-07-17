#!/bin/bash

# 配置项
SERVER_ADDR="vnt.wherewego.top:29872"
VNT_PATH="/usr/local/bin/vnt-cli"
SERVICE_PATH="/etc/systemd/system/vnt.service"

install_vnt() {
    echo "--- 开始安装 VNT ---"
    read -p "请输入 -k Token (默认: ytalgh): " input_k
    K_VAL=${input_k:-ytalgh}
    read -p "请输入 -w 密码: " W_VAL
    read -p "请输入 -n 设备名: " N_VAL

    # 下载与移动
    mkdir -p ~/tmp_vnt && cd ~/tmp_vnt
    wget https://github.com/vnt-dev/vnt/releases/download/v1.2.16/vnt-x86_64-unknown-linux-musl-v1.2.16.tar.gz
    tar -zxvf vnt-x86_64-unknown-linux-musl-v1.2.16.tar.gz
    sudo mv vnt-cli "$VNT_PATH"
    sudo chmod +x "$VNT_PATH"
    rm -rf ~/tmp_vnt

    # 创建服务
    echo "[Unit]
Description=VNT Client Service
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$VNT_PATH -k \"$K_VAL\" -s \"$SERVER_ADDR\" -w \"$W_VAL\" -n \"$N_VAL\"
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target" | sudo tee "$SERVICE_PATH" > /dev/null

    sudo systemctl daemon-reload
    sudo systemctl enable vnt --now
    echo "--- 安装完成，服务已启动 ---"
}

status_vnt() {
    sudo systemctl status vnt
}

uninstall_vnt() {
    echo "--- 正在卸载 VNT ---"
    sudo systemctl stop vnt
    sudo systemctl disable vnt
    sudo rm "$VNT_PATH"
    sudo rm "$SERVICE_PATH"
    sudo systemctl daemon-reload
    echo "--- 卸载完成 ---"
}

# 主菜单
echo "VNT 管理脚本"
echo "1. 安装 VNT"
echo "2. 查看 VNT 服务状态"
echo "3. 卸载 VNT"
read -p "请选择 (1-3): " choice

case $choice in
    1) install_vnt ;;
    2) status_vnt ;;
    3) uninstall_vnt ;;
    *) echo "无效选择" ;;
esac
