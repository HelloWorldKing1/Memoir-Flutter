# Memoir Flutter 多端互通版 (AI 开发指南)

## 项目概述
Memoir 是一款轻量级多场景个人记录工具，覆盖灵感碎片、个人感悟、日记、学习总结、长文创作等场景。本版本为 Flutter 多端互通版，支持 iOS / Android / Web / 桌面端。后端采用自托管的 **PocketBase**，数据离线优先，多端实时同步。

## 技术栈速查
| 类别 | 技术 | 用途 |
|------|------|------|
| 跨平台 | Flutter 3.44.1 (Dart 3.12.1) | UI 及多端适配 |
| 状态管理 | flutter_riverpod 3.3+ / riverpod_annotation 4.0+ | 全局/局部状态、依赖注入 |
| 后端 | PocketBase 0.24+ | 认证、数据库、实时推送、文件存储 |
| 本地存储 | Hive 2.2+ / hive_flutter 1.1+ | 离线缓存、草稿、同步队列 |
| 安全存储 | flutter_secure_storage 10.3+ | Token 持久化、敏感数据 |
| 网络 | pocketbase SDK + WebSocket 实时订阅 | API 调用、实时推送 |
| Markdown | flutter_markdown + markdown_toolbar | 编辑与预览 |
| 图表 | fl_chart 1.2+ | 统计可视化（柱状图、热力图） |
| 路由 | go_router 17.3+ | 声明式路由、页面过渡 |
| 工具 | connectivity_plus, image_picker, share_plus, path_provider | 网络检测、图片选择、导出、文件路径 |

## 项目结构
```shell
lib/
├── core/                         # 基础能力（跨模块共享的底层设施）
│   ├── di/                       # Provider 全局配置、依赖注入初始化
│   ├── pocketbase/               # PocketBase 客户端单例、认证拦截器
│   ├── sync/                     # 离线队列、同步引擎、冲突解决
│   ├── network/                  # 网络状态监听、连通性检查
│   ├── constants/                # 常量、枚举、动画参数
│   ├── themes/                   # 亮色/暗色主题定义
│   ├── routes/                   # 路由常量、类型安全路由定义
│   ├── extensions/               # Dart 扩展方法（String、DateTime 等）
│   └── utils/                    # 纯工具函数（格式化、校验）
├── data/                         # 数据层
│   ├── local/                    # Hive 适配器、本地数据源实现
│   ├── remote/                   # PocketBase API 调用、DTO 映射
│   ├── repositories/             # 仓库接口（抽象），实现在 local/remote
│   └── models/                   # 数据实体（Diary、User、Mood 等）
├── domain/                       # 业务用例（离线优先的核心策略在此编码）
│   ├── usecases/                 # 如 SyncPendingChanges、ResolveConflict
│   └── entities/                 # 纯领域实体（可选，小项目可复用 data/models）
├── features/                     # 功能模块
│   ├── auth/                     # 登录/注册/Token 管理
│   ├── diary/                    # 日记列表、详情、编辑器
│   ├── search/                   # 全文搜索、标签/心情筛选
│   ├── statistics/               # 统计图表、标签云、热力图
│   ├── settings/                 # 设置、导入导出、主题切换
│   └── shared/                   # 通用 UI 组件（侧边栏、响应式布局、动画）
├── l10n/                         # 国际化（可选）
└── main.dart
```

### 分层架构约定

**Repository 模式** —— 接口与实现分离：
- `data/repositories/` 只放 **抽象接口**（如 `abstract class DiaryRepository`）
- `data/local/` 放 **Hive 实现**（如 `DiaryLocalRepository implements DiaryRepository`）
- `data/remote/` 放 **PocketBase 实现**（如 `DiaryRemoteRepository implements DiaryRepository`）
- 调用方通过 Riverpod Provider 注入，不直接依赖具体实现

**Provider 组织** —— 按层级归类：
- `core/di/` — 全局单例 Provider（PocketBase 客户端、同步服务、Hive 初始化）
- `data/repositories/` — 仓库 Provider（对外暴露接口，内部选择 local/remote）
- 各 `features/` 内部 — 页面级、组件级 Provider（只作用于本模块）

**Domain 层职责**（非可选）：
- 封装「离线优先」的核心策略：何时读缓存、何时调网络、冲突如何解决
- 每个 UseCase 是一个可测试的独立类，注入 Repository 接口
- 小项目可复用 `data/models` 作为领域实体，后续如有需要再独立
## 关键实现模式

### 离线优先 + 同步队列

**写操作流程**：
1. 更新本地 Hive（乐观更新，UI 立即响应）
2. 将操作加入 `PendingQueue`（Hive 存储），记录操作类型（create/update/delete）、时间戳、完整数据快照
3. 触发同步服务（网络可用时立即尝试；不可用时静默等待 `connectivity_plus` 通知）

**同步状态机** —— 队列中每项具备以下状态：
- `pending` → 等待同步
- `syncing` → 正在请求 PocketBase API
- `synced` → 成功，从队列移除
- `failed` → 失败，记录重试次数，指数退避（1s → 2s → 4s → 8s → max 60s）

**删除策略**：
- 采用 **软删除**：本地模型设 `isDeleted = true`，同步到服务端后执行真正的 API 删除
- 避免硬删除后离线设备仍持有旧数据导致复活

**首次启动**（冷启动/重新安装）：
- 从 PocketBase 拉取全部数据覆盖本地 Hive（全量同步）
- 后续使用 WebSocket 订阅增量更新

**读取策略**：
- 优先从 Hive 读取（即时展示）
- 同时订阅 PocketBase 实时变更（WebSocket）
- 若数据不一致：对比 `updated` 字段，采用最新版本（Last-Write-Wins）

### PocketBase 集成

**客户端初始化**：
- 单例 `PocketBase` 实例，通过 Riverpod `Provider` 全局注入
- 使用 `AsyncAuthStore` 持久化 token 到 `flutter_secure_storage`
- 在 `main.dart` 的 `WidgetsFlutterBinding.ensureInitialized()` 之后完成初始化

**API 调用示例**：
- 认证：`pb.collection('users').authWithPassword(email, password)`
- CRUD：`pb.collection('diaries').getList(page: 1, perPage: 20, filter: 'user = "$userId"')`
- 实时订阅：`pb.collection('diaries').subscribe('*', callback, filter: 'user = "$userId"')`
- 文件上传：`pb.collection('diaries').update(id, body: {'pictures': MultipartFile.fromPath(...)})`

### 认证架构

**认证方式**：Email + 密码（PocketBase 内置 `users` 集合），后续可扩展 OAuth2（Google / Apple / GitHub）

**Auth 状态管理**：
- `AuthNotifier`（`NotifierProvider`）持有当前用户状态（`User?`）
- 登录成功 → 更新 `AuthNotifier` → `go_router` 的 `redirect` 自动跳转到首页
- Token 过期 → `AsyncAuthStore` 自动尝试刷新；刷新失败 → 清空状态跳转登录页
- 登出 → 清空 `flutter_secure_storage` 中的 token → 重置所有 Hive 数据（可选）

**路由守卫**：
- `go_router` 的 `redirect` 回调检查 `AuthNotifier` 状态
- 未认证 → 重定向到 `/login`
- 已认证访问 `/login` → 重定向到 `/`

### 状态管理（Riverpod）

**Provider 类型选择**：
- `NotifierProvider` / `AsyncNotifierProvider` — 复杂状态（日记列表含筛选、同步队列、Auth 状态）→ Riverpod 3.x 推荐
- `FutureProvider` / `StreamProvider` — 异步数据（统计聚合、实时订阅）
- `Provider` — 全局单例（PocketBase 客户端、同步服务、Hive boxes）
- 代码生成：`riverpod_annotation` + `build_runner` 可自动生成 provider 代码

**Provider 组织约定**：
- `core/di/providers.dart` — 全局基础设施 Provider（PocketBase、Hive、SyncService）
- `data/repositories/providers.dart` — 仓库 Provider（对外暴露接口，隐藏 local/remote 切换）
- `features/<module>/providers/` — 模块级 Provider（页面状态、表单状态）
- 命名：Repository Provider 用 `xxxRepositoryProvider`，状态 Provider 用 `xxxProvider`

### 响应式布局
- 使用 `LayoutBuilder` 判断屏幕宽度：
  - `>= 1200`：桌面三栏（左侧边栏 + 主内容 + 右侧边栏）
  - `600 ~ 1199`：平板（侧边栏可折叠）
  - `< 600`：移动（底部导航栏 + FAB）

### 动画规范
- 卡片入场：`AnimatedContainer` + `Curves.easeOutBack`
- 按钮反馈：`GestureDetector` + `ScaleTransition`
- 心情选择：`AnimatedContainer` + 弹跳曲线
- 路由过渡：`go_router` 的 `CustomTransitionPage` 实现左右滑动或淡入淡出

### 错误处理策略

**分层处理原则** —— 错误在恰当的层级被捕获和转换：

| 层 | 处理方式 | 示例 |
|----|---------|------|
| Remote / Local | `try-catch` 捕获，转为 `Result<T>` 或抛出领域异常 | `NetworkException`、`AuthException`、`NotFoundException` |
| Repository | 汇总 local + remote 的错误，决定降级策略 | 网络不可用 → 返回本地缓存 + 提示用户 |
| Notifier | 将错误映射为用户可读消息，更新 UI 状态 | `state = AsyncValue.error('无法连接服务器')` |
| UI | 通过 `AsyncValue.error` 展示 SnackBar / 重试按钮 / 空状态 | `snackBar + retry action` |

**降级优先级**：
1. 有网络 → 使用远程数据，同步本地
2. 无网络 → 使用本地 Hive 缓存，界面顶部显示「离线模式」横幅
3. 本地也无数据 → 展示 Empty State，引导用户联网后重试

## 编码规范
- **命名**：文件 `snake_case`，类 `PascalCase`，变量/方法 `camelCase`，常量 `kCamelCase` 或 `SCREAMING_SNAKE_CASE`
- **格式化**：`dart format .`，`flutter analyze`
- **注释**：公开 API 需添加 `///` 文档注释，复杂逻辑添加行内注释
- **错误处理**：使用 `try-catch` 并记录日志，避免静默失败
- **测试**：核心逻辑（同步、冲突解决）需编写单元测试，UI 层可选择性 Widget 测试

## 常用命令
```bash
flutter pub get                        # 获取依赖
flutter run -d <device-id>             # 运行（指定设备）
flutter run -d chrome                  # 运行 Web 版本
flutter test                           # 运行测试
flutter analyze                        # 代码分析
dart format .                          # 格式化代码

# 构建生产版本
flutter build apk --release            # Android APK
flutter build appbundle --release      # Android AAB
flutter build ios --release            # iOS（需 macOS）
flutter build web --release            # Web
flutter build windows --release        # Windows
flutter build macos --release          # macOS
flutter build linux --release          # Linux
```



## PocketBase 数据模型

### 集合 `users`（PocketBase 内置，扩展字段）

| 字段     | 类型   | 规则      | 说明                 |
| -------- | ------ | --------- | -------------------- |
| name     | String | 可选      | 显示名称             |
| avatar   | File   | 可选      | 头像                 |

> PocketBase 内置 `email`、`password`、`emailVisibility`、`verified` 字段，无需手动创建。`users` 集合的 API 规则保持默认（仅本人可读写）。

### 集合 `diaries`

| 字段      | 类型             | 规则                         |
| --------- | ---------------- | ---------------------------- |
| title     | String           | 必填，max 200                |
| content   | Text             | 必填                         |
| entryType | Select           | inspiration/reflection/diary/summary/article |
| mood      | Select           | happy/neutral/sad/angry/love |
| weather   | Select (可选)    | sunny/cloudy/rainy           |
| tags      | JSON             | 字符串数组                   |
| pictures  | File (多文件)    | 存储于 `diary_pictures`      |
| user      | Relation (users) | 创建时自动设为当前用户       |
| isDeleted | Bool             | 默认 false，软删除标记       |
| updated   | DateTime (自动)  | PocketBase 自动管理          |

### 安全规则（API 规则）

```javascript
// 列表/查看
@request.auth.id = user.id
// 创建
@request.auth.id != "" && user = @request.auth.id
// 更新/删除
@request.auth.id = user.id
```

### Schema 迁移

- PocketBase 无内置 Migration。修改集合字段后，通过 Admin UI 或 `pb_migrations` 集合手动记录变更
- 客户端侧：新增字段使用 `??` 默认值兼容旧缓存数据；Hive 中模型字段变更时升级 `typeId` 或使用 `HiveAdapter` 转换



## 重要注意事项

1. **Web 平台兼容**：PocketBase 需在 Admin UI → Settings 中配置 CORS 允许来源；Hive 在 Web 下需调用 `Hive.initFlutter()`，注意 `path_provider` 在 Web 平台不可用。
2. **离线队列持久化**：待同步操作需存储完整数据（包括图片临时路径），同步时重新读取文件上传。操作按时间顺序 FIFO 执行。
3. **冲突解决**：默认 Last-Write-Wins（基于 `updated` 字段）。若需用户手动选择，捕获 PocketBase 400/409 响应后弹出差异对比对话框。
4. **分页性能**：日记列表使用 `ListView.builder` + PocketBase `page`/`perPage` 参数。初始加载 20 条，滚动到底部时加载下一页。
5. **安全底线**：生产环境必须启用 SSL（PocketBase 与客户端均 HTTPS）；PocketBase Admin UI 使用强密码，限制 IP 访问；`flutter_secure_storage` 存储 token 而非明文密码。
6. **图片处理**：`image_picker` 选取后先在本地 Hive 缓存缩略图（Base64，max 200px），原图仅在上传时读取，避免内存膨胀。
7. **测试重点**：同步引擎单元测试（队列增删、退避算法、冲突解决）为必须项；UI 层 Widget 测试按需覆盖；集成测试至少覆盖「登录 → 写日记 → 同步」完整链路。