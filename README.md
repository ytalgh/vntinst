# VNT 一键安装与管理工具

本脚本支持自动下载最新版 VNT、全局环境部署及系统服务管理。

### 快速部署

在任何 Linux 机器上，只需执行以下命令即可一键完成部署：

```bash
# 1. 下载脚本
wget https://raw.githubusercontent.com/ytalgh/vntinst/main/vntinst.sh

# 2. 赋予执行权限并直接运行
chmod +x vntinst.sh && sudo ./vntinst.sh
```
### 使用说明  

**全局调用**：脚本首次运行时会自动将自身安装到 /opt/vnt-script-repo/ 并创建全局链接。

**随时管理**：部署完成后，无论何时，只需在终端输入 vnt 即可唤出管理菜单。

**自动更新**：脚本在安装 VNT 时会自动获取 GitHub 上的最新发布版本。
