# Claude Code 最佳实践指南

## 一、API 配置最佳实践

### 1.1 火山方舟 Coding Plan（国内推荐）

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://ark.cn-beijing.volces.com/api/coding",
    "ANTHROPIC_AUTH_TOKEN": "ark-xxx",
    "ANTHROPIC_MODEL": "doubao-seed-code-preview-latest",
    "API_TIMEOUT_MS": "600000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

**优势**：
- 国内直连，无需代理
- 9.9元/月起，性价比高
- 支持多种模型：豆包编程、DeepSeek、GLM

### 1.2 模型选择建议

| 场景 | 推荐模型 | 说明 |
|------|----------|------|
| 日常开发 | doubao-seed-code-preview-latest | 豆包编程，代码能力强 |
| 复杂推理 | ark-code-latest | DeepSeek V3.2，推理能力强 |
| 快速响应 | doubao-seed-2.0-lite | 轻量版，速度快 |
| 通用任务 | glm-5.1 | GLM，平衡性能 |

### 1.3 超时设置

```json
{
  "API_TIMEOUT_MS": "600000"  // 10分钟，适合复杂任务
}
```

## 二、权限配置最佳实践

### 2.1 推荐权限白名单

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(npm:*)", "Bash(npx:*)", "Bash(node:*)", "Bash(pnpm:*)",
      "Bash(python:*)", "Bash(pip:*)", "Bash(uv:*)",
      "Bash(ls:*)", "Bash(cat:*)", "Bash(echo:*)", "Bash(mkdir:*)",
      "Bash(dir:*)", "Bash(type:*)", "Bash(find:*)", "Bash(grep:*)",
      "Read", "Write", "Edit", "MultiEdit", "Glob", "Grep", "LS"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(format:*)",
      "Bash(del /s:*)",
      "Bash(sudo rm:*)"
    ]
  }
}
```

### 2.2 危险操作防护

- ❌ 禁止 `rm -rf` - 防止误删
- ❌ 禁止 `format` - 防止格式化磁盘
- ❌ 禁止 `del /s` - Windows 批量删除
- ❌ 禁止 `sudo rm` - 防止提权删除

## 三、MCP 服务器最佳实践

### 3.1 推荐配置（4个核心）

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

### 3.2 MCP 用途说明

| MCP | 用途 | 使用场景 |
|-----|------|----------|
| Context7 | 实时文档检索 | 查最新框架文档，防止幻觉 |
| Sequential Thinking | 结构化推理 | 复杂问题分步思考 |
| Fetch | 网页抓取 | 获取API文档、Changelog |
| Memory | 持久化记忆 | 跨会话保存关键信息 |
| Playwright | 浏览器自动化 | E2E测试、页面截图 |
| GitHub | GitHub集成 | PR/Issue/代码搜索 |

## 四、Superpowers 工作流最佳实践

### 4.1 标准开发流程

```
用户需求 → /brainstorm → /write-plan → /execute-plan → 验证 → 提交
```

### 4.2 各阶段要点

| 阶段 | 命令 | 要点 |
|------|------|------|
| 需求探索 | `/brainstorm` | 充分理解需求，不要急于写代码 |
| 计划制定 | `/write-plan` | 拆分成小任务，每个任务可独立验证 |
| 执行实现 | `/execute-plan` | 分批执行，每批有审查检查点 |
| 验证完成 | `/status` | 运行测试、lint、typecheck |

### 4.3 常用 Skills

| Skill | 触发场景 |
|-------|----------|
| `test-driven-development` | 实现新功能前 |
| `systematic-debugging` | 遇到 Bug 时 |
| `requesting-code-review` | 完成功能后 |
| `verification-before-completion` | 提交前验证 |

## 五、CLAUDE.md 最佳实践

### 5.1 推荐结构

```markdown
# 全局配置

## 用户偏好
- 语言：中文优先
- 操作系统：Windows 11 / Linux / macOS
- 终端：PowerShell / Bash

## 编码规范
- 变量声明：必须用 let/const，禁止 var
- 函数命名：camelCase
- 组件命名：PascalCase
- 注释：中文说明

## 禁止行为
- NEVER 提交密码、密钥到 Git
- NEVER 创建 v1、v2、backup 等重复文件
- NEVER 使用 rm -rf 删除文件

## 工作流
- 复杂需求先 brainstorming
- 完成后运行 lint + test 验证

## 常用命令
- 前端：pnpm lint && pnpm test
- Python：ruff check . && pytest
```

### 5.2 项目级 CLAUDE.md

在项目根目录创建 `.claude/CLAUDE.md` 或 `CLAUDE.md`：

```markdown
# 项目配置

## 技术栈
- 框架：Next.js 14
- 语言：TypeScript
- 样式：Tailwind CSS

## 项目结构
- src/app/ - 页面路由
- src/components/ - 组件
- src/lib/ - 工具函数

## 开发命令
- dev: pnpm dev
- build: pnpm build
- test: pnpm test

## 注意事项
- 使用 Server Components 优先
- 图片使用 next/image
```

## 六、性能优化建议

### 6.1 减少网络请求

```json
{
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

禁用遥测、更新检查等非必要网络请求。

### 6.2 合理设置超时

```json
{
  "env": {
    "API_TIMEOUT_MS": "600000"  // 复杂任务 10分钟
  }
}
```

### 6.3 使用本地 MCP

优先使用不需要 API Key 的 MCP 服务器：
- ✅ context7, sequential-thinking, fetch, memory
- ⚠️ github (需要 GITHUB_TOKEN)
- ⚠️ brave-search (需要 BRAVE_API_KEY)

## 七、常见问题解决

### 7.1 Git Bash 路径问题 (Windows)

```powershell
# 设置环境变量
[System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", "C:\Program Files\Git\bin\bash.exe", "User")
```

### 7.2 WSL 内存占用过高

创建 `~/.wslconfig`：

```ini
[wsl2]
memory=4GB
processors=2
```

### 7.3 权限被拒绝

检查 `settings.json` 的 `permissions.allow` 是否包含需要的操作。

## 八、推荐工具链

| 工具 | 用途 |
|------|------|
| Claude Code | AI 编程助手 |
| Superpowers | 结构化开发流程 |
| Context7 | 实时文档检索 |
| Sequential Thinking | 复杂推理 |
| Git | 版本控制 |
| pnpm | 包管理 |
