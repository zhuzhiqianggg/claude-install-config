# claude-code-config

Claude Code 一键安装、配置、升级工具。支持 Windows + Linux/macOS，自动从 GitHub clone Superpowers Skills，批量安装 21 个精选插件。

## 快速安装

### Windows (PowerShell)

```powershell
# 一键安装（推荐）
iwr -UseBasicParsing "https://raw.githubusercontent.com/zhuzhiqianggg/claude-install-config/main/scripts/install.ps1" | iex

# 一键更新
iwr -UseBasicParsing "https://raw.githubusercontent.com/zhuzhiqianggg/claude-install-config/main/scripts/update.ps1" | iex

# 或克隆后本地安装
git clone https://github.com/zhuzhiqianggg/claude-install-config.git
cd claude-install-config
.\scripts\install.ps1
```

### Linux / macOS

```bash
# 一键安装（推荐）
bash <(curl -s https://raw.githubusercontent.com/zhuzhiqianggg/claude-install-config/main/scripts/install.sh)

# 一键更新
bash <(curl -s https://raw.githubusercontent.com/zhuzhiqianggg/claude-install-config/main/scripts/update.sh)

# 或克隆后本地安装
git clone https://github.com/zhuzhiqianggg/claude-install-config.git
cd claude-install-config
chmod +x scripts/*.sh
./scripts/install.sh
```

## 功能特性

| 功能 | 说明 |
|------|------|
| 🚀 一键安装 CLI | 自动检测平台并安装最新版 |
| 🔧 Git 代理修复 | 自动检测并修复 GitHub 连接问题 |
| 🦸 Superpowers | 从 GitHub clone 官方版本 |
| 🔌 21 个精选插件 | 批量安装高质量插件 |
| 📦 MCP 服务器 | 推荐/完整/最小 三种方案 |
| ⚙️ API 配置 | 火山方舟/Anthropic/OpenRouter 交互式选择 |
| 📝 CLAUDE.md | 全局记忆模板 |
| 📖 最佳实践 | 详细的配置指南 |

## 安装流程 (11步)

| 步骤 | 功能 |
|------|------|
| 1/11 | 检查依赖 (Node.js + Git) |
| 2/11 | 安装 Claude Code CLI |
| 3/11 | 配置 Windows 环境 (Git Bash 路径) |
| 4/11 | 修复 Git GitHub 连接 |
| 5/11 | 配置 API |
| 6/11 | 生成 CLAUDE.md |
| 7/11 | 安装 Superpowers (GitHub clone) |
| 8/11 | 批量安装 21 个插件 |
| 9/11 | 注册 MCP 服务器 |
| 10/11 | 验证安装 |
| 11/11 | 完成提示 |

## 安装的插件 (21个)

| 分类 | 插件 | 说明 |
|------|------|------|
| 🦸 核心 | superpowers | 头脑风暴、TDD、系统化调试 |
| 🚀 开发 | feature-dev, ralph-loop | 特性开发全流程 |
| 🔍 审查 | code-review, code-simplifier, security-guidance | 代码审查、安全检查 |
| 📝 Git | commit-commands | 提交/推送/PR 工作流 |
| 🧠 LSP | typescript-lsp, pyright-lsp, gopls-lsp | 语言服务 |
| 📚 文档 | context7, claude-md-management | 实时文档、CLAUDE.md 管理 |
| 🛠 工具 | skill-creator, plugin-dev, mcp-server-dev | 开发工具 |
| 🎨 前端 | frontend-design, playground | 前端设计 |
| 📊 报告 | session-report, remember | 会话报告、记忆压缩 |

## 支持的 API 提供商

| 提供商 | 说明 | 默认模型 |
|--------|------|----------|
| 🔥 火山方舟 | 国内推荐 | doubao-seed-code-preview-latest |
| 🌐 Anthropic | 需要海外网络 | claude-sonnet-4-20250514 |
| 🔀 OpenRouter | 多模型聚合 | anthropic/claude-sonnet-4-20250514 |

## MCP 服务器

| 服务器 | 功能 | 需要 Key |
|--------|------|----------|
| Context7 | 实时文档检索 | 否 |
| Sequential Thinking | 结构化推理 | 否 |
| Fetch | 网页抓取 | 否 |
| Memory | 持久化记忆 | 否 |
| Playwright | 浏览器自动化 | 否 |
| GitHub | PR/Issue/代码搜索 | 是 |

## 目录结构

```
claude-code-config/
├── scripts/
│   ├── install.ps1       # Windows 一键安装
│   ├── install.sh        # Linux/macOS 一键安装
│   ├── update.ps1        # Windows 一键更新
│   ├── update.sh         # Linux/macOS 一键更新
│   ├── setup_api.ps1     # API 配置
│   ├── setup_mcp.ps1     # MCP 配置
│   └── fix-git.ps1       # Git 代理修复
├── config/
│   ├── settings.json     # 标准配置模板
│   ├── mcp.json          # MCP 服务器模板
│   ├── plugins.json      # 插件模板
│   ├── plugins.conf      # 插件列表 (21个)
│   ├── CLAUDE.md         # 全局记忆模板
│   └── best-practices.md # 最佳实践指南
├── AGENTS.md
└── README.md
```

## 最佳实践

详见 [config/best-practices.md](config/best-practices.md)

## 常用操作

```powershell
# Windows
.\scripts\install.ps1                    # 完整安装
.\scripts\install.ps1 -SkipInstall       # 跳过 CLI 安装
.\scripts\fix-git.ps1                    # 单独修复 Git
.\scripts\setup_api.ps1                  # 切换 API
.\scripts\setup_mcp.ps1                  # 管理 MCP
.\scripts\update.ps1                     # 升级

# Claude Code 内
/model doubao-seed-2.0-pro               # 切换模型
/status                                  # 验证连接
/find-skills                             # 查看 Skills
/mcp                                     # 查看 MCP 状态
```

## 配置文件位置

| 文件 | 路径 |
|------|------|
| settings.json | ~/.claude/settings.json |
| CLAUDE.md | ~/.claude/CLAUDE.md |
| plugins.json | ~/.claude/plugins.json |
| mcp.json | ~/.claude/mcp.json |
| superpowers/ | ~/.config/superpowers/ |

## 许可证

MIT
