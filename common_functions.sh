#!/bin/bash

# Ubuntu 命令大全脚本 - 通用函数库
# 所有脚本共享的变量和函数

# 严格模式 - 提高脚本安全性
set -euo pipefail

# 颜色定义 - 统一管理
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # 无颜色

# 全局配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$HOME/.ub_command_menu"
readonly LOG_FILE="$CONFIG_DIR/debug.log"

# 确保配置目录存在
mkdir -p "$CONFIG_DIR"

# 日志函数
log() {
    local level="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*" >> "$LOG_FILE"
}

# 错误处理函数
error_exit() {
    local msg="$1"
    echo -e "${RED}错误: $msg${NC}" >&2
    log "ERROR" "$msg"
    exit 1
}

# 警告函数
warn() {
    local msg="$1"
    echo -e "${YELLOW}警告: $msg${NC}" >&2
    log "WARN" "$msg"
}

# 信息函数
info() {
    local msg="$1"
    echo -e "${GREEN}$msg${NC}"
    log "INFO" "$msg"
}

# 输入验证函数
validate_input() {
    local input="$1"
    local pattern="$2"
    local error_msg="$3"
    
    if [[ ! "$input" =~ $pattern ]]; then
        error_exit "$error_msg"
    fi
}

# 检查命令是否存在
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        error_exit "命令 '$cmd' 未找到，请先安装相关软件包"
    fi
}

# 检查文件是否存在且可读
check_file_readable() {
    local file="$1"
    if [[ ! -f "$file" ]] || [[ ! -r "$file" ]]; then
        error_exit "文件 '$file' 不存在或不可读"
    fi
}

# 清屏函数 - 优化版本，减少不必要的清屏
clear_screen() {
    # 只有在终端支持的情况下才清屏
    if [[ -t 1 ]]; then
        clear
    fi
}

# 显示标题 - 优化版本
show_header() {
    local title="${1:-Ubuntu 命令大全}"
    local version="${2:-v2.0}"
    
    echo -e "${BLUE}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                                               │${NC}"
    echo -e "${BLUE}│${YELLOW}           $title        ${BLUE}│${NC}"
    echo -e "${BLUE}│${GREEN}                   $version                      ${BLUE}│${NC}"
    echo -e "${BLUE}│                                               │${NC}"
    echo -e "${BLUE}└───────────────────────────────────────────────┘${NC}"
    echo ""
}

# 等待用户输入 - 统一函数
wait_for_input() {
    local prompt="${1:-按任意键继续...}"
    echo -e "\n${CYAN}$prompt${NC}"
    read -n 1 -s
}

# 获取用户确认
get_confirmation() {
    local prompt="$1"
    local response
    
    while true; do
        echo -e "${YELLOW}$prompt [y/N]:${NC} "
        read -r response
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]|"") return 1 ;;
            *) echo -e "${RED}请输入 y 或 n${NC}" ;;
        esac
    done
}

# 安全的命令执行函数
execute_command() {
    local cmd="$1"
    local show_output="${2:-true}"
    
    log "INFO" "执行命令: $cmd"
    
    if [[ "$show_output" == "true" ]]; then
        echo -e "\n${CYAN}执行命令: ${YELLOW}$cmd${NC}\n"
    fi
    
    if get_confirmation "确定要执行此命令吗？"; then
        if eval "$cmd"; then
            info "命令执行成功"
            log "INFO" "命令执行成功: $cmd"
        else
            local exit_code=$?
            error_exit "命令执行失败 (退出码: $exit_code): $cmd"
        fi
    else
        warn "用户取消了命令执行"
    fi
    
    wait_for_input
}

# 无效选项处理
invalid_option() {
    warn "无效的选项，请重新选择"
    wait_for_input
}

# 创建目录（如果不存在）
ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || error_exit "无法创建目录: $dir"
        log "INFO" "创建目录: $dir"
    fi
}

# 备份文件
backup_file() {
    local file="$1"
    local backup_dir="$CONFIG_DIR/backups"
    
    ensure_directory "$backup_dir"
    
    if [[ -f "$file" ]]; then
        local backup_name="$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
        cp "$file" "$backup_dir/$backup_name" || warn "无法备份文件: $file"
        log "INFO" "备份文件: $file -> $backup_dir/$backup_name"
    fi
}

# 检查网络连接
check_network() {
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        error_exit "网络连接不可用"
    fi
}

# 性能监控
show_performance_info() {
    echo -e "${BLUE}系统性能信息:${NC}"
    echo -e "${CYAN}CPU使用率:${NC} $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
    echo -e "${CYAN}内存使用:${NC} $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
    echo -e "${CYAN}磁盘使用:${NC} $(df -h / | awk 'NR==2{print $5}')"
    echo -e "${CYAN}系统负载:${NC} $(uptime | awk -F'load average:' '{print $2}')"
}

# 导出所有函数供其他脚本使用
export -f log error_exit warn info validate_input check_command
export -f check_file_readable clear_screen show_header wait_for_input
export -f get_confirmation execute_command invalid_option ensure_directory
export -f backup_file check_network show_performance_info