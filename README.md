# Linux 系统快速初始化脚本（QIL）

## 简介

这是一个用于快速初始化 Linux 系统的脚本，旨在简化系统配置过程，提高工作效率。脚本提供了多种实用功能，包括更换软件源、设置主机名、配置静态 IP、安装常用工具等，支持 CentOS 和 Debian 系列系统。

## 功能清单

- 更换软件源（支持国内镜像源）
- 设置主机名
- 配置静态 IP 地址
- 配置 PyPI 国内源（可选国内源，如清华）
- 配置 DNS 服务器（可选阿里、腾讯、华为DNS也可自定义DNS）
- 时间同步
- 安装常用工具（lrzsz wget vim net-tools gcc gcc-c++ curl telnet unzip git tcpdump nmap htop）
- 安装 Docker
- 禁用 SELinux
- 启用历史命令显示操作时间
- 设置最大打开文件数
- 优化系统内核参数
- 防火墙设置
- NetworkManager 设置

## 使用方法
1. 克隆或下载脚本 `git clone https://github.com/AiENG07/QIL.git`
2. 进入脚本文件夹 `cd QIL`
3. 给脚本执行权限：`chmod +x Quick_Init_Linux.sh`
4. 以 root 用户运行脚本：`sudo ./Quick_Init_Linux.sh`
5. 在菜单中选择需要的操作，按照提示进行配置

### 交互式菜单操作

脚本运行后会显示主菜单，通过方向键或 WASD 键导航，按 Enter 确认选择：

```
===========================================
              主菜单
操作系统: CentOS Linux 8 (Core)
当前用户:  root
系统时间:  2025-3-20 10:00:00
===========================================
=>  更换软件源
    设置主机名
    配置静态 IP
    配置 PyPI 国内源
    配置 DNS
    时间同步
    安装常用工具
    安装 Docker
    禁用 SELinux
    历史命令显示操作时间
    设置最大打开文件数
    系统内核参数优化
    防火墙设置
    NetworkManager设置
    退出

使用方向键 Up/Down 或 WASD 控制选项，按 Enter 回车键确认选择:
```

## 注意事项

- 支持的 Linux 发行版：Debian、Ubuntu、CentOS
- 需要 root 权限运行脚本
- 请确保在使用脚本前备份重要数据
- 脚本会根据系统类型自动适配包管理器
- 部分功能（如更换软件源）需要网络连接
- 配置静态 IP 前请确保输入的网络信息正确
- 禁用 SELinux 可能会影响系统安全性，请根据实际需求操作


## 贡献
- 作者: AiENG07
- 版本: v0.1.0.20250321

欢迎通过 GitHub 提交问题或拉取请求来贡献改进意见。

## 许可

本脚本采用 MIT 许可证，可在 LICENSE 文件中查看详细信息。






