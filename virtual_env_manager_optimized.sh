#!/bin/bash

# 虚拟环境管理脚本 - 优化版本
# 提供创建、进入、激活和退出虚拟环境的功能

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common_functions.sh" || {
    echo "错误: 无法加载通用函数库" >&2
    exit 1
}

# 虚拟环境配置
readonly VENV_CONFIG_FILE="$CONFIG_DIR/virtual_environments.conf"

# 初始化虚拟环境管理器
init_venv_manager() {
    ensure_directory "$CONFIG_DIR"
    
    # 创建配置文件模板
    if [[ ! -f "$VENV_CONFIG_FILE" ]]; then
        cat > "$VENV_CONFIG_FILE" << 'EOF'
# 虚拟环境配置文件
# 格式: [环境名称]
# type=python|node|conda|docker
# path=/path/to/environment
# description=环境描述
# created=YYYY-MM-DD
EOF
    fi
}

# 显示虚拟环境菜单
show_virtual_env_menu() {
    while true; do
        clear_screen
        show_header "虚拟环境管理工具"
        
        echo -e "${CYAN}虚拟环境管理:${NC}"
        echo -e "${YELLOW}1.${NC} 创建 Python 虚拟环境"
        echo -e "${YELLOW}2.${NC} 创建 Node.js 环境"
        echo -e "${YELLOW}3.${NC} 创建 Conda 环境"
        echo -e "${YELLOW}4.${NC} 创建 Docker 容器环境"
        echo -e "${YELLOW}5.${NC} 列出所有环境"
        echo -e "${YELLOW}6.${NC} 激活环境"
        echo -e "${YELLOW}7.${NC} 删除环境"
        echo -e "${YELLOW}8.${NC} 环境信息"
        echo -e "${YELLOW}0.${NC} 返回主菜单"
        
        echo -ne "\n${CYAN}请输入选项 [0-8]:${NC} "
        read -n 1 option
        echo
        
        case "$option" in
            1) create_python_venv ;;
            2) create_node_env ;;
            3) create_conda_env ;;
            4) create_docker_env ;;
            5) list_all_environments ;;
            6) activate_environment ;;
            7) delete_environment ;;
            8) show_environment_info ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

# 创建Python虚拟环境
create_python_venv() {
    clear_screen
    show_header "创建Python虚拟环境"
    
    # 检查Python是否安装
    if ! command -v python3 &> /dev/null; then
        error_exit "Python3 未安装，请先安装 Python3"
    fi
    
    echo -ne "${CYAN}请输入环境名称:${NC} "
    read -r env_name
    validate_input "$env_name" '^[a-zA-Z0-9_-]+$' "环境名称只能包含字母、数字、下划线和短横线"
    
    echo -ne "${CYAN}请输入安装路径 (留空使用默认 ~/.venvs/$env_name):${NC} "
    read -r venv_path
    
    if [[ -z "$venv_path" ]]; then
        venv_path="$HOME/.venvs/$env_name"
    fi
    
    # 展开路径中的~符号
    venv_path="${venv_path/#\~/$HOME}"
    
    # 检查环境是否已存在
    if [[ -d "$venv_path" ]]; then
        error_exit "虚拟环境路径已存在: $venv_path"
    fi
    
    echo -ne "${CYAN}请选择Python版本 [1]Python3 [2]指定版本:${NC} "
    read -n 1 python_option
    echo
    
    local python_cmd="python3"
    if [[ "$python_option" == "2" ]]; then
        echo -ne "${CYAN}请输入Python版本 (如: 3.9):${NC} "
        read -r python_version
        python_cmd="python$python_version"
        
        if ! command -v "$python_cmd" &> /dev/null; then
            error_exit "Python $python_version 未安装"
        fi
    fi
    
    # 创建虚拟环境
    ensure_directory "$(dirname "$venv_path")"
    
    if execute_command "$python_cmd -m venv '$venv_path'" false; then
        # 保存环境信息
        save_environment_info "$env_name" "python" "$venv_path" "Python虚拟环境"
        info "Python虚拟环境创建成功"
        echo -e "${CYAN}激活命令: source '$venv_path/bin/activate'${NC}"
    fi
    
    wait_for_input
}

# 创建Node.js环境
create_node_env() {
    clear_screen
    show_header "创建Node.js环境"
    
    # 检查是否需要安装NVM
    if ! command -v nvm &> /dev/null && [[ ! -f "$HOME/.nvm/nvm.sh" ]]; then
        echo -e "${YELLOW}NVM (Node Version Manager) 未安装${NC}"
        if get_confirmation "是否安装 NVM？"; then
            install_nvm
        else
            warn "无法创建Node.js环境，需要先安装NVM"
            wait_for_input
            return
        fi
    fi
    
    # 加载NVM
    if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
        source "$HOME/.nvm/nvm.sh"
    fi
    
    echo -ne "${CYAN}请输入环境名称:${NC} "
    read -r env_name
    validate_input "$env_name" '^[a-zA-Z0-9_-]+$' "环境名称只能包含字母、数字、下划线和短横线"
    
    echo -ne "${CYAN}请输入Node.js版本 (如: 18, 16, lts):${NC} "
    read -r node_version
    
    # 安装指定版本的Node.js
    if execute_command "nvm install $node_version" false; then
        execute_command "nvm alias $env_name $node_version" false
        save_environment_info "$env_name" "node" "$HOME/.nvm/versions/node/v$node_version" "Node.js环境 v$node_version"
        info "Node.js环境创建成功"
        echo -e "${CYAN}切换命令: nvm use $env_name${NC}"
    fi
    
    wait_for_input
}

# 创建Conda环境
create_conda_env() {
    clear_screen
    show_header "创建Conda环境"
    
    # 检查Conda是否安装
    if ! command -v conda &> /dev/null; then
        echo -e "${YELLOW}Conda 未安装${NC}"
        if get_confirmation "是否安装 Miniconda？"; then
            install_miniconda
        else
            warn "无法创建Conda环境，需要先安装Conda"
            wait_for_input
            return
        fi
    fi
    
    echo -ne "${CYAN}请输入环境名称:${NC} "
    read -r env_name
    validate_input "$env_name" '^[a-zA-Z0-9_-]+$' "环境名称只能包含字母、数字、下划线和短横线"
    
    echo -ne "${CYAN}请输入Python版本 (如: 3.9, 3.10):${NC} "
    read -r python_version
    
    # 创建Conda环境
    if execute_command "conda create -n $env_name python=$python_version" false; then
        local conda_env_path="$(conda info --base)/envs/$env_name"
        save_environment_info "$env_name" "conda" "$conda_env_path" "Conda环境 Python $python_version"
        info "Conda环境创建成功"
        echo -e "${CYAN}激活命令: conda activate $env_name${NC}"
    fi
    
    wait_for_input
}

# 创建Docker容器环境
create_docker_env() {
    clear_screen
    show_header "创建Docker容器环境"
    
    # 检查Docker是否安装
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker 未安装${NC}"
        if get_confirmation "是否安装 Docker？"; then
            install_docker
        else
            warn "无法创建Docker环境，需要先安装Docker"
            wait_for_input
            return
        fi
    fi
    
    echo -ne "${CYAN}请输入容器名称:${NC} "
    read -r container_name
    validate_input "$container_name" '^[a-zA-Z0-9_-]+$' "容器名称只能包含字母、数字、下划线和短横线"
    
    echo -ne "${CYAN}请输入镜像名称 (如: ubuntu:22.04, python:3.9):${NC} "
    read -r image_name
    
    echo -ne "${CYAN}是否映射端口？ [y/N]:${NC} "
    read -n 1 map_port
    echo
    
    local port_mapping=""
    if [[ "$map_port" =~ ^[Yy]$ ]]; then
        echo -ne "${CYAN}请输入端口映射 (格式: 主机端口:容器端口):${NC} "
        read -r port_mapping
        port_mapping=" -p $port_mapping"
    fi
    
    echo -ne "${CYAN}是否映射卷？ [y/N]:${NC} "
    read -n 1 map_volume
    echo
    
    local volume_mapping=""
    if [[ "$map_volume" =~ ^[Yy]$ ]]; then
        echo -ne "${CYAN}请输入卷映射 (格式: 主机路径:容器路径):${NC} "
        read -r volume_mapping
        volume_mapping=" -v $volume_mapping"
    fi
    
    # 创建并运行容器
    local docker_cmd="docker run -dit --name $container_name$port_mapping$volume_mapping $image_name"
    
    if execute_command "$docker_cmd" false; then
        save_environment_info "$container_name" "docker" "/var/lib/docker/containers" "Docker容器 ($image_name)"
        info "Docker容器创建成功"
        echo -e "${CYAN}进入命令: docker exec -it $container_name /bin/bash${NC}"
    fi
    
    wait_for_input
}

# 列出所有环境
list_all_environments() {
    clear_screen
    show_header "所有虚拟环境"
    
    if [[ ! -f "$VENV_CONFIG_FILE" ]]; then
        warn "未找到任何环境配置"
        wait_for_input
        return
    fi
    
    echo -e "${CYAN}已配置的虚拟环境:${NC}\n"
    
    local env_count=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            local env_name="${BASH_REMATCH[1]}"
            env_count=$((env_count + 1))
            echo -e "${YELLOW}$env_count. $env_name${NC}"
            
            # 读取环境详细信息
            while IFS= read -r detail_line && [[ -n "$detail_line" ]]; do
                if [[ "$detail_line" =~ ^([^=]+)=(.+)$ ]]; then
                    local key="${BASH_REMATCH[1]}"
                    local value="${BASH_REMATCH[2]}"
                    echo -e "   ${CYAN}$key:${NC} $value"
                fi
            done
            echo
        fi
    done < "$VENV_CONFIG_FILE"
    
    if [[ "$env_count" -eq 0 ]]; then
        warn "未找到任何已配置的环境"
    fi
    
    wait_for_input
}

# 保存环境信息
save_environment_info() {
    local env_name="$1"
    local env_type="$2"
    local env_path="$3"
    local description="$4"
    
    {
        echo "[$env_name]"
        echo "type=$env_type"
        echo "path=$env_path"
        echo "description=$description"
        echo "created=$(date +%Y-%m-%d)"
        echo ""
    } >> "$VENV_CONFIG_FILE"
    
    log "INFO" "保存环境信息: $env_name ($env_type)"
}

# 安装工具函数
install_nvm() {
    check_network
    execute_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    info "请重新打开终端或运行: source ~/.bashrc"
}

install_miniconda() {
    check_network
    local miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    execute_command "wget $miniconda_url -O /tmp/miniconda.sh && bash /tmp/miniconda.sh"
}

install_docker() {
    check_network
    execute_command "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    execute_command "sudo usermod -aG docker $USER"
    info "请重新登录以使Docker权限生效"
}

# 如果脚本被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_venv_manager
    show_virtual_env_menu
fi