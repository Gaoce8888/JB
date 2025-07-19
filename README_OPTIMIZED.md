# Ubuntu 命令大全脚本 - 优化版本 v2.0

## 🚀 主要改进

### 1. 架构优化
- **模块化设计**: 分离通用函数到 `common_functions.sh`
- **代码复用**: 消除重复代码，提高维护性
- **统一接口**: 所有脚本使用相同的函数和变量定义

### 2. 安全性增强
- **严格模式**: 使用 `set -euo pipefail` 提高脚本安全性
- **输入验证**: 所有用户输入都经过严格验证
- **权限检查**: 自动检查命令和文件权限
- **错误处理**: 完善的错误处理和恢复机制

### 3. 性能优化
- **减少清屏**: 智能清屏，避免不必要的界面重绘
- **缓存机制**: 缓存系统信息，减少重复查询
- **并行处理**: 支持并行执行多个命令
- **资源管理**: 自动清理临时文件和资源

### 4. 用户体验改进
- **一致的界面**: 统一的颜色主题和布局
- **进度显示**: 长时间操作显示进度条
- **智能提示**: 更友好的错误信息和操作提示
- **快捷操作**: 支持快捷键和批量操作

### 5. 功能增强
- **日志记录**: 完整的操作日志记录
- **备份功能**: 自动备份重要配置文件
- **网络检查**: 自动检测网络连接状态
- **性能监控**: 实时显示系统性能信息
- **多种安装模式**: 系统级、用户级、便携式安装

## 📁 文件结构

```
ub_command_menu/
├── common_functions.sh              # 通用函数库
├── ub_commands_optimized.sh         # 主脚本 (优化版)
├── virtual_env_manager_optimized.sh # 虚拟环境管理 (优化版)
├── script_auth_manager.sh           # 脚本授权管理
├── preset_manager.sh                # 预设管理
├── install_optimized.sh             # 优化安装器
└── README_OPTIMIZED.md              # 本文档
```

## 🛠️ 安装方法

### 方法1: 使用优化安装器 (推荐)

```bash
# 下载并运行安装器
wget https://raw.githubusercontent.com/your-repo/ub-command-menu/main/install_optimized.sh
chmod +x install_optimized.sh
./install_optimized.sh
```

### 方法2: 手动安装

```bash
# 克隆仓库
git clone https://github.com/your-repo/ub-command-menu.git
cd ub-command-menu

# 设置执行权限
chmod +x *.sh

# 运行主脚本
./ub_commands_optimized.sh
```

### 方法3: 一键安装 (当前目录)

```bash
# 直接运行优化后的脚本
./ub_commands_optimized.sh
```

## 🎯 主要功能

### 1. 系统管理
- 系统信息查看
- 磁盘和内存监控
- 进程管理
- 服务状态查看
- 系统更新和清理

### 2. 软件包管理
- apt 包管理操作
- PPA 仓库管理
- .deb 文件安装
- 软件包搜索和信息查看

### 3. 文件操作
- 文件和目录管理
- 权限设置
- 文件搜索
- 内容查看

### 4. 虚拟环境管理
- Python 虚拟环境
- Node.js 环境 (通过 NVM)
- Conda 环境
- Docker 容器环境

### 5. 开发工具
- 各类开发环境配置
- 版本控制工具
- 编译工具安装

### 6. 网络工具
- 网络连接测试
- 端口扫描
- 网络配置

## 🔧 配置说明

### 配置目录结构
```
~/.ub_command_menu/
├── debug.log                    # 调试日志
├── custom_commands.conf         # 自定义命令配置
├── virtual_environments.conf    # 虚拟环境配置
├── presets.conf                # 预设配置
└── backups/                    # 备份目录
    ├── bashrc.20231201_120000.bak
    └── ...
```

### 环境变量
脚本会自动设置以下环境变量:
- `UB_CONFIG_DIR`: 配置目录路径
- `UB_LOG_FILE`: 日志文件路径

## 📊 性能监控

脚本内置性能监控功能，可以实时显示:
- CPU 使用率
- 内存使用情况
- 磁盘使用率
- 系统负载

## 🔐 安全特性

### 1. 权限管理
- 自动检查命令执行权限
- 危险操作需要确认
- 非 root 用户安全执行

### 2. 输入验证
- 文件路径验证
- 命令参数验证
- 网络地址验证

### 3. 错误处理
- 详细的错误信息
- 自动恢复机制
- 操作日志记录

## 🚀 使用示例

### 启动脚本
```bash
# 如果已安装到系统
ub

# 或者直接运行
./ub_commands_optimized.sh
```

### 查看系统性能
在主菜单中按 `S` 键，可以查看实时系统性能信息。

### 创建 Python 虚拟环境
1. 主菜单 → `V` (虚拟环境管理)
2. 选择 `1` (创建 Python 虚拟环境)
3. 输入环境名称和路径
4. 选择 Python 版本

### 自定义命令
1. 主菜单 → `9` (自定义命令)
2. 选择 `1` (添加自定义命令)
3. 输入命令名称、描述和内容

## 🐛 故障排除

### 常见问题

1. **脚本无法执行**
   ```bash
   chmod +x *.sh
   ```

2. **网络连接问题**
   检查网络连接或使用离线安装模式

3. **权限不足**
   对于系统级操作，请使用 sudo

4. **依赖缺失**
   脚本会自动检测并提示安装缺失的依赖

### 日志查看
```bash
# 查看详细日志
tail -f ~/.ub_command_menu/debug.log

# 查看错误日志
grep ERROR ~/.ub_command_menu/debug.log
```

## 🔄 更新说明

### 从旧版本升级
1. 备份现有配置: `cp -r ~/.ub_command_menu ~/.ub_command_menu.bak`
2. 运行新的安装器
3. 配置会自动迁移

### 版本兼容性
- v2.0 向后兼容 v1.x 的配置文件
- 自定义命令和预设会自动迁移

## 📝 开发指南

### 添加新功能
1. 在 `common_functions.sh` 中添加通用函数
2. 在主脚本中添加菜单项和处理函数
3. 更新帮助信息

### 代码规范
- 使用严格模式: `set -euo pipefail`
- 所有变量使用 `local` 声明
- 函数名使用下划线分隔
- 添加详细注释

## 📄 许可证

MIT License - 详见 LICENSE 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request!

## 📞 支持

如有问题，请通过以下方式联系:
- GitHub Issues
- Email: your-email@example.com

---

**享受使用 Ubuntu 命令大全脚本! 🎉**