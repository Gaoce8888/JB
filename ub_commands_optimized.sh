#!/bin/bash

# Ubuntu 命令大全脚本 - 优化版本
# 适用于 Ubuntu 22.04+
# 使用方法: 按数字键选择对应的命令或功能

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common_functions.sh" || {
    echo "错误: 无法加载通用函数库" >&2
    exit 1
}

# 初始化脚本
init_script() {
    log "INFO" "启动 Ubuntu 命令大全脚本"
    
    # 检查操作系统
    if [[ ! -f /etc/lsb-release ]] || ! grep -q "Ubuntu" /etc/lsb-release; then
        warn "此脚本专为 Ubuntu 系统设计，在其他系统上可能无法正常工作"
    fi
    
    # 检查 bash 版本
    if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
        error_exit "需要 Bash 4.0 或更高版本"
    fi
}

# 显示主菜单
show_main_menu() {
    while true; do
        clear_screen
        show_header "Ubuntu 命令大全 - 项目部署专用" "v2.0"
        
        cat << 'EOF'
请选择命令类别:
1. 系统信息与管理
2. 软件包管理
3. 文件与目录操作
4. 网络工具
5. 项目部署工具
6. 开发环境配置
7. Docker 相关命令
8. 数据库管理
9. 自定义命令
V. 虚拟环境管理
A. 脚本授权工具
P. 预设选项管理
S. 系统性能监控
H. 帮助信息
0. 退出

EOF
        
        echo -ne "${CYAN}请输入选项 [0-9/V/A/P/S/H]:${NC} "
        read -n 1 option
        echo # 换行
        
        case "$option" in
            1) system_info_menu ;;
            2) package_management_menu ;;
            3) file_operations_menu ;;
            4) network_tools_menu ;;
            5) deployment_tools_menu ;;
            6) dev_environment_menu ;;
            7) docker_menu ;;
            8) database_menu ;;
            9) custom_commands_menu ;;
            [Vv]) virtual_env_menu ;;
            [Aa]) script_auth_menu ;;
            [Pp]) preset_management_menu ;;
            [Ss]) show_performance_info; wait_for_input ;;
            [Hh]) show_help ;;
            0) exit_script ;;
            *) invalid_option ;;
        esac
    done
}

# 系统信息与管理菜单
system_info_menu() {
    local commands=(
        "1:显示系统信息:uname -a"
        "2:显示磁盘使用情况:df -h"
        "3:显示内存使用情况:free -h"
        "4:显示系统进程:ps aux"
        "5:显示系统负载:uptime"
        "6:显示系统服务状态:systemctl list-units --type=service"
        "7:更新系统:sudo apt update && sudo apt upgrade -y"
        "8:清理系统:sudo apt autoremove -y && sudo apt autoclean"
        "9:重启系统:sudo reboot"
        "0:返回主菜单:"
    )
    
    show_submenu "系统信息与管理" commands[@]
}

# 软件包管理菜单
package_management_menu() {
    local commands=(
        "1:更新软件包列表:sudo apt update"
        "2:安装软件包:install_package"
        "3:移除软件包:remove_package"
        "4:搜索软件包:search_package"
        "5:显示软件包信息:show_package_info"
        "6:列出已安装的软件包:apt list --installed"
        "7:添加 PPA 仓库:add_ppa_repository"
        "8:安装 .deb 文件:install_deb_file"
        "0:返回主菜单:"
    )
    
    show_submenu "软件包管理" commands[@]
}

# 通用子菜单显示函数
show_submenu() {
    local title="$1"
    local -n menu_commands="$2"
    
    while true; do
        clear_screen
        show_header "$title"
        
        # 显示菜单选项
        for cmd in "${menu_commands[@]}"; do
            IFS=':' read -r num desc command <<< "$cmd"
            echo -e "${YELLOW}$num.${NC} $desc"
        done
        
        echo -ne "\n${CYAN}请输入选项:${NC} "
        read -n 1 option
        echo # 换行
        
        # 处理选项
        local found=false
        for cmd in "${menu_commands[@]}"; do
            IFS=':' read -r num desc command <<< "$cmd"
            if [[ "$option" == "$num" ]]; then
                found=true
                if [[ "$num" == "0" ]]; then
                    return
                elif [[ -n "$command" ]]; then
                    if declare -f "$command" > /dev/null; then
                        # 如果是函数，调用函数
                        "$command"
                    else
                        # 如果是命令，执行命令
                        execute_command "$command"
                    fi
                fi
                break
            fi
        done
        
        if [[ "$found" == false ]]; then
            invalid_option
        fi
    done
}

# 软件包相关函数
install_package() {
    echo -ne "${CYAN}请输入要安装的软件包名称:${NC} "
    read -r package_name
    validate_input "$package_name" '^[a-zA-Z0-9][a-zA-Z0-9+.-]*$' "无效的软件包名称"
    execute_command "sudo apt install $package_name"
}

remove_package() {
    echo -ne "${CYAN}请输入要移除的软件包名称:${NC} "
    read -r package_name
    validate_input "$package_name" '^[a-zA-Z0-9][a-zA-Z0-9+.-]*$' "无效的软件包名称"
    execute_command "sudo apt remove $package_name"
}

search_package() {
    echo -ne "${CYAN}请输入要搜索的关键词:${NC} "
    read -r search_term
    validate_input "$search_term" '^.+$' "搜索关键词不能为空"
    execute_command "apt search $search_term"
}

show_package_info() {
    echo -ne "${CYAN}请输入软件包名称:${NC} "
    read -r package_name
    validate_input "$package_name" '^[a-zA-Z0-9][a-zA-Z0-9+.-]*$' "无效的软件包名称"
    execute_command "apt show $package_name"
}

add_ppa_repository() {
    echo -ne "${CYAN}请输入 PPA 地址 (格式: ppa:user/repo):${NC} "
    read -r ppa_address
    validate_input "$ppa_address" '^ppa:[a-zA-Z0-9-]+/[a-zA-Z0-9-]+$' "无效的 PPA 地址格式"
    execute_command "sudo add-apt-repository $ppa_address"
}

install_deb_file() {
    echo -ne "${CYAN}请输入 .deb 文件路径:${NC} "
    read -r deb_file
    check_file_readable "$deb_file"
    execute_command "sudo dpkg -i '$deb_file'"
}

# 文件操作菜单的简化版本
file_operations_menu() {
    local commands=(
        "1:列出目录内容:ls -la"
        "2:创建目录:create_directory"
        "3:删除文件/目录:remove_item"
        "4:复制文件/目录:copy_item"
        "5:移动文件/目录:move_item"
        "6:查找文件:find_files"
        "7:文件权限管理:manage_permissions"
        "8:查看文件内容:view_file_content"
        "0:返回主菜单:"
    )
    
    show_submenu "文件与目录操作" commands[@]
}

# 文件操作相关函数
create_directory() {
    echo -ne "${CYAN}请输入要创建的目录路径:${NC} "
    read -r dir_path
    validate_input "$dir_path" '^[^<>:"|?*]+$' "无效的目录路径"
    execute_command "mkdir -p '$dir_path'"
}

remove_item() {
    echo -ne "${CYAN}请输入要删除的文件或目录路径:${NC} "
    read -r item_path
    validate_input "$item_path" '^[^<>:"|?*]+$' "无效的路径"
    
    if [[ -d "$item_path" ]]; then
        execute_command "rm -rf '$item_path'"
    else
        execute_command "rm -f '$item_path'"
    fi
}

# 虚拟环境管理菜单
virtual_env_menu() {
    if [[ -f "$SCRIPT_DIR/virtual_env_manager.sh" ]]; then
        source "$SCRIPT_DIR/virtual_env_manager.sh"
    else
        error_exit "虚拟环境管理脚本未找到"
    fi
}

# 脚本授权管理菜单
script_auth_menu() {
    if [[ -f "$SCRIPT_DIR/script_auth_manager.sh" ]]; then
        source "$SCRIPT_DIR/script_auth_manager.sh"
    else
        error_exit "脚本授权管理脚本未找到"
    fi
}

# 预设管理菜单
preset_management_menu() {
    if [[ -f "$SCRIPT_DIR/preset_manager.sh" ]]; then
        source "$SCRIPT_DIR/preset_manager.sh"
    else
        error_exit "预设管理脚本未找到"
    fi
}

# 自定义命令菜单
custom_commands_menu() {
    local custom_file="$CONFIG_DIR/custom_commands.conf"
    
    while true; do
        clear_screen
        show_header "自定义命令管理"
        
        echo -e "${CYAN}自定义命令管理:${NC}"
        echo -e "${YELLOW}1.${NC} 添加自定义命令"
        echo -e "${YELLOW}2.${NC} 查看自定义命令"
        echo -e "${YELLOW}3.${NC} 执行自定义命令"
        echo -e "${YELLOW}4.${NC} 删除自定义命令"
        echo -e "${YELLOW}0.${NC} 返回主菜单"
        
        echo -ne "\n${CYAN}请输入选项:${NC} "
        read -n 1 option
        echo
        
        case "$option" in
            1) add_custom_command ;;
            2) view_custom_commands ;;
            3) execute_custom_command ;;
            4) delete_custom_command ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

# 自定义命令相关函数
add_custom_command() {
    ensure_directory "$(dirname "$CONFIG_DIR/custom_commands.conf")"
    
    echo -ne "${CYAN}请输入命令名称:${NC} "
    read -r cmd_name
    validate_input "$cmd_name" '^[a-zA-Z0-9_-]+$' "命令名称只能包含字母、数字、下划线和短横线"
    
    echo -ne "${CYAN}请输入命令描述:${NC} "
    read -r cmd_desc
    
    echo -ne "${CYAN}请输入要执行的命令:${NC} "
    read -r cmd_content
    
    # 保存到配置文件
    {
        echo "[$cmd_name]"
        echo "description=$cmd_desc"
        echo "command=$cmd_content"
        echo ""
    } >> "$CONFIG_DIR/custom_commands.conf"
    
    info "自定义命令已添加"
    wait_for_input
}

view_custom_commands() {
    local custom_file="$CONFIG_DIR/custom_commands.conf"
    
    if [[ ! -f "$custom_file" ]]; then
        warn "尚未添加任何自定义命令"
        wait_for_input
        return
    fi
    
    echo -e "${CYAN}已保存的自定义命令:${NC}\n"
    cat "$custom_file"
    wait_for_input
}

# 显示帮助信息
show_help() {
    clear_screen
    show_header "帮助信息"
    
    cat << 'EOF'
Ubuntu 命令大全脚本使用说明:

1. 功能概述:
   - 提供 Ubuntu 系统常用命令的图形化界面
   - 支持系统管理、软件包管理、文件操作等功能
   - 包含虚拟环境管理和自定义命令功能

2. 安全特性:
   - 所有危险操作都需要用户确认
   - 自动记录操作日志
   - 输入验证和错误处理

3. 配置文件位置:
   - 主配置目录: ~/.ub_command_menu/
   - 日志文件: ~/.ub_command_menu/debug.log
   - 备份目录: ~/.ub_command_menu/backups/

4. 快捷键:
   - Ctrl+C: 中断当前操作
   - 在任何菜单中输入对应数字或字母进行选择

5. 故障排除:
   - 查看日志文件了解错误详情
   - 确保具有必要的系统权限
   - 检查网络连接（网络相关功能）

EOF
    
    wait_for_input
}

# 退出脚本
exit_script() {
    log "INFO" "用户退出脚本"
    echo -e "\n${GREEN}感谢使用 Ubuntu 命令大全脚本!${NC}"
    exit 0
}

# 主函数
main() {
    # 捕获退出信号
    trap exit_script INT TERM
    
    # 初始化
    init_script
    
    # 显示主菜单
    show_main_menu
}

# 如果脚本被直接执行（而不是被 source），则运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi