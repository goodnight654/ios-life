# iOS Life Assistant - 快速上手指南

## 🎯 目标：5分钟内在你的 Mac 上运行起来

---

## Step 1: 下载代码

打开 Terminal（终端），执行：

```bash
# 进入你想存放项目的目录
cd ~/Documents

# 克隆代码（替换为你的实际仓库地址）
git clone https://github.com/yourusername/ios-life-assistant.git

# 进入项目目录
cd ios-life-assistant
```

---

## Step 2: 用 Xcode 打开

**方法一：命令行**
```bash
open LifeAssistant.xcodeproj
```

**方法二：Finder**
1. 打开 Finder
2. 进入 `~/Documents/ios-life-assistant`
3. 双击 `LifeAssistant.xcodeproj`

---

## Step 3: 选择运行目标

在 Xcode 顶部工具栏：

```
[LifeAssistant > iPhone 15 Pro] ▶️
```

点击 `iPhone 15 Pro` 可以选择：
- **模拟器**: iPhone 15 Pro / iPhone 14 / iPad 等
- **真机**: 你的 iPhone (需要连接数据线)

---

## Step 4: 运行！

点击 ▶️ 按钮，或按 `Cmd + R`

等待编译完成（首次可能需要 1-2 分钟），然后模拟器会自动启动并显示 App。

---

## 🔧 真机测试额外步骤

如果想在自己的 iPhone 上运行：

### 1. 连接 iPhone
用数据线连接 Mac 和 iPhone

### 2. 配置签名
1. 在 Xcode 左侧点击最顶部的 `LifeAssistant`
2. 中间选择 `TARGETS` → `LifeAssistant`
3. 右侧切换到 `Signing & Capabilities`
4. 勾选 `Automatically manage signing`
5. Team 选择你的 Apple ID

### 3. 信任证书
首次运行时 iPhone 会提示：
> "不受信任的开发者"

去 iPhone 设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID

### 4. 再次运行
回到 Xcode 点击 ▶️

---

## ✅ 验证功能

App 启动后，你应该看到底部有 5 个 Tab：

1. **记账** 💰 - 点击右上角 + 添加一笔记录
2. **待办** ✅ - 添加任务，查看进度条
3. **AI识图** 🤖 - 拍照或选图识别
4. **面试** 💼 - 添加面试信息
5. **会议** 📅 - 添加学术会议

---

## 🐛 遇到问题？

### 报错："No such module 'Charts'"
**解决**: Charts 是 iOS 17+ 内置框架，检查 Deployment Target
1. 点击项目 → LifeAssistant → General
2. 找到 `Minimum Deployments` → iOS
3. 确保 ≥ 17.0

### 报错："Failed to code sign"
**解决**: 
1. 检查是否登录了 Apple ID (Xcode → Preferences → Accounts)
2. 重新选择 Team
3. Clean Build Folder (Cmd + Shift + K)，再运行

### 数据不同步到 iCloud
**解决**:
1. 确保 Mac/iPhone 登录了同一个 Apple ID
2. 设置 → Apple ID → iCloud → iCloud Drive 开启
3. 等待几分钟（首次同步较慢）

---

## 📚 下一步

- 阅读完整文档：[README.md](README.md)
- 自定义功能：修改 `Views/` 目录下的 SwiftUI 文件
- 添加新模块：参考现有代码结构

---

**🎉 恭喜！你现在拥有了自己的 iOS 生活助手 App！**
