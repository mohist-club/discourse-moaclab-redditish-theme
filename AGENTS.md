# discourse-moaclab-redditish-theme

moaclab.com 的默认主题（线上主题 276），基于官方 `discourse-redditish-theme` 修改。它是全站每个页面都会加载的代码，改动影响面最大。

站点级的发布流程、线上 ID 和已安装组件清单在私有维护仓库 `mohist-club/Moaclab`（`ops/release.md`、`components/README.md`）。本文件只写这个仓库内的开发约定。

## 目录

| 路径 | 内容 |
| --- | --- |
| `about.json` | 元数据、资源、依赖组件（Full Width、Header Search） |
| `settings.yml` | 主题设置 |
| `migrations/settings/` | 设置迁移，已合并的迁移不再修改 |
| `common/`、`mobile/`、`scss/` | 样式，`scss/` 按页面区域分文件 |
| `javascripts/discourse/` | `api-initializers/`、`components/`、`connectors/`、`services/` |
| `locales/` | `en` 与 `zh_CN` 文案 |
| `spec/system/` | 系统测试（在真实 Discourse 上跑浏览器） |
| `test/` | 前端验收测试和设置迁移测试 |

## 约定

- **组件用 `.gjs`**（Glimmer），通过 plugin outlet 和 `api.*` 扩展界面，不覆盖核心模板。
- **保留原生交互**：导航、筛选、通知、收藏等用 Discourse 原生组件，主题只改外观和布局。
- **样式**：颜色用 CSS 变量和 `common/color_definitions.scss` 里的定义，浅色和深色都要检查。
- **文案**：界面文字放 `locales/`，`en` 与 `zh_CN` 同步更新。README 更新记录和提交信息沿用中英双语。
- **设置变更**：改名或改结构时在 `migrations/settings/` 新增迁移并补测试，不改已有迁移。
- **系统测试的前提要写明**：测试依赖的站点设置在 `before` 里显式设置，不依赖核心默认值。核心默认值会变，moaclab.com 的设置也和默认值不同。
- 不新增依赖和外部 CDN 资源，确有需要先问。

## 检查

使用 Node.js 22 或更新版本，pnpm 版本以 `package.json` 的 `packageManager` 为准：

```sh
pnpm install --frozen-lockfile
pnpm lint
node --test test/homepage-gb-migration.test.mjs
```

系统测试和前端验收测试需要 Discourse 环境，由 CI（`.github/workflows/discourse-theme.yml`）在最新 Discourse 上运行。PR 的 Actions 必须全绿才能合并；出现失败先判断是本次改动引起的还是核心更新引起的，两种情况都要在合并前处理，不带红合并。

## 版本与发布

1. 从 `main` 开分支，一个分支只做一件事。
2. 影响线上表现的改动，同步更新 `about.json` 的 `theme_version` 和 `README.md` 顶部的版本号与更新记录。只改测试、CI 或文档时不改版本号。
3. 推分支，开指向 `main` 的 PR，附桌面和手机宽度的预览截图。合并由仓库所有者完成，合并后删除分支。
4. 发版后打 `vX.Y.Z` tag。
5. 更新到网站按维护仓库的 `ops/release.md`「主题和组件」一节执行：先在预览主题上验证，再更新主题 276。

## 不要做

- 不直接推 `main`，不强制推送。
- 不提交密钥或站点数据。
- 更新线上主题属于生产操作，需要仓库所有者在当前对话里明确批准。
- 不做任务范围以外的重构。
