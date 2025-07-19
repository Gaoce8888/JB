#!/bin/bash

# Ubuntu 命令大全脚本 - 优化版 v2.0
# 适用于 Ubuntu 22.04
# 改进：性能优化、错误处理、日志记录、用户体验增强

# 全局变量和配置
SCRIPT_VERSION="2.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.ub_command_menu"
LOG_DIR="$CONFIG_DIR/logs"
HISTORY_FILE="$CONFIG_DIR/command_history"
CACHE_DIR="$CONFIG_DIR/cache"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # 无颜色

# 初始化环境
init_environment() {
    # 创建必要的目录
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$CACHE_DIR" 2>/dev/null
    
    # 创建历史文件
    touch "$HISTORY_FILE" 2>/dev/null
    
    # 设置日志文件
    LOG_FILE="$LOG_DIR/ub_commands_$(date +%Y%m%d).log"
}

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 优化的执行命令函数
execute_command() {
    local cmd="$1"
    local timeout="${2:-30}"  # 默认30秒超时
    local confirm_dangerous="${3:-true}"
    
    # 危险命令列表
    local dangerous_patterns=("rm -rf" "dd if=" "mkfs" "fdisk" "> /dev/" "shutdown" "reboot")
    
    # 检查危险命令
    if [[ "$confirm_dangerous" == "true" ]]; then
        for pattern in "${dangerous_patterns[@]}"; do
            if [[ "$cmd" == *"$pattern"* ]]; then
                echo -e "${RED}${BOLD}⚠️  警告: 检测到潜在危险命令！${NC}"
                echo -e "${YELLOW}命令: $cmd${NC}"
                echo -ne "${CYAN}确定要执行吗? (y/N): ${NC}"
                read -n 1 confirm
                echo
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    log "WARN" "用户取消了危险命令: $cmd"
                    echo -e "${GREEN}✓ 已取消执行${NC}"
                    return 1
                fi
                break
            fi
        done
    fi
    
    # 显示命令
    echo -e "\n${GREEN}▶ 执行命令: ${YELLOW}$cmd${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 记录到历史
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $cmd" >> "$HISTORY_FILE"
    log "INFO" "执行命令: $cmd"
    
    # 执行命令
    local start_time=$(date +%s.%N)
    
    # 使用timeout命令防止命令卡住
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout" bash -c "$cmd"
        local exit_code=$?
    else
        eval "$cmd"
        local exit_code=$?
    fi
    
    # 计算执行时间
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    duration=$(printf "%.2f" $duration)
    
    # 显示结果
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ $exit_code -eq 0 ]]; then
        log "INFO" "命令成功执行 (耗时: ${duration}秒)"
        echo -e "${GREEN}✓ 命令执行成功${NC} ${WHITE}(耗时: ${duration}秒)${NC}"
    elif [[ $exit_code -eq 124 ]]; then
        log "ERROR" "命令执行超时"
        echo -e "${RED}✗ 命令执行超时${NC} ${WHITE}(超时时间: ${timeout}秒)${NC}"
    else
        log "ERROR" "命令执行失败 (退出码: $exit_code)"
        echo -e "${RED}✗ 命令执行失败${NC} ${WHITE}(退出码: $exit_code)${NC}"
    fi
    
    echo -e "\n${CYAN}按任意键继续...${NC}"
    read -n 1
    
    return $exit_code
}

# 清屏函数
clear_screen() {
    clear
    # 显示简洁的顶部信息
    echo -e "${BLUE}Ubuntu 命令工具 v${SCRIPT_VERSION}${NC} | ${WHITE}$(date '+%Y-%m-%d %H:%M')${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 显示主标题
show_header() {
    echo -e "${BOLD}${YELLOW}Ubuntu 命令大全 - 项目部署专用${NC}"
    echo -e "${GREEN}优化版 v${SCRIPT_VERSION}${NC}\n"
}

# 改进的菜单显示函数
show_menu_items() {
    local items=("$@")
    local cols=2  # 两列显示
    local width=30  # 每列宽度
    local count=${#items[@]}
    local rows=$(( (count + cols - 1) / cols ))
    
    for ((row=0; row<rows; row++)); do
        for ((col=0; col<cols; col++)); do
            local idx=$((row + col * rows))
            if [[ $idx -lt $count ]]; then
                printf "%-${width}s" "${items[$idx]}"
            fi
        done
        echo
    done
}

# 输入验证函数
validate_input() {
    local input="$1"
    local type="$2"
    
    case "$type" in
        "number")
            [[ "$input" =~ ^[0-9]+$ ]] && return 0
            echo -e "${RED}错误: 请输入有效的数字${NC}"
            return 1
            ;;
        "path")
            # 展开波浪号
            input="${input/#\~/$HOME}"
            [[ -e "$input" ]] && return 0
            echo -e "${RED}错误: 路径不存在: $input${NC}"
            return 1
            ;;
        "file")
            input="${input/#\~/$HOME}"
            [[ -f "$input" ]] && return 0
            echo -e "${RED}错误: 文件不存在: $input${NC}"
            return 1
            ;;
        "directory")
            input="${input/#\~/$HOME}"
            [[ -d "$input" ]] && return 0
            echo -e "${RED}错误: 目录不存在: $input${NC}"
            return 1
            ;;
    esac
}

# 无效选项提示（改进版）
invalid_option() {
    echo -e "\n${RED}✗ 无效选项！${NC}"
    sleep 1
}

# 返回菜单提示
press_any_key() {
    echo -e "\n${CYAN}按任意键返回...${NC}"
    read -n 1
}

# 确认操作
confirm_action() {
    local prompt="${1:-确定要继续吗?}"
    echo -ne "${YELLOW}${prompt} (y/N): ${NC}"
    read -n 1 confirm
    echo
    [[ "$confirm" =~ ^[Yy]$ ]]
}

# 显示加载动画
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# 初始化
init_environment

# 显示主菜单（优化版）
show_main_menu() {
    while true; do
        clear_screen
        show_header
        
        echo -e "${CYAN}主菜单${NC}"
        echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        # 使用改进的菜单显示
        local menu_items=(
            "${YELLOW}1.${NC} 系统信息与管理"
            "${YELLOW}2.${NC} 软件包管理"
            "${YELLOW}3.${NC} 文件与目录操作"
            "${YELLOW}4.${NC} 网络工具"
            "${YELLOW}5.${NC} 项目部署工具"
            "${YELLOW}6.${NC} 开发环境配置"
            "${YELLOW}7.${NC} Docker 容器管理"
            "${YELLOW}8.${NC} 数据库管理"
            "${YELLOW}9.${NC} 自定义命令"
            "${YELLOW}H.${NC} 命令历史"
            "${YELLOW}V.${NC} 虚拟环境管理"
            "${YELLOW}A.${NC} 脚本授权工具"
            "${YELLOW}P.${NC} 预设选项管理"
            "${YELLOW}S.${NC} 系统设置"
            "${YELLOW}0.${NC} 退出"
        )
        
        show_menu_items "${menu_items[@]}"
        
        echo -e "\n${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -ne "${CYAN}请选择操作: ${NC}"
        
        read -n 1 option
        echo
        
        case ${option,,} in  # 转换为小写
            1) system_info_menu ;;
            2) package_management_menu ;;
            3) file_operations_menu ;;
            4) network_tools_menu ;;
            5) deployment_tools_menu ;;
            6) dev_environment_menu ;;
            7) docker_menu ;;
            8) database_menu ;;
            9) custom_commands_menu ;;
            h) show_command_history ;;
            v) source "$SCRIPT_DIR/virtual_env_manager.sh" && virtual_env_menu ;;
            a) source "$SCRIPT_DIR/script_auth_manager.sh" && script_auth_menu ;;
            p) source "$SCRIPT_DIR/preset_manager.sh" && preset_menu ;;
            s) settings_menu ;;
            0) exit_script ;;
            *) invalid_option ;;
        esac
    done
}

# 系统信息与管理菜单（优化版）
system_info_menu() {
    while true; do
        clear_screen
        echo -e "${CYAN}系统信息与管理${NC}"
        echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        # 显示基本系统信息
        echo -e "${GREEN}系统概览:${NC}"
        echo -e "  ${WHITE}主机名:${NC} $(hostname)"
        echo -e "  ${WHITE}内核:${NC} $(uname -r)"
        echo -e "  ${WHITE}运行时间:${NC} $(uptime -p)"
        echo -e "  ${WHITE}负载:${NC} $(uptime | awk -F'load average:' '{print $2}')"
        echo
        
        local menu_items=(
            "${YELLOW}1.${NC} 显示详细系统信息"
            "${YELLOW}2.${NC} 磁盘使用情况"
            "${YELLOW}3.${NC} 内存使用情况"
            "${YELLOW}4.${NC} 进程管理"
            "${YELLOW}5.${NC} 系统服务管理"
            "${YELLOW}6.${NC} 系统更新"
            "${YELLOW}7.${NC} 系统清理"
            "${YELLOW}8.${NC} 系统监控 (htop)"
            "${YELLOW}9.${NC} 查看系统日志"
            "${YELLOW}0.${NC} 返回主菜单"
        )
        
        show_menu_items "${menu_items[@]}"
        
        echo -e "\n${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -ne "${CYAN}请选择操作: ${NC}"
        
        read -n 1 option
        echo
        
        case $option in
            1) execute_command "uname -a && lsb_release -a" ;;
            2) disk_usage_menu ;;
            3) memory_usage_menu ;;
            4) process_management_menu ;;
            5) service_management_menu ;;
            6) system_update_menu ;;
            7) system_cleanup_menu ;;
            8) 
                if ! command -v htop &> /dev/null; then
                    echo -e "${YELLOW}htop 未安装，正在安装...${NC}"
                    execute_command "sudo apt install -y htop"
                fi
                execute_command "htop"
                ;;
            9) log_viewer_menu ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

# 磁盘使用情况子菜单
disk_usage_menu() {
    clear_screen
    echo -e "${CYAN}磁盘使用情况${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # 显示磁盘使用概览
    execute_command "df -h | grep -E '^/dev/|^Filesystem'" 30 false
    
    echo -e "\n${YELLOW}选项:${NC}"
    echo -e "1. 查看指定目录的磁盘使用"
    echo -e "2. 查找大文件 (>100MB)"
    echo -e "3. 分析目录空间占用"
    echo -e "0. 返回"
    
    echo -ne "\n${CYAN}请选择: ${NC}"
    read -n 1 option
    echo
    
    case $option in
        1)
            echo -ne "${CYAN}请输入目录路径: ${NC}"
            read dir_path
            dir_path="${dir_path:-/}"
            execute_command "du -h --max-depth=1 $dir_path | sort -hr | head -20"
            ;;
        2)
            echo -ne "${CYAN}请输入搜索路径 (默认: /home): ${NC}"
            read search_path
            search_path="${search_path:-/home}"
            execute_command "find $search_path -type f -size +100M -exec ls -lh {} \; 2>/dev/null | sort -k5 -hr"
            ;;
        3)
            if ! command -v ncdu &> /dev/null; then
                echo -e "${YELLOW}ncdu 未安装，正在安装...${NC}"
                execute_command "sudo apt install -y ncdu"
            fi
            echo -ne "${CYAN}请输入要分析的目录: ${NC}"
            read analyze_dir
            analyze_dir="${analyze_dir:-/}"
            execute_command "ncdu $analyze_dir"
            ;;
    esac
}

# 内存使用情况子菜单
memory_usage_menu() {
    clear_screen
    echo -e "${CYAN}内存使用情况${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    execute_command "free -h" 30 false
    echo
    execute_command "echo '内存占用最高的10个进程:' && ps aux --sort=-%mem | head -11" 30 false
    
    press_any_key
}

# 进程管理子菜单
process_management_menu() {
    while true; do
        clear_screen
        echo -e "${CYAN}进程管理${NC}"
        echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        echo -e "${YELLOW}1.${NC} 查看所有进程"
        echo -e "${YELLOW}2.${NC} 按CPU使用率排序"
        echo -e "${YELLOW}3.${NC} 按内存使用率排序"
        echo -e "${YELLOW}4.${NC} 查找进程"
        echo -e "${YELLOW}5.${NC} 结束进程"
        echo -e "${YELLOW}6.${NC} 查看进程树"
        echo -e "${YELLOW}0.${NC} 返回"
        
        echo -ne "\n${CYAN}请选择: ${NC}"
        read -n 1 option
        echo
        
        case $option in
            1) execute_command "ps aux | less" ;;
            2) execute_command "ps aux --sort=-pcpu | head -20" ;;
            3) execute_command "ps aux --sort=-%mem | head -20" ;;
            4)
                echo -ne "${CYAN}请输入进程名称: ${NC}"
                read process_name
                execute_command "ps aux | grep -i $process_name | grep -v grep"
                ;;
            5)
                echo -ne "${CYAN}请输入进程PID: ${NC}"
                read pid
                if validate_input "$pid" "number"; then
                    execute_command "kill -9 $pid"
                fi
                ;;
            6)
                if ! command -v pstree &> /dev/null; then
                    echo -e "${YELLOW}pstree 未安装，正在安装...${NC}"
                    execute_command "sudo apt install -y psmisc"
                fi
                execute_command "pstree -p"
                ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

# 显示命令历史
show_command_history() {
    clear_screen
    echo -e "${CYAN}命令历史${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [[ -f "$HISTORY_FILE" ]]; then
        echo -e "${GREEN}最近执行的命令:${NC}\n"
        tail -50 "$HISTORY_FILE" | nl -w3 -s'. '
        echo -e "\n${YELLOW}选项:${NC}"
        echo -e "1. 清空历史"
        echo -e "2. 搜索历史"
        echo -e "0. 返回"
        
        echo -ne "\n${CYAN}请选择: ${NC}"
        read -n 1 option
        echo
        
        case $option in
            1)
                if confirm_action "确定要清空命令历史吗?"; then
                    > "$HISTORY_FILE"
                    echo -e "${GREEN}✓ 历史已清空${NC}"
                    sleep 1
                fi
                ;;
            2)
                echo -ne "${CYAN}请输入搜索关键词: ${NC}"
                read keyword
                grep -i "$keyword" "$HISTORY_FILE" | tail -20 | nl -w3 -s'. '
                press_any_key
                ;;
        esac
    else
        echo -e "${YELLOW}暂无命令历史${NC}"
        press_any_key
    fi
}

# 退出脚本
exit_script() {
    clear_screen
    echo -e "${GREEN}感谢使用 Ubuntu 命令大全！${NC}"
    echo -e "${WHITE}日志文件保存在: $LOG_FILE${NC}"
    log "INFO" "脚本正常退出"
    exit 0
}

# 启动主菜单
show_main_menu