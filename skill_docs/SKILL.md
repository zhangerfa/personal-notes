---
name: personal-notes
description: 记录用户的想法、观点和思考，同步到内网 Codebase 和 GitHub 两个仓库。触发词：记下来、补充笔记、加到笔记、笔记：。
---

# Personal Notes Skill

## 功能

记录用户的想法、观点、哲学思考，动态推断笔记仓库路径并写入对应文件。

## 触发条件

当用户发送以下内容时使用此 skill：
- 明确说"补充笔记"、"记下来"、"加到笔记"
- 消息以"笔记："开头
- 发送一段个人观点、想法、哲学思考，并期望被整理记录

## 全局索引与双段式加载

- 在笔记仓库根目录下必须维护一个全局索引文件 `INDEX.md`。
- **`INDEX.md` 的结构**：按文件夹和文件层级，记录所有笔记文件的路径，以及该文件包含的核心条目清单（目录/摘要词）。
- **双段式加载与查重逻辑**：
  1. **第一阶段（轻量检索）**：接收新笔记后，Agent **仅读取** `INDEX.md`，判断新内容可能所属的分类 or 文件路径。
  2. **第二阶段（深度比对）**：锁定潜在目标文件后，定向读取该具体文件的完整内容，进行深度语义比对（判断是追加还是合并修改）。

## 索引缺失的处理逻辑

- 如果发现 `INDEX.md` 不存在或已失效，必须先触发一次全局扫描（遍历仓库下的所有 `.md` 文件），重新生成 `INDEX.md`，然后再处理用户的新笔记。

## 核心规则

### 1. 双仓库架构

笔记同时存储于两个远端，内容必须保持一致：

| 远端名 | URL | 用途 |
|--------|-----|------|
| `codebase` | `https://code.byted.org/zhangbo.int/note` | 主远端（内网） |
| `github` | `https://github.com/zhangerfa/personal-notes` | 备远端（外网） |

每次执行前通过 `git remote -v` 确认远端配置正确。若远端未配置，执行：
```bash
git remote add codebase https://code.byted.org/zhangbo.int/note
git remote add github https://github.com/zhangerfa/personal-notes
```

### 2. 写入与双推送流程

每次更新笔记，必须遵循以下"写入-提交-双推"的流程：

1.  **自动创建分支**：`git checkout -b note-update-$(date +%Y%m%d%H%M%S)`
2.  **本地写入**：将新内容写入对应的笔记文件并更新 `INDEX.md`。
3.  **提交改动**：`git add . && git commit -m "feat: add/update note"`
4.  **推送到主远端**：`git push -u codebase <新分支名>`
5.  **推送到备远端**：`git push github <新分支名>`
6.  **反馈链接**：
    - Codebase MR：`https://code.byted.org/zhangbo.int/note/merge_requests/new?source_branch=<新分支名>`
    - GitHub PR：`https://github.com/zhangerfa/personal-notes/pull/new/<新分支名>`

### 3. main 分支双向同步

当 main 分支有新合并后，或需要手动同步时，执行以下命令保持两端一致：

```bash
git fetch codebase && git fetch github
git checkout main && git merge codebase/main
git push github main
```

**特别说明**：
- **严禁**在对话框中打印长篇 Git Diff 并阻塞等待用户确认。
- **必须**同步更新 `INDEX.md`。
- 每次写入笔记后，**必须**同时推送到两个远端。

### 4. 无关键词
整理后的笔记不添加"关键词"标签。

## 笔记路径与环境适配

Agent 必须具备动态推断笔记仓库物理路径的能力，严禁将路径死锁为 `./memory/notes`。路径推断逻辑应遵循以下简单原则：

1. **云端沙盒环境**：若判断当前处于 Aime 云端沙盒（如存在 `WORKSPACE_ID`），默认使用 `./memory/notes`。
2. **本地物理机环境**：若在用户个人电脑运行，默认回退至家目录下的 `~/memory/notes`。

## 笔记文件

- **默认根目录**：根据上述逻辑动态确定的笔记仓库路径。
- **默认主文件**：`<笔记根目录>/personal-notes.md`（或根据分类自动选择/创建文件）。
- **自动处理**：如果目录或文件不存在，应自动创建。新文件初始内容为 `# Personal Notes`。

## 格式规范

每条笔记作为独立的二级标题（`## 标题`），标题下注明日期（`> YYYY-MM-DD`），内容适当整理排版，保持简洁清晰格式。

## 去重规则

- **语义合并**：写入前扫描已有笔记，如果存在语义高度相似的条目，不新建条目，而是将新内容合并到已有条目下，允许删改已有笔记。

## 分类与检索

- **主题分组**：当笔记条目超过 20 条时，自动按主题分组，使用文件夹分类，并在对应文件内使用一级标题（#）作为分类，二级标题（##）作为具体笔记。分类示例：`# 技术思考`、`# 人生哲学`、`# 工作反思`。
- **目录索引 (TOC)**：在每个文件顶部维护一个目录索引，格式为 `- [标题](#锚点)`，方便快速跳转。
- **分类逻辑**：由 skill 根据内容语义自动判断分类，用户也可以指定。

## 文件分片

- **上限限制**：单文件上限 500 条笔记或 50KB（以先到者为准）。
- **自动分片**：达到上限后自动按语义拆分为多个文件或文件夹。
