# iOS Life Assistant - 生活助手

一个集成记账、待办事项、AI 识图、面试/会议汇总的 iOS 生活助手应用。

## 📱 功能特性

### 💰 记账模块
- 收入/支出记录
- 10+ 分类管理（餐饮、交通、购物等）
- 月度/年度统计图表
- iCloud 云端同步

### ✅ 待办事项
- 任务创建、编辑、完成
- 优先级设置（高/中/低）
- 截止日期提醒
- **与 iOS Reminders 系统同步**
- 进度条可视化

### 🤖 AI 识图
- 快捷指令唤起
- Vision OCR 本地识别
- OpenAI API 智能分析
- 自动分类：记账 vs 待办
- 历史记录管理

### 💼 面试汇总
- 公司/职位信息管理
- 状态追踪（投递→笔试→面试→Offer）
- 按 DDL 排序
- Offer 率统计

### 📅 会议/期刊汇总
- 学术会议追踪
- 期刊投稿截止提醒
- AI/ML/CV/NLP 等分类筛选
- 网站链接直达

---

## 🚀 快速开始

### 环境要求
- **macOS 14.0+**
- **Xcode 15.0+**
- **iOS 17.0+** (目标设备)
- **Apple Developer Account** (可选，用于真机测试)

### 1. 克隆代码

```bash
git clone https://github.com/yourusername/ios-life-assistant.git
cd ios-life-assistant
```

### 2. 打开项目

```bash
open LifeAssistant.xcodeproj
```

或者用 Xcode 打开 `LifeAssistant.xcodeproj` 文件。

### 3. 配置签名 (真机测试)

1. 在 Xcode 左侧选择项目根目录
2. 选择 TARGETS → LifeAssistant
3. 切换到 **Signing & Capabilities** 标签
4. 勾选 **Automatically manage signing**
5. 选择你的 Team (Apple ID)

### 4. 运行项目

**模拟器运行：**
1. 在 Xcode 顶部工具栏选择 iPhone 15 Pro (或任意 iOS 17+ 模拟器)
2. 点击 ▶️ Run 按钮 (Cmd + R)

**真机运行：**
1. 用数据线连接 iPhone
2. 在 Xcode 顶部选择你的设备
3. 点击 ▶️ Run 按钮
4. 首次运行需要在 iPhone 上信任开发者证书

---

## ⚙️ 配置说明

### CloudKit / iCloud 同步

1. 登录 [Apple Developer Portal](https://developer.apple.com)
2. 进入 Certificates, Identifiers & Profiles
3. 找到 App ID `com.yourname.LifeAssistant`
4. 确保勾选 **iCloud** 和 **CloudKit**
5. 在 Xcode 中重新下载配置文件

### Siri 快捷指令

1. 打开 iPhone 设置 → Siri 与搜索
2. 找到 "LifeAssistant"
3. 开启 "使用 App 时学习" 和 "建议快捷指令"
4. 在快捷指令 App 中添加自定义指令

### AI 识图 API 配置 (可选)

如需使用 OpenAI 增强识别：

1. 复制 `Config/APIConfig.template.swift` 为 `APIConfig.swift`
2. 填入你的 OpenAI API Key:

```swift
struct APIConfig {
    static let openAIKey = "your-api-key-here"
}
```

> ⚠️ 不要将包含真实 API Key 的文件提交到 Git！

---

## 📁 项目结构

```
LifeAssistant/
├── App/
│   ├── LifeAssistantApp.swift      # 应用入口
│   └── PersistenceController.swift # Core Data + CloudKit
├── Views/
│   ├── ContentView.swift           # 主 Tab 导航
│   ├── Account/                    # 💰 记账模块
│   ├── Todo/                       # ✅ 待办模块
│   ├── AI/                         # 🤖 AI识图
│   ├── Interview/                  # 💼 面试模块
│   ├── Conference/                 # 📅 会议模块
│   └── Components/                 # 共享UI组件
├── Services/                       # 业务逻辑层
├── Models/                         # 数据模型
├── Intents/                        # Siri 快捷指令
└── Resources/                      # 资源文件
```

---

## 🛠️ 开发指南

### 技术栈
- **SwiftUI** - UI 框架
- **Core Data** - 本地数据持久化
- **CloudKit** - iCloud 云端同步
- **EventKit** - 系统提醒同步
- **Vision** - 本地 OCR 识别
- **SiriKit** - 快捷指令支持

### 添加新功能

1. **数据模型**: 在 `Models/` 定义 struct 和 enum
2. **Core Data**: 在 `.xcdatamodeld` 添加 Entity
3. **Service 层**: 在 `Services/` 实现 CRUD
4. **UI 层**: 在 `Views/` 创建 SwiftUI View

### 调试技巧

```swift
// 查看 Core Data 数据
let request: NSFetchRequest<AccountRecordEntity> = AccountRecordEntity.fetchRequest()
let records = try? context.fetch(request)
print("Records count: \(records?.count ?? 0)")

// 检查 CloudKit 同步状态
NotificationCenter.default.addObserver(
    forName: NSPersistentStoreRemoteChangeNotification,
    object: nil,
    queue: .main
) { _ in
    print("CloudKit sync completed")
}
```

---

## 🐛 常见问题

### Q: 编译报错 "No such module 'Charts'"
A: Charts 是 iOS 17+ 内置框架，确保 Deployment Target ≥ 17.0

### Q: iCloud 同步不生效
A: 
1. 检查 Apple ID 是否登录
2. 确认 iCloud Drive 已开启
3. 等待几分钟（首次同步较慢）

### Q: 真机安装失败
A:
1. 检查设备 iOS 版本 ≥ 17.0
2. 确认已信任开发者证书
3. 清理 Build Folder (Cmd + Shift + K)

### Q: Siri 快捷指令无法使用
A:
1. 确保已在设置中开启权限
2. 重新录制语音指令
3. 检查 IntentHandler 是否正确配置

---

## 📸 截图预览

| 记账 | 待办 | AI识图 |
|:---:|:---:|:---:|
| ![Account](Screenshots/account.png) | ![Todo](Screenshots/todo.png) | ![AI](Screenshots/ai.png) |

| 面试 | 会议 |
|:---:|:---:|
| ![Interview](Screenshots/interview.png) | ![Conference](Screenshots/conference.png) |

---

## 📝 更新日志

### v1.0.0 (2026-03-09)
- ✅ 初始版本发布
- ✅ 完整 5 大功能模块
- ✅ CloudKit 同步
- ✅ Siri 快捷指令

---

## 👨‍💻 作者

Created by 孙哥

---

## 📄 License

MIT License - 自由使用和修改
