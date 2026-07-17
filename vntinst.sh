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
    cd ~ && rm -rf ~/tmp_vnt

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

check_vnt_menu() {
    echo "--- 查看 VNT ---"
    echo "1. 查看服务状态"
    echo "2. 查看当前状态"
    echo "3. 查看设备列表"
    read -p "请选择 (1-3): " sub_choice
    case $sub_choice in
        1) sudo systemctl status vnt ;;
        2) $VNT_PATH --info ;;
        3) $VNT_PATH --all ;;
        *) echo "无效选择" ;;
    esac
}

uninstall_vnt() {
    echo "--- 正在彻底卸载 VNT ---"
    
    # 停止并删除系统服务
    sudo systemctl stop vnt 2>/dev/null
    sudo systemctl disable vnt 2>/dev/null
    if [ -f "$SERVICE_PATH" ]; then
        sudo rm -f "$SERVICE_PATH"
        sudo systemctl daemon-reload
    fi

    # 删除 VNT 客户端文件及残留进程
    if [ -f "$VNT_PATH" ]; then
        sudo rm -f "$VNT_PATH"
    fi
    sudo pkill vnt-cli 2>/dev/null

    echo "--- 核心程序已卸载 ---"
    
    # 删除管理脚本本身
    echo "--- 即将删除管理脚本并退出 ---"
    sudo rm -f /usr/local/bin/vnt
    
    echo "--- 卸载完成 ---"
    exit 0
}

# 主菜单
echo "VNT 管理脚本"
echo "1. 安装 VNT"
echo "2. 查看 VNT"
echo "3. 卸载 VNT"
read -p "请选择 (1-3): " choice

case $choice in
    1) install_vnt ;;
    2) check_vnt_menu ;;
    3) uninstall_vnt ;;
    *) echo "无效选择" ;;
esac
