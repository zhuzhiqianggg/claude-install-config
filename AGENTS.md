# AGENTS.md

> Claude Code 配置管理项目。AI 编码代理参考文档。

## 项目概览

Claude Code 一键安装、配置、升级工具。支持 Windows + Linux/macOS，自动从 GitHub clone Superpowers Skills。

## 核心功能

1. **一键安装** - `scripts/install.ps1` 或 `scripts/install.sh`
2. **一键更新** - `scripts/update.ps1` 或 `scripts/update.sh`
3. **API 配置** - `scripts/setup_api.ps1` 交互式切换 API 提供商
4. **MCP 管理** - `scripts/setup_mcp.ps1` 注册/管理 MCP 服务器

## 目录结构

```
├── scripts/          # 安装脚本
│   ├── install.ps1   # Windows 一键安装（主入口）
│   ├── install.sh    # Linux/macOS 一键安装
│   ├── update.ps1    # Windows 一键更新
│   ├── update.sh     # Linux/macOS 一键更新
│   ├── setup_api.ps1 # API 配置
│   └── setup_mcp.ps1 # MCP 配置
├── config/           # 配置模板
│   ├── settings.json # 标准配置（API + 权限）
│   ├── mcp.json      # MCP 服务器模板
│   ├── plugins.json  # 插件模板
│   └── CLAUDE.md     # 全局记忆模板
└── AGENTS.md         # 本文件
```

## 安装流程 (9步)

| 步骤 | 功能 | 说明 |
|------|------|------|
| 1/9 | 检查依赖 | Node.js 18+ + Git |
| 2/9 | 安装 CLI | `irm https://claude.ai/install.ps1 | iex` |
| 3/9 | 配置环境 | Git Bash 路径 (Windows only) |
| 4/9 | 配置 API | 交互式选择火山方舟/Anthropic/OpenRouter |
| 5/9 | 生成 CLAUDE.md | 全局记忆模板 |
| 6/9 | 安装 Superpowers | **git clone https://github.com/obra/superpowers** |
| 7/9 | 注册 MCP | 推荐/完整/最小 三种方案 |
| 8/9 | 验证安装 | 检查所有配置文件 |
| 9/9 | 完成提示 | 下一步指引 |

## 支持的 API 提供商

| 提供商 | Base URL | 模型 |
|--------|----------|------|
| 火山方舟 | https://ark.cn-beijing.volces.com/api/coding | doubao-seed-code-preview-latest |
| Anthropic | (官方默认) | claude-sonnet-4-20250514 |
| OpenRouter | https://openrouter.ai/api/v1 | anthropic/claude-sonnet-4-20250514 |

## 支持的 MCP 服务器

| 名称 | 功能 | 需要 API Key |
|------|------|-------------|
| context7 | 实时文档检索 | 否 |
| sequential-thinking | 结构化推理 | 否 |
| fetch | 网页抓取 | 否 |
| memory | 持久化记忆 | 否 |
| playwright | 浏览器自动化 | 否 |
| github | GitHub集成 | 是 (GITHUB_TOKEN) |

## 安装位置

| 系统 | Claude 配置目录 | Superpowers 目录 |
|------|-----------------|------------------|
| Windows | ~/.claude/ | ~/.config/superpowers/ |
| Linux/macOS | ~/.claude/ | ~/.config/superpowers/ |

## Superpowers Skills

从官方 GitHub 仓库 clone，提供：

**3 个命令：**
- `/brainstorm` - 头脑风暴
- `/write-plan` - 创建实现计划
- `/execute-plan` - 执行计划

**14 个 Skills：**
- brainstorming, writing-plans, executing-plans
- test-driven-development, systematic-debugging
- dispatching-parallel-agents, requesting-code-review
- receiving-code-review, finishing-a-development-branch
- using-git-worktrees, verification-before-completion
- using-superpowers, incremental-implementation
- context-engineering

## 代码规范

- PowerShell 脚本使用 UTF8 编码
- Bash 脚本使用 `#!/bin/bash` shebang
- 函数命名：Write-Step, Write-Ok 等 Verb-Noun 格式
- 参数使用 param() 声明，支持 [switch] 和 [ValidateSet]
