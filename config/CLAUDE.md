# 全局配置

> Claude Code 全局规则。所有项目自动继承此配置。

---

## 一、文件操作

### 1.1 安全删除（重要）

- **禁止**使用 `rm` 或 `rm -rf` 命令删除文件
- **必须**使用 `mv` 命令将文件移至 `.trash/` 目录
- 示例：`mv 待删文件 .trash/`

**正确做法：**
```bash
mv old_file.py .trash/
mv deprecated/ .trash/
```

**错误做法：**
```bash
rm old_file.py      # ❌ 禁止
rm -rf deprecated/  # ❌ 禁止
```

### 1.2 禁止创建重复文件

- **绝对禁止**创建 `v1`、`v2`、`backup`、`old`、`new`、`最终版` 等重复文件
- **禁止**带版本号后缀（`_v1`、`_v2`、`_backup`、`_bak`）
- 需要修改文件时，**直接在原文件上修改**
- 如果文件太大需要重构，先移至 `.trash/`，然后重写原文件

### 1.3 敏感文件

- **禁止**将密码、密钥、Token 提交到 Git
- 使用环境变量或 `.env` 文件

---

## 二、编码规范

- 变量声明：必须用 `let` 或 `const`，禁止用 `var`
- 函数命名：camelCase，动词开头
- 组件命名：PascalCase
- 文件命名：snake_case（Python），kebab-case（前端）
- 所有函数必须有类型标注（TypeScript）或中文注释（Python）

---

## 三、禁止行为

- NEVER 直接修改 node_modules
- NEVER 提交密码、密钥、Token到Git
- NEVER 创建v1、v2、backup等重复文件
- NEVER 使用 rm 命令删除文件，用 mv 移至 .trash/
- NEVER 在没有测试的情况下提交代码

---

## 四、工作流

- 使用 Superpowers Skills 进行结构化开发
- 复杂需求先 brainstorming，再 writing-plans，最后执行
- 代码修改前先理解上下文，遵循现有代码风格
- 完成后必须运行 lint 和 typecheck 验证
- 提交前必须运行测试

---

## 五、常用命令

- 前端项目：`pnpm lint && pnpm test`
- Python项目：`ruff check . && pytest`
- Git提交：`feat: / fix: / refactor:` 前缀
- 类型检查：`pnpm typecheck` 或 `tsc --noEmit`
- 安全删除：`mv 文件 .trash/`

---

## 六、Superpowers 命令

- `/brainstorm` - 头脑风暴，探索需求
- `/write-plan` - 创建实现计划
- `/execute-plan` - 执行计划

---

## 七、项目记忆

- 火山方舟 Coding Plan 用户
- API Key 配置在 ~/.claude/settings.json
- 切换模型: `/model <model-name>`
- 切换API: 运行 `setup_api.ps1`
