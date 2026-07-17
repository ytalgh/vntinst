#!/bin/bash

# 配置项
SERVER_ADDR="vnt.wherewego.top:29872"
VNT_CLI="/usr/local/bin/vnt-cli"
SERVICE_FILE="/etc/systemd/system/vnt.service"
REPO_DIR="/opt/vnt-script-repo"
SCRIPT_PATH="$REPO_DIR/vntinst.sh"

# 1. 环境自检与自动部署
setup_environment() {
    if [[ "$PWD" != "$REPO_DIR" ]]; then
        if [ ! -d "$REPO_DIR" ]; then
            sudo mkdir -p "$REPO_DIR"
        fi
        sudo cp "$0" "$SCRIPT_PATH"
        sudo chmod -R 755 "$REPO_DIR"
        sudo ln -sf "$SCRIPT_PATH" /usr/local/bin/vnt
        echo "环境配置已完成，现在可以直接在终端输入 'vnt' 使用。"
    fi
}

# 2. 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
       echo "正在通过 sudo 提升权限..."
       exec sudo "$0" "$@"
    fi
}

# 3. 安装服务
install_vnt() {
    echo "--- 开始安装 VNT ---"
    read -p "请输入 -k Token (默认: ytalgh): " input_k
    K_VAL=${input_k:-ytalgh}
    read -p "请输入 -w 密码: " W_VAL
    read -p "请输入 -n 设备名: " N_VAL

    echo "正在查询 GitHub 最新版本..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/vnt-dev/vnt/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$LATEST_VERSION" ]; then
        echo "无法获取最新版本，请检查网络连接。"
        return
    fi
    echo "检测到最新版本: $LATEST_VERSION"

    echo "正在下载..."
    mkdir -p /tmp/vnt_tmp && cd /tmp/vnt_tmp
    DOWNLOAD_URL="https://github.com/vnt-dev/vnt/releases/download/${LATEST_VERSION}/vnt-x86_64-unknown-linux-musl-${LATEST_VERSION}.tar.gz"
    
    wget -q "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo "下载失败，请重试。"
        return
    fi
    
    tar -zxvf "vnt-x86_64-unknown-linux-musl-${LATEST_VERSION}.tar.gz" > /dev/null
    mv vnt-cli "$VNT_CLI"
    chmod +x "$VNT_CLI"
    cd ~ && rm -rf /tmp/vnt_tmp

    echo "[Unit]
Description=VNT Client Service
After=network.target

[Service]
Type=simple
ExecStart=$VNT_CLI -k \"$K_VAL\" -s \"$SERVER_ADDR\" -w \"$W_VAL\" -n \"$N_VAL\"
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target" | tee "$SERVICE_FILE" > /dev/null

    systemctl daemon-reload
    systemctl enable vnt --now
    echo "--- 安装完成，版本 $LATEST_VERSION 已设为开机自启 ---"
}

# 4. 更新 VNT 版本
update_vnt() {
    echo "--- 开始检查 VNT 更新 ---"
    
    # 1. 获取 GitHub 最新版本
    LATEST_VERSION=$(curl -s https://api.github.com/repos/vnt-dev/vnt/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$LATEST_VERSION" ]; then
        echo "无法连接 GitHub，检查更新失败。"
        return
    fi

    # 2. 获取本地版本
    if [ -f "$VNT_CLI" ]; then
        LOCAL_VERSION=$($VNT_CLI --version 2>&1 | awk '{print $2}')
    else
        LOCAL_VERSION="none"
    fi

    echo "本地版本: $LOCAL_VERSION"
    echo "最新版本: $LATEST_VERSION"

    # 3. 对比版本
    if [ "$LOCAL_VERSION" == "$LATEST_VERSION" ]; then
        echo "当前已是最新版本，无需更新。"
        return
    fi

    # 4. 执行更新
    echo "检测到新版本，正在更新..."
    mkdir -p /tmp/vnt_tmp && cd /tmp/vnt_tmp
    DOWNLOAD_URL="https://github.com/vnt-dev/vnt/releases/download/${LATEST_VERSION}/vnt-x86_64-unknown-linux-musl-${LATEST_VERSION}.tar.gz"
    
    wget -q "$DOWNLOAD_URL"
    if [ $? -eq 0 ]; then
        systemctl stop vnt
        tar -zxvf "vnt-x86_64-unknown-linux-musl-${LATEST_VERSION}.tar.gz" > /dev/null
        mv vnt-cli "$VNT_CLI"
        chmod +x "$VNT_CLI"
        systemctl start vnt
        echo "--- 更新完成，已更新至 $LATEST_VERSION 并重启服务 ---"
    else
        echo "下载更新包失败。"
    fi
    cd ~ && rm -rf /tmp/vnt_tmp
}

# 5. 查看状态菜单
check_vnt_menu() {
    while true; do
        echo -e "\n--- 查看 VNT 状态 ---"
        echo "1. 查看服务运行状态"
        echo "2. 查看当前网络信息"
        echo "3. 查看设备连接列表"
        echo "4. 返回主菜单"
        read -p "请选择 (1-4): " sub_choice
        case $sub_choice in
            1) systemctl status vnt --no-pager | head -n 20 ;;
            2) $VNT_CLI --info ;;
            3) $VNT_CLI --all ;;
            4) break ;;
            *) echo "无效选择" ;;
        esac
    done
}

# 6. 卸载服务
uninstall_vnt() {
    echo "--- 正在彻底卸载 VNT ---"
    systemctl stop vnt 2>/dev/null
    systemctl disable vnt 2>/dev/null
    rm -f "$SERVICE_FILE"
    rm -f "$VNT_CLI"
    systemctl daemon-reload
    echo "--- 卸载完成 ---"
    exit 0
}

# 初始化执行
setup_environment
check_root

# 主循环
while true; do
    echo -e "\n=== VNT 全局管理工具 ==="
    echo "1. 安装 VNT 服务"
    echo "2. 查看 VNT 状态"
    echo "3. 卸载 VNT 服务"
    echo "4. 更新 VNT 版本"
    echo "5. 退出"
    read -p "请选择 (1-5): " choice
    case $choice in
        1) install_vnt ;;
        2) check_vnt_menu ;;
        3) uninstall_vnt ;;
        4) update_vnt ;;
        5) echo "退出"; exit 0 ;;
        *) echo "无效选择" ;;
    esac
done
