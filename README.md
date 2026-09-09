# Moaclab Redditish

Moaclab 的 Discourse Reddit 风格主题，基于官方 `discourse-redditish-theme` 创建。

## 安装

在 Discourse 后台打开：

**管理 → 自定义 → 主题 → 安装 → 从 Git 仓库安装**

使用仓库地址：

```text
https://github.com/mohist-club/discourse-moaclab-redditish-theme.git
```

## 来源

- Upstream: https://github.com/discourse/discourse-redditish-theme
- Meta topic: https://meta.discourse.org/t/-/269466

版本：`1.3.1`

## 1.3.1

- 顶部原生菜单固定为 56px 高度，保留占位，滚动时不遮挡首屏内容。
- 桌面侧栏宽度 272px，恢复 1px 右侧分隔线，保留原生整栏收起和分组折叠。
- 导航行高 40px、字体 14px / 20px、图标 20px、图文间距 12px、水平内边距 16px。
- 上述为本主题明确固定的尺寸；Reddit 实时页面受验证限制，未声明全像素一致。

## 1.3.0

- 页眉工具使用圆形悬停、展开状态；搜索框支持聚焦反馈。
- 左侧导航采用整行点击区域、选中色块、右侧分组箭头，保留原生折叠与更多菜单。
- 移除帖子分割线、图片描边和侧栏分隔线，改用浅色背景与留白。
- 提供键盘焦点与减少动态效果偏好支持。

## 1.2.0

- 使用随主题托管的 Reddit Sans 可变字体和独立的浅色、深色视觉配色。
- 统一三栏布局、顶部搜索、导航、侧栏与信息流；保留原生交互。
- 原生页眉搜索可见时隐藏重复的欢迎搜索区。
- 16px 图片与悬停圆角，18px 标题，24px 头像，32px 操作按钮。
- 图片根据原始宽高比显示，控制极端比例；分享按钮使用轻量线框箭头。

字体：[Reddit Sans](https://github.com/reddit/redditsans)，SIL Open Font License。
图标：[Lucide](https://github.com/lucide-icons/lucide)，ISC License。
许可证随资源保留在 `assets/`。

## 1.1.0

- 756px 自适应内容流，白底、细分割线和浅色悬停背景。
- 头像和用户名，紧凑标题间距；图片完整显示，文字帖保留三行摘要。
- 线框图标、点赞数量、评论链接和原生分享弹窗。
- 调整右侧栏密度；保留主题原有搜索和配色方案适配。
