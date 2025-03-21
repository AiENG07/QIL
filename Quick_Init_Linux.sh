#!/bin/bash

# 颜色常量定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # 颜色重置

# 系统信息检测函数
detect_os() {
  if grep -qi "ubuntu" /etc/os-release || grep -qi "debian" /etc/os-release; then
    echo "debian"
  elif grep -qi "centos" /etc/os-release; then
    echo "centos"
  else
    echo "unknown"
  fi
}

# 通用输出函数
print_color() {
  local color=$1
  shift
  echo -e "${color}$*${NC}"
}

# 带标题的头部输出
print_header() {
  clear
  show_banner
  echo -e "${GREEN}===========================================${NC}"
  echo -e "${YELLOW}              $1                ${NC}"
  echo ""
  system_info
  echo -e "${GREEN}===========================================${NC}"
}

# 包管理器封装
pkg_manager() {
  case $(detect_os) in
    debian)
      apt-get "$@" -y
      ;;
    centos)
      yum "$@" -y
      ;;
  esac
}

# 命令执行状态检查
execute_command() {
  local command="$@"
  if ! eval "$command"; then
    print_color $RED "命令执行失败: $command"
    return 1
  fi
  return 0
}

# 定义公共函数来处理操作结果
check_operation_result() {
  if [[ $? -eq 0 ]]; then
    print_color $GREEN "$1完成！"
  else
    print_color $RED "$1失败！"
  fi
}

# 系统信息显示
system_info() {
  local os_info=$(hostnamectl | grep -i "Operating System" | cut -d':' -f2-)
  local current_user=$(whoami)
  local current_time=$(date +"%Y-%m-%d %H:%M:%S")

  print_color $GREEN "操作系统: $os_info"
  print_color $GREEN "当前用户:  $current_user"
  print_color $GREEN "系统时间:  $current_time"
}

# 艺术字横幅
show_banner() {
  # clear
  local ascii_art="
┌───────────────────────────────────────────────────────┐
│                                                       │
│     ██████╗ ██╗██╗            Quick init Linux        │
│    ██╔═══██╗██║██║            版本: v0.1.0.20250321   │
│    ██║   ██║██║██║            作者: AiENG07           │
│    ██║▄▄ ██║██║██║            描述:这是一个Linux      │
│    ╚██████╔╝██║███████╗       系统快速初始化脚本      │
│      ╚══▀▀═╝ ╚═╝╚══════╝                              │
│                                                       │
└───────────────────────────────────────────────────────┘
  "
  print_color $GREEN "$ascii_art"
}

# 箭头键处理函数
handle_navigation() {
  local key=$1
  local -n ref=$2
  local max=$3
  local min=${4:-0}

  case "$key" in
    $'\e')
      read -rsn1 -t 0.1 tmp
      if [[ "$tmp" == "[" ]]; then
        read -rsn1 -t 0.1 tmp
        case "$tmp" in
          "A") # 上箭头
            ref=$(( ((ref > min)) ? ref - 1 : max ))
            ;;
          "B") # 下箭头
            ref=$(( ((ref < max)) ? ref + 1 : min ))
            ;;
        esac
      fi
      ;;
    "w")
      ref=$(( ((ref > min)) ? ref - 1 : max ))
      ;;
    "s")
      ref=$(( ((ref < max)) ? ref + 1 : min ))
      ;;
    "") return 1 ;; # 回车键
  esac
  return 0
}

# 通用菜单函数
show_menu() {
  local title="$1"
  shift
  local options=("$@")
  local selected=0

  while true; do
    print_header "$title"
    for i in "${!options[@]}"; do
      if ((i == selected)); then
        print_color $BLUE "=> ${options[i]}"
      else
        echo "   ${options[i]}"
      fi
    done

    read -rsn1 -p $'\nTips:使用方向键 Up/Down 或 WASD 控制选项，按 Enter 回车键确认选择：' key
    if ! handle_navigation "$key" selected $(( ${#options[@]} - 1 )); then
      break
    fi
  done
  return $selected
}

# 确认对话框
confirm_dialog() {
  local prompt="$1"
  local options=("确认" "取消")

  show_menu "$prompt" "${options[@]}"
  local choice=$?
  ((choice == 0)) && return 0 || return 1
}

# 更换软件源函数
change_software_source() {
  print_header "更换软件源"
  echo "正在更换软件源..."
  execute_command "bash <(curl -sSL https://linuxmirrors.cn/main.sh)"
  check_operation_result "软件源更换"
}

# 设置主机名函数
set_hostname() {
  print_header "设置主机名"
  read -p "请输入新的主机名：" new_hostname
  echo "正在设置主机名...(你的新主机名是 $new_hostname)"
  execute_command "hostnamectl set-hostname \"$new_hostname\""
  execute_command "echo \"127.0.0.1   $new_hostname\" >> /etc/hosts"
  # confirm_dialog "是否立即生效新的主机名？(将重启)" && reboot
  check_operation_result "主机名设置"
}

# 配置 PyPI 国内源函数
configure_pypi_source() {
  print_header "配置 PyPI 国内源"
  local PyPI_options=(
    "清华大学: https://pypi.tuna.tsinghua.edu.cn/simple/"
    "阿里云: http://mirrors.aliyun.com/pypi/simple/"
    "中国科技大学: https://pypi.mirrors.ustc.edu.cn/simple/"
    "豆瓣: http://pypi.douban.com/simple/"
    "Python官方: https://pypi.python.org/simple/"
    "v2ex: http://pypi.v2ex.com/simple/"
    "中国科学院: http://pypi.mirrors.opencas.cn/simple/"
    "中国科学技术大学: http://pypi.mirrors.ustc.edu.cn/simple/"
    "华为: https://mirrors.huaweicloud.com/simple/"
    "自定义PyPI 国内源"
    "返回主菜单"
  )

  show_menu "选择配置PyPI 国内源" "${PyPI_options[@]}"
  local choice=$?
  # 根据用户选择执行对应操作
  case $choice in
    0)
      echo "正在配置 清华大学 PyPI 国内源..."
      configure_pypi "https://pypi.tuna.tsinghua.edu.cn/simple/" "pypi.tuna.tsinghua.edu.cn"
      ;;
    1)
      echo "正在配置 阿里云 PyPI 国内源..."
      configure_pypi "http://mirrors.aliyun.com/pypi/simple/" "mirrors.aliyun.com"
      ;;
    2)
      echo "正在配置 中国科技大学 PyPI 国内源..."
      configure_pypi "https://pypi.mirrors.ustc.edu.cn/simple/" "pypi.mirrors.ustc.edu.cn"
      ;;
    3)
      echo "正在配置 豆瓣 PyPI 国内源..."
      configure_pypi "http://pypi.douban.com/simple/" "pypi.douban.com"
      ;;
    4)
      echo "正在配置 Python官方 PyPI 源..."
      configure_pypi "https://pypi.python.org/simple/" "pypi.python.org"
      ;;
    5)
      echo "正在配置 v2ex PyPI 国内源..."
      configure_pypi "http://pypi.v2ex.com/simple/" "pypi.v2ex.com"
      ;;
    6)
      echo "正在配置 中国科学院 PyPI 国内源..."
      configure_pypi "http://pypi.mirrors.opencas.cn/simple/" "pypi.mirrors.opencas.cn"
      ;;
    7)
      echo "正在配置 中国科学技术大学 PyPI 国内源..."
      configure_pypi "http://pypi.mirrors.ustc.edu.cn/simple/" "pypi.mirrors.ustc.edu.cn"
      ;;
    8)
      echo "正在配置 华为 PyPI 国内源..."
      configure_pypi "https://mirrors.huaweicloud.com/simple/" "mirrors.huaweicloud.com"
      ;;
    9)
      echo "正在自定义 PyPI 国内源..."
      echo "示例：https://pypi.tuna.tsinghua.edu.cn/simple/"
      read -p "请输入自定义的 PyPI 国内源地址：" custom_source
      if [[ -z "$custom_source" ]]; then
        print_color $RED "未输入有效的源地址，配置取消！"
        return
      fi
      local host=$(echo "$custom_source" | awk -F[/:] '{print $4}')
      configure_pypi "$custom_source" "$host"
      ;;
    10) main ;;
  esac
  check_operation_result PyPI 国内源配置
}

# 配置 PyPI 源的通用函数
configure_pypi() {
  local source_url=$1
  local trusted_host=$2
  execute_command "mkdir -p ~/.pip"
  execute_command "cat > ~/.pip/pip.conf <<EOF
[global]
index-url = $source_url
[install]
trusted-host = $trusted_host
EOF"

  # 检查配置文件是否创建成功
  if [[ ! -f ~/.pip/pip.conf ]]; then
    print_color $RED "配置文件创建失败！"
    return 1
  fi
}

# 安装常用工具函数
install_common_tools() {
  print_header "安装常用工具"
  echo "安装环境准备..."
  execute_command "pkg_manager update"
  execute_command "pkg_manager upgrade"
  echo "正在安装常用工具..."
  execute_command "pkg_manager install lrzsz wget vim net-tools gcc gcc-c++ curl telnet unzip git tcpdump nmap htop"
  check_operation_result 常用工具安装
}

# 配置 DNS 函数
configure_dns() {
  print_header "配置 DNS"
  local dns_options=(
    "阿里云 DNS (223.5.5.5)"
    "腾讯云 DNS (119.29.29.29)"
    "华为云 DNS (112.124.47.27)"
    "自定义 DNS"
    "返回主菜单"
  )

  show_menu "选择 DNS 服务商" "${dns_options[@]}"
  case $? in
    0) echo "nameserver 223.5.5.5" > /etc/resolv.conf ;;
    1) echo "nameserver 119.29.29.29" > /etc/resolv.conf ;;
    2) echo "nameserver 112.124.47.27" > /etc/resolv.conf ;;
    3)
      read -p "输入主 DNS 服务器: " primary
      read -p "输入备用 DNS 服务器: " secondary
      echo -e "nameserver $primary\nnameserver $secondary" > /etc/resolv.conf
      ;;
    4) main ;;
  esac
  check_operation_result DNS配置更新
}

# 安装 Docker 函数
install_docker() {
  print_header "安装 Docker"
  if [[ $(detect_os) == "debian" ]]; then
    execute_command "pkg_manager install apt-transport-https ca-certificates curl gnupg-agent software-properties-common"
    execute_command "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -"
    execute_command "add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\""
    execute_command "pkg_manager update"
    execute_command "pkg_manager install docker-ce docker-ce-cli containerd.io"
  elif [[ $(detect_os) == "centos" ]]; then
    execute_command "pkg_manager install yum-utils device-mapper-persistent-data lvm2"
    execute_command "yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
    execute_command "pkg_manager install docker-ce docker-ce-cli containerd.io"
    execute_command "systemctl start docker"
    execute_command "systemctl enable docker"
  fi
  check_operation_result Docker安装
}

# 时间同步函数
time_synchronization() {
  print_header "时间同步"
  execute_command "timedatectl set-ntp true"
  check_operation_result 时间同步
}

# 禁用 SELinux 函数
disable_selinux() {
  print_header "禁用 SELinux"
  execute_command "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"
  execute_command "setenforce 0"
  check_operation_result SELinux禁用
}

# 历史命令显示操作时间函数
enable_history_timestamp() {
  print_header "历史命令显示操作时间"
  local config_line="HISTTIMEFORMAT=\"%F %T\""
  # 检查是否已经存在相同的配置
  if grep -q "^$config_line" /etc/profile; then
    echo "配置已存在，无需更改"
  else
    # 如果不存在，则添加配置
    execute_command "cp /etc/profile /etc/profile.bak"
    execute_command "echo /etc/profile.bak 备份成功！"
    execute_command "echo '# 历史命令显示操作时间' >> /etc/profile"
    execute_command "echo '$config_line' >> /etc/profile"
    execute_command "source /etc/profile"
    check_operation_result "历史命令显示操作时间启用"
  fi
}

# 设置最大打开文件数函数
set_max_open_files() {
  print_header "设置最大打开文件数"
  execute_command "echo 'fs.file-max = 65535' >> /etc/sysctl.conf"
  execute_command "echo '* soft nofile 65535' >> /etc/security/limits.conf"
  execute_command "echo '* hard nofile 65535' >> /etc/security/limits.conf"
  execute_command "sysctl -p"
  check_operation_result 最大打开文件数设置
}

# 系统内核参数优化函数
optimize_kernel_parameters() {
  print_header "系统内核参数优化"

  local kernel_options=(
    "自动优化内核"
    "自定义优化内核"
    "返回主菜单"
  )

  # 定义内核参数优化项
  local kernel_params=(
    "net.core.somaxconn=65535"
    "net.ipv4.tcp_tw_reuse=1"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.tcp_keepalive_time=600"
    "net.ipv4.tcp_keepalive_probes=3"
    "net.ipv4.tcp_keepalive_intvl=15"
    "net.ipv4.ip_local_port_range='1024 65000'"
    "fs.file-max=2097152"
    "vm.swappiness=10"
    "vm.overcommit_memory=1"
    "vm.dirty_ratio=20"
    "vm.dirty_background_ratio=10"
    "kernel.pid_max=65536"
    "net.ipv4.tcp_max_syn_backlog=4096"
    "net.ipv4.tcp_max_tw_buckets=262144"
    "net.ipv4.route.gc_timeout=100"
    "net.ipv4.tcp_fin_timeout=30"
    "net.ipv4.tcp_slow_start_after_idle=0"
    "net.ipv4.tcp_sack=1"
    "net.ipv4.tcp_dsack=1"
    "net.ipv4.tcp_mem='16384 26777216 26777216'"
    "net.ipv4.tcp_rmem='4096 262144 262144'"
    "net.ipv4.tcp_wmem='4096 262144 262144'"
    "net.core.netdev_max_backlog=262144"
    "net.core.rmem_default=262144"
    "net.core.wmem_default=262144"
    "net.core.rmem_max=262144"
    "net.core.wmem_max=262144"
  )

  show_menu "选择内核参数优化方式" "${kernel_options[@]}"
  local choice=$?
  case $choice in
    0)
      for param in "${kernel_params[@]}"; do
        # 检查参数是否有效
        if sysctl -n "${param%%=*}" >/dev/null 2>&1; then
          if grep -q "${param}" /etc/sysctl.conf; then
            print_color $YELLOW "参数已存在，跳过写入: $param"
          else
            execute_command "echo $param >> /etc/sysctl.conf"
            execute_command "sysctl -w $param"
          fi
        else
          print_color $YELLOW "跳过不支持的参数: $param"
        fi
      done
      ;;
    1)
      read -p "请输入自定义的内核参数（每行一个）：" custom_params
      while IFS= read -r line; do
        if [[ "$line" =~ ^[^=]+=[^=]+ ]]; then
          echo "$line" >> /etc/sysctl.conf
        else
          print_color $RED "无效的参数格式: $line"
        fi
      done <<< "$custom_params"
      ;;
    2) main ;;
  esac
  # 应用新的内核参数
  if execute_command "sysctl -p"; then
    print_color $GREEN 内核参数优化
  else
    print_color $RED "内核参数优化失败，请检查配置文件 /etc/sysctl.conf"
  fi
}


# 配置静态 IP 函数
configure_static_ip() {
  print_header "配置静态 IP"

  read -p "请输入网络接口名称（如 eth0）：" interface
  read -p "请输入 IP 地址（如 192.168.1.100）：" ip
  read -p "请输入子网掩码（如 255.255.255.0）：" netmask
  read -p "请输入网关（如 192.168.1.1）：" gateway

  if [[ $(detect_os) == "debian" ]]; then
    execute_command "echo 'auto $interface' >> /etc/netplan/01-netcfg.yaml"
    execute_command "echo '  dhcp4: no' >> /etc/netplan/01-netcfg.yaml"
    execute_command "echo '  addresses: [$ip/$netmask]' >> /etc/netplan/01-netcfg.yaml"
    execute_command "echo '  gateway4: $gateway' >> /etc/netplan/01-netcfg.yaml"
    execute_command "netplan apply"
  elif [[ $(detect_os) == "centos" ]]; then
    execute_command "echo 'BOOTPROTO=static' > /etc/sysconfig/network-scripts/ifcfg-\$interface"
    execute_command "echo 'IPADDR=$ip' >> /etc/sysconfig/network-scripts/ifcfg-\$interface"
    execute_command "echo 'NETMASK=$netmask' >> /etc/sysconfig/network-scripts/ifcfg-\$interface"
    execute_command "echo 'GATEWAY=$gateway' >> /etc/sysconfig/network-scripts/ifcfg-\$interface"
    execute_command "echo 'ONBOOT=yes' >> /etc/sysconfig/network-scripts/ifcfg-\$interface"
    execute_command "systemctl restart network"
  fi
  check_operation_result 静态 IP 配置
}

set_firewalld(){
  print_header "配置 防火墙"
  # 关闭防火墙
  systemctl stop firewalld
  check_operation_result 关闭防火墙配置
  # 关闭开机自启动
  systemctl disable firewalld
  check_operation_result 关闭防火墙开机自启动配置
}

set_networkManager(){
  print_header "配置 NetworkManager"
  # 关闭 NetworkManager
  systemctl stop NetworkManager
  check_operation_result 关闭 NetworkManager 配置
  # 关闭开机自启动
  systemctl disable NetworkManager
  check_operation_result 关闭 NetworkManager 开机自启动配置
}

# 主菜单处理
main() {
  while true; do
    local main_options=(
      "更换软件源"
      "设置主机名"
      "配置静态 IP"
      "配置 PyPI 国内源"
      "配置 DNS"
      "时间同步"
      "安装常用工具"
      "安装 Docker"
      "禁用 SELinux"
      "历史命令显示操作时间"
      "设置最大打开文件数"
      "系统内核参数优化"
      "防火墙设置"
      "NetworkManager设置"
      "退出"
    )

    show_menu "主菜单" "${main_options[@]}"
    local choice=$?
    case $choice in
      0) confirm_dialog "是否更换软件源?" && change_software_source ;;
      1) confirm_dialog "是否设置主机名?" && set_hostname ;;
      2) confirm_dialog "是否配置静态 IP?" && configure_static_ip ;;
      3) confirm_dialog "是否配置 PyPI 国内源?" && configure_pypi_source ;;
      4) confirm_dialog "是否配置 DNS?" && configure_dns ;;
      5) confirm_dialog "是否进行时间同步?" && time_synchronization ;;
      6) confirm_dialog "是否安装常用工具?" && install_common_tools ;;
      7) confirm_dialog "是否安装 Docker?" && install_docker ;;
      8) confirm_dialog "是否禁用 SELinux?" && disable_selinux ;;
      9) confirm_dialog "是否启用历史命令显示操作时间?" && enable_history_timestamp ;;
      10) confirm_dialog "是否设置最大打开文件数?" && set_max_open_files ;;
      11) confirm_dialog "是否进行系统内核参数优化?" && optimize_kernel_parameters ;;
      12) confirm_dialog "是否进行防火墙设置?" && set_firewalld ;;
      13) confirm_dialog "是否进行NetworkManager设置?" && set_networkManager ;;
      14) exit 0 ;;
    esac
    read -p "按 Enter 键返回主菜单..."
  done
}

# 权限检查
if (( EUID != 0 )); then
  print_color $RED "请使用 root 用户运行此脚本"
  exit 1
fi

# 程序入口
main