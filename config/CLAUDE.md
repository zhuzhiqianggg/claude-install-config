# 全局配置

## 用户偏好
- 语言：中文优先，代码注释用中文
- 操作系统：Windows 11 / Linux / macOS
- 终端：PowerShell / Git Bash / Zsh
- 编辑器：VSCode / Trae IDE

## 编码规范
- 变量声明：必须用 `let` 或 `const`，禁止用 `var`
- 函数命名：camelCase，动词开头
- 组件命名：PascalCase
- 文件命名：snake_case（Python），kebab-case（前端）
- 所有函数必须有类型标注（TypeScript）或中文注释（Python）

## 禁止行为
- NEVER 直接修改 node_modules
- NEVER 提交密码、密钥、Token到Git
- NEVER 创建v1、v2、backup等重复文件
- NEVER 使用 rm -rf 删除文件，用 mv 移至 .trash/
- NEVER 在没有测试的情况下提交代码

## 工作流
- 使用 Superpowers Skills 进行结构化开发
- 复杂需求先 brainstorming，再 writing-plans，最后执行
- 代码修改前先理解上下文，遵循现有代码风格
- 完成后必须运行 lint 和 typecheck 验证
- 提交前必须运行测试

## 常用命令
- 前端项目：`pnpm lint && pnpm test`
- Python项目：`ruff check . && pytest`
- Git提交：`feat: / fix: / refactor:` 前缀
- 类型检查：`pnpm typecheck` 或 `tsc --noEmit`

## API 配置
- API Key 存储在 ~/.claude/settings.json
- 切换模型: /model <model-name>
- 切换API: 运行 scripts/setup_api.ps1
- 推荐模型: doubao-seed-code-preview-latest (豆包编程)

## MCP 服务器
- Context7: 实时文档检索，防止幻觉
- Sequential Thinking: 结构化推理，减少错误
- Fetch: 网页抓取
- Memory: 跨会话持久化记忆

## Superpowers 命令
- /brainstorm - 头脑风暴，探索需求
- /write-plan - 创建实现计划
- /execute-plan - 执行计划

## 项目记忆
- 火山方舟 Coding Plan 用户
- 优先使用 Server Components (Next.js)
- 图片使用 next/image 优化
- 样式使用 Tailwind CSS
