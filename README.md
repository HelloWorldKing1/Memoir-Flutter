# Memoir ✨ (Flutter 多端互通版)

> 捕捉每一个念头，让灵感与感悟都有归处。  
> 多端同步 · 离线可用 · 数据自托管

Memoir 是一个轻量、敏捷的个人记录工具。你可以随手写下**灵感碎片、个人感悟、读书思考、代码顿悟、情绪日记、学习总结、长文创作**——任何值得记录的内容。  
本版本基于 **Flutter** 重构，支持 **iOS / Android / Web / 桌面端（Windows / macOS / Linux）**，数据存储在自托管的 **PocketBase** 后端，实现多设备实时同步，同时保持离线优先的流畅体验。

## ✨ 特性

- **🚀 多场景记录** — 灵感 💡 / 感悟 🤔 / 日记 📔 / 总结 📋 / 文章 📝，每种类型独立标识
- **🔄 多端同步** — 基于 PocketBase 实时推送，手机、电脑、网页端数据即时一致
- **📴 离线优先** — 本地 Hive 缓存，断网可用，恢复网络后自动同步
- **🔐 数据自托管** — 后端完全由你掌控（PocketBase），无厂商锁定
- **📤 数据可迁移** — 一键导出 JSON 备份，支持从备份恢复
- **✍️ 富文本编辑** — 所见即所得的 WYSIWYG 编辑器（基于 AppFlowy Editor），支持标题、列表、引用、代码块、分割线等块组件，Markdown 快捷键 / 斜杠命令 / 选区浮动工具栏三重交互
- **🏷️ 智能标签** — 自动补全已有标签，点击标签聚合内容
- **💾 自动保存** — 实时存入本地草稿，意外关闭不丢字
- **🌓 深色模式** — 亮色/暗色一键切换，深夜书写不刺眼
- **🔍 多维筛选** — 按类型、心情、标签、日期组合筛选
- **📅 日历热力图** — 月度视图，记录频率颜色深浅直观呈现
- **📊 统计面板** — 记录分布柱状图 + 标签云
- **🖱️ 鼠标光晕** — 桌面端跟随光标的柔和径向渐变（可选）

## 🛠 技术栈

| 层 | 技术 | 版本 |
|---|---|---|
| 客户端框架 | Flutter / Dart | 3.44.1 / 3.12.1 |
| 状态管理 | flutter_riverpod + riverpod_annotation | 3.3+ |
| 后端服务 | PocketBase（自托管，MIT 协议） | 0.24+ |
| 本地缓存 | Hive + hive_flutter | 2.2+ |
| 安全存储 | flutter_secure_storage | 10.3+ |
| 网络同步 | pocketbase SDK + WebSocket 实时订阅 | — |
| 路由 | go_router | 17.3+ |
| 图表 | fl_chart | 1.2+ |
| 富文本编辑器 | appflowy_editor | 6.2+ |
| Markdown 渲染 | flutter_markdown | 0.7+ |
| 网络检测 | connectivity_plus | 7.1+ |
| 图片选择 | image_picker | 1.2+ |
| 分享导出 | share_plus | 12.0+ |

## 🛠 未来规划
- 🖼️ 图片上传：编辑器内嵌图片插入、压缩、云端存储
- 📄 导出增强：PDF 导出、分享卡片生成
- 🤖 AI 集成：一键润色日记、AI 配图、对话式记录（口述经历 → AI 自动总结成文）
- 📝 协作编辑：多人实时协同（基于 CRDT）

## 📁 项目结构

```shell
memoir_flutter/
├── lib/
│   ├── core/                     # 基础能力
│   │   ├── pocketbase/           # PocketBase 客户端、认证、实时订阅
│   │   ├── sync/                 # 离线队列、同步引擎、冲突解决
│   │   ├── network/              # 网络状态监听
│   │   ├── constants/            # 常量、动画参数
│   │   ├── themes/               # 亮色/暗色主题
│   │   ├── routes/               # 路由定义
│   │   └── utils/                # 工具函数
│   ├── data/                     # 数据层
│   │   ├── local/                # Hive 本地存储
│   │   ├── remote/               # PocketBase API 封装
│   │   ├── repositories/         # 仓库接口与实现（离线优先）
│   │   └── models/               # Entry、Mood、EntryType 等实体
│   ├── domain/                   # 业务用例
│   ├── features/                 # 功能模块
│   │   ├── auth/                 # 登录/注册
│   │   ├── diary/                # 记录列表、详情、编辑器
│   │   ├── search/               # 全文搜索、标签/类型/心情筛选
│   │   ├── statistics/           # 统计图表、标签云、热力图
│   │   ├── settings/             # 设置、导入导出、主题切换
│   │   └── shared/               # 通用组件（侧边栏、响应式布局、动画）
│   ├── l10n/                     # 国际化（可选）
│   └── main.dart                 # 应用入口
├── assets/
│   ├── images/                   # 图片资源
│   └── fonts/                    # 字体资源
├── test/                         # 单元测试 & Widget 测试
├── android/                      # Android 平台工程
├── ios/                          # iOS 平台工程
├── web/                          # Web 平台工程
├── windows/                      # Windows 平台工程
├── macos/                        # macOS 平台工程
├── linux/                        # Linux 平台工程
├── pubspec.yaml                  # 依赖配置
├── analysis_options.yaml         # Lint 规则
├── CLAUDE.md                     # AI 开发指南（技术细节、编码规范）
└── README.md
```

## 🚀 快速开始

### 环境要求

- **Flutter SDK** ≥ 3.44（Dart ≥ 3.12）
- **PocketBase** 后端（Docker 或二进制部署）
- 可选：Docker（用于部署 PocketBase）

### 1. 部署 PocketBase 后端

#### 使用 Docker（推荐）

```bash
mkdir memoir-backend && cd memoir-backend
docker compose up -d
```

#### 直接运行二进制

```bash
# 从 https://pocketbase.io 下载对应系统的二进制文件
chmod +x pocketbase
./pocketbase serve --http=0.0.0.0:8090
```

#### 配置 PocketBase

1. 访问 `http://your-server-ip:8090/_/` 进入 Admin UI，创建管理员账户
2. 创建集合 `diaries`，字段参照 [CLAUDE.md](./CLAUDE.md) 中的数据模型
3. 设置 API 安全规则（确保用户只能访问自己的记录）

### 2. 运行 Flutter 客户端

```bash
git clone https://github.com/yourname/memoir-flutter.git
cd memoir-flutter
flutter pub get

# 配置后端地址（lib/core/constants/app_constants.dart）
# 运行
flutter run -d chrome     # Web
flutter run -d <device>   # 其他平台
```

### 3. 构建生产版本

```bash
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android AAB
flutter build ios --release          # iOS（需 macOS）
flutter build web --release          # Web
flutter build windows --release      # Windows
flutter build macos --release        # macOS
flutter build linux --release        # Linux
```

## 📦 部署 PocketBase（详细）

### Docker Compose 示例

```yaml
version: '3.8'

services:
  pocketbase:
    image: ghcr.io/pocketbase/pocketbase:latest
    container_name: pocketbase
    restart: always
    ports:
      - "8090:8090"
    volumes:
      - ./pb_data:/pb_data
      - ./pb_public:/pb_public
    command: serve --http=0.0.0.0:8090

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - pocketbase
    restart: always
```

### Nginx 反向代理配置（支持 WebSocket）

```nginx
server {
    listen 443 ssl http2;
    server_name memoir.yourdomain.com;

    ssl_certificate     /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    location / {
        proxy_pass http://pocketbase:8090;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 📄 数据导入 / 导出

- **导出**：在设置页面点击「导出数据」，生成包含所有记录的 JSON 文件，可保存到本地。
- **导入**：选择之前导出的 JSON 文件，系统会自动合并（基于 `updated` 时间戳去重，冲突时提示选择）。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request。  
开发前请阅读 [CLAUDE.md](./CLAUDE.md) 了解技术细节和编码规范。  

## 📜 开源协议

本项目采用 **MIT** 协议。  
PocketBase 本身遵循 MIT 协议，可自由使用和修改。

## 💬 常见问题

**Q: 必须自己部署后端吗？**  
A: 目前仅支持自托管，以保证数据隐私和自主权。

**Q: 离线编辑后，多端同步如何解决冲突？**  
A: 采用 Last-Write-Wins 策略（基于 `updated` 字段）。

**Q: 记录类型有什么区别？**  
A: 灵感（一闪而过的想法）、感悟（深度思考）、日记（日常生活）、总结（学习/工作复盘）、文章（长文创作）——只是分类标签，数据结构和功能完全一致。

**Q: Web 版本访问 PocketBase 出现 CORS 错误？**  
A: 请在 PocketBase Admin UI → Settings → 允许跨域来源中添加你的 Web 域名。

------

**Enjoy your memories, wherever you are.** 🎈
