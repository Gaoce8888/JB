#!/bin/bash

# Ubuntu命令大全脚本安装器 - 优化版本
# 通过网络指令一键安装Ubuntu命令大全脚本

# 严格模式
set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # 无颜色

# 配置变量
readonly INSTALL_DIR="/usr/local/bin/ub_command_menu"
readonly USER_INSTALL_DIR="$HOME/.local/bin/ub_command_menu"
readonly TEMP_DIR="/tmp/ub_command_menu_install"
readonly REPO_URL="https://raw.githubusercontent.com/your-repo/ub-command-menu/main"
readonly LOG_FILE="/tmp/ub_install.log"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG_FILE"
}

# 错误处理
error_exit() {
    local msg="$1"
    echo -e "${RED}错误: $msg${NC}" >&2
    log "ERROR: $msg"
    cleanup
    exit 1
}

# 信息输出
info() {
    echo -e "${GREEN}$1${NC}"
    log "INFO: $1"
}

# 警告输出
warn() {
    echo -e "${YELLOW}警告: $1${NC}"
    log "WARN: $1"
}

# 清理函数
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR" || warn "无法删除临时目录: $TEMP_DIR"
    fi
}

# 检查系统要求
check_requirements() {
    info "检查系统要求..."
    
    # 检查操作系统
    if [[ ! -f /etc/lsb-release ]] || ! grep -q "Ubuntu" /etc/lsb-release; then
        warn "此脚本专为 Ubuntu 系统设计"
    fi
    
    # 检查 bash 版本
    if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
        error_exit "需要 Bash 4.0 或更高版本，当前版本: $BASH_VERSION"
    fi
    
    # 检查必要命令
    local required_commands=("curl" "wget" "git")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            warn "命令 '$cmd' 未找到，将尝试安装"
            install_missing_tools
            break
        fi
    done
    
    # 检查网络连接
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        error_exit "网络连接不可用，无法进行在线安装"
    fi
    
    info "系统要求检查完成"
}

# 安装缺失的工具
install_missing_tools() {
    info "安装缺失的工具..."
    
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y curl wget git
    elif command -v yum &> /dev/null; then
        sudo yum install -y curl wget git
    else
        error_exit "不支持的包管理器，请手动安装 curl, wget, git"
    fi
}

# 检查安装权限
check_permissions() {
    local install_path="$1"
    
    if [[ "$install_path" == "$INSTALL_DIR" ]]; then
        if [[ "$(id -u)" != "0" ]]; then
            error_exit "系统级安装需要root权限，请使用sudo运行此脚本"
        fi
    else
        # 确保用户目录存在
        mkdir -p "$(dirname "$install_path")" || error_exit "无法创建安装目录: $(dirname "$install_path")"
    fi
}

# 选择安装模式
choose_install_mode() {
    echo -e "${CYAN}请选择安装模式:${NC}"
    echo -e "${YELLOW}1.${NC} 系统级安装 (需要sudo权限, 所有用户可用)"
    echo -e "${YELLOW}2.${NC} 用户级安装 (仅当前用户可用)"
    echo -e "${YELLOW}3.${NC} 便携式安装 (指定目录)"
    
    while true; do
        echo -ne "${CYAN}请输入选项 [1-3]:${NC} "
        read -r choice
        
        case "$choice" in
            1) 
                check_permissions "$INSTALL_DIR"
                echo "$INSTALL_DIR"
                return
                ;;
            2) 
                check_permissions "$USER_INSTALL_DIR"
                echo "$USER_INSTALL_DIR"
                return
                ;;
            3)
                echo -ne "${CYAN}请输入安装目录:${NC} "
                read -r custom_dir
                if [[ -z "$custom_dir" ]]; then
                    warn "目录不能为空"
                    continue
                fi
                # 展开路径
                custom_dir="${custom_dir/#\~/$HOME}"
                check_permissions "$custom_dir"
                echo "$custom_dir"
                return
                ;;
            *)
                warn "无效选项，请重新选择"
                ;;
        esac
    done
}

# 显示进度条
show_progress() {
    local duration="$1"
    local message="$2"
    local progress=0
    local bar_length=30
    
    echo -ne "${message} ["
    
    while [[ $progress -le $bar_length ]]; do
        local percentage=$((progress * 100 / bar_length))
        echo -ne "\r${message} ["
        
        for ((i=0; i<progress; i++)); do
            echo -ne "█"
        done
        
        for ((i=progress; i<bar_length; i++)); do
            echo -ne " "
        done
        
        echo -ne "] ${percentage}%"
        
        progress=$((progress + 1))
        sleep "$duration"
    done
    
    echo -e " ${GREEN}完成${NC}"
}

# 下载文件
download_files() {
    local install_dir="$1"
    
    info "创建临时下载目录..."
    mkdir -p "$TEMP_DIR" || error_exit "无法创建临时目录"
    
    # 要下载的文件列表
    local files=(
        "common_functions.sh"
        "ub_commands_optimized.sh"
        "virtual_env_manager_optimized.sh"
        "script_auth_manager.sh"
        "preset_manager.sh"
    )
    
    info "开始下载脚本文件..."
    
    for file in "${files[@]}"; do
        echo -ne "${CYAN}下载 $file...${NC} "
        
        # 首先尝试当前目录
        if [[ -f "$file" ]]; then
            cp "$file" "$TEMP_DIR/" || error_exit "无法复制文件: $file"
            echo -e "${GREEN}✓${NC}"
        # 然后尝试从网络下载
        elif curl -fsSL "$REPO_URL/$file" -o "$TEMP_DIR/$file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        # 如果网络下载失败，创建基本版本
        else
            warn "无法下载 $file，将创建基本版本"
            create_basic_file "$file" "$TEMP_DIR"
        fi
    done
    
    info "文件下载完成"
}

# 创建基本文件（当网络下载失败时）
create_basic_file() {
    local filename="$1"
    local target_dir="$2"
    
    case "$filename" in
        "common_functions.sh")
            # 如果当前目录存在，直接复制
            if [[ -f "common_functions.sh" ]]; then
                cp "common_functions.sh" "$target_dir/"
            fi
            ;;
        "ub_commands_optimized.sh")
            if [[ -f "ub_commands_optimized.sh" ]]; then
                cp "ub_commands_optimized.sh" "$target_dir/"
            elif [[ -f "ub_commands.sh" ]]; then
                cp "ub_commands.sh" "$target_dir/ub_commands_optimized.sh"
            fi
            ;;
        *)
            # 对于其他文件，检查是否存在原始版本
            local original_name="${filename/_optimized/}"
            if [[ -f "$original_name" ]]; then
                cp "$original_name" "$target_dir/$filename"
            fi
            ;;
    esac
}

# 安装文件
install_files() {
    local install_dir="$1"
    
    info "安装脚本文件到: $install_dir"
    
    # 创建安装目录
    mkdir -p "$install_dir" || error_exit "无法创建安装目录: $install_dir"
    
    # 复制文件
    cp -r "$TEMP_DIR"/* "$install_dir/" || error_exit "无法复制文件到安装目录"
    
    # 设置执行权限
    find "$install_dir" -name "*.sh" -exec chmod +x {} \; || error_exit "无法设置执行权限"
    
    info "文件安装完成"
}

# 创建系统链接
create_system_links() {
    local install_dir="$1"
    
    # 系统级安装创建软链接
    if [[ "$install_dir" == "$INSTALL_DIR" ]]; then
        info "创建系统命令链接..."
        
        # 创建主命令链接
        ln -sf "$install_dir/ub_commands_optimized.sh" "/usr/local/bin/ub" || warn "无法创建系统链接"
        ln -sf "$install_dir/ub_commands_optimized.sh" "/usr/local/bin/ubuntu-commands" || warn "无法创建系统链接"
        
        info "系统命令链接创建完成"
        echo -e "${CYAN}您现在可以使用以下命令启动:${NC}"
        echo -e "  - ${YELLOW}ub${NC}"
        echo -e "  - ${YELLOW}ubuntu-commands${NC}"
    
    # 用户级安装更新PATH
    elif [[ "$install_dir" == "$USER_INSTALL_DIR" ]]; then
        info "配置用户环境..."
        
        # 添加到用户的 .bashrc
        local bashrc="$HOME/.bashrc"
        if [[ -f "$bashrc" ]] && ! grep -q "$USER_INSTALL_DIR" "$bashrc"; then
            echo "" >> "$bashrc"
            echo "# Ubuntu 命令大全脚本" >> "$bashrc"
            echo "export PATH=\"$USER_INSTALL_DIR:\$PATH\"" >> "$bashrc"
            echo "alias ub='$install_dir/ub_commands_optimized.sh'" >> "$bashrc"
            
            info "已添加到用户环境变量"
            echo -e "${CYAN}请运行以下命令重新加载环境:${NC}"
            echo -e "  ${YELLOW}source ~/.bashrc${NC}"
        fi
    fi
}

# 验证安装
verify_installation() {
    local install_dir="$1"
    
    info "验证安装..."
    
    # 检查主脚本是否存在且可执行
    local main_script="$install_dir/ub_commands_optimized.sh"
    if [[ ! -f "$main_script" ]]; then
        error_exit "主脚本文件未找到: $main_script"
    fi
    
    if [[ ! -x "$main_script" ]]; then
        error_exit "主脚本文件不可执行: $main_script"
    fi
    
    # 测试脚本语法
    if ! bash -n "$main_script"; then
        error_exit "主脚本语法错误"
    fi
    
    info "安装验证完成"
}

# 显示安装完成信息
show_completion_message() {
    local install_dir="$1"
    
    clear
    echo -e "${BLUE}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                                               │${NC}"
    echo -e "${BLUE}│${GREEN}        Ubuntu命令大全脚本安装成功!           ${BLUE}│${NC}"
    echo -e "${BLUE}│                                               │${NC}"
    echo -e "${BLUE}└───────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${CYAN}安装位置:${NC} $install_dir"
    echo -e "${CYAN}启动命令:${NC} $install_dir/ub_commands_optimized.sh"
    echo ""
    
    if [[ "$install_dir" == "$INSTALL_DIR" ]]; then
        echo -e "${CYAN}系统命令:${NC}"
        echo -e "  - ${YELLOW}ub${NC}"
        echo -e "  - ${YELLOW}ubuntu-commands${NC}"
    elif [[ "$install_dir" == "$USER_INSTALL_DIR" ]]; then
        echo -e "${CYAN}用户命令 (重新加载终端后可用):${NC}"
        echo -e "  - ${YELLOW}ub${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}配置目录:${NC} ~/.ub_command_menu/"
    echo -e "${CYAN}日志文件:${NC} ~/.ub_command_menu/debug.log"
    echo ""
    echo -e "${GREEN}享受使用 Ubuntu 命令大全脚本!${NC}"
}

# 主安装函数
main() {
    # 设置错误陷阱
    trap cleanup EXIT
    
    # 显示标题
    clear
    echo -e "${BLUE}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                                               │${NC}"
    echo -e "${BLUE}│${YELLOW}       Ubuntu命令大全脚本 - 安装器            ${BLUE}│${NC}"
    echo -e "${BLUE}│${GREEN}                   v2.0                       ${BLUE}│${NC}"
    echo -e "${BLUE}│                                               │${NC}"
    echo -e "${BLUE}└───────────────────────────────────────────────┘${NC}"
    echo ""
    
    # 检查系统要求
    check_requirements
    
    # 选择安装模式
    local install_dir
    install_dir=$(choose_install_mode)
    
    # 开始安装过程
    echo ""
    info "开始安装过程..."
    
    # 下载文件
    download_files "$install_dir"
    
    # 安装文件
    install_files "$install_dir"
    
    # 创建系统链接
    create_system_links "$install_dir"
    
    # 验证安装
    verify_installation "$install_dir"
    
    # 显示完成信息
    show_completion_message "$install_dir"
    
    # 清理临时文件
    cleanup
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi