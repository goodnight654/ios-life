# iOS Life Assistant - 项目计划

## 项目概述
一个集成记账、待办事项、AI 识图、面试/会议汇总的 iOS 生活助手应用

## 功能模块

### 1. 记账模块 💰
- 收入/支出记录
- 分类管理（餐饮、交通、购物等）
- 数据存储：Core Data + CloudKit (iCloud)
- 月度/年度统计图表

### 2. 待办事项模块 ✅
- 任务创建、编辑、完成
- 优先级设置
- 截止日期提醒
- 与 iOS Reminders 同步（EventKit）
- 进度条可视化

### 3. AI 识图模块 🤖
- 快捷指令集成（Siri Shortcuts）
- 截图识别功能
- AI 接口：调用 OpenAI Vision API 或本地 CoreML
- 自动分类：记账 vs 待办

### 4. 面试汇总模块 💼
- 面试信息录入（公司、岗位、DDL）
- 按 DDL 排序
- 美观的卡片式展示
- 状态追踪（投递→笔试→面试→offer）

### 5. 会议/期刊汇总模块 📅
- 学术会议信息录入
- 期刊截止日期追踪
- 按 DDL 排序
- 分类筛选（AI/ML/Sys等）

## 技术栈
- SwiftUI (UI)
- Core Data (本地存储)
- CloudKit (iCloud 同步)
- EventKit (系统待办同步)
- CoreML/Vision (AI 识别)
- SiriKit (快捷指令)

## 开发阶段

### Phase 1: 基础架构 (Day 1)
- [ ] Xcode 项目创建
- [ ] Core Data 模型设计
- [ ] CloudKit 配置
- [ ] TabView 导航框架

### Phase 2: 记账模块 (Day 1-2)
- [ ] 数据模型设计
- [ ] 记账界面
- [ ] 统计图表
- [ ] iCloud 同步测试

### Phase 3: 待办模块 (Day 2-3)
- [ ] 任务 CRUD
- [ ] 进度条组件
- [ ] EventKit 集成
- [ ] 提醒功能

### Phase 4: AI 识图 (Day 3-4)
- [ ] 快捷指令配置
- [ ] AI 接口集成
- [ ] 截图处理
- [ ] 自动分类逻辑

### Phase 5: 面试/会议模块 (Day 4-5)
- [ ] 面试管理界面
- [ ] 会议管理界面
- [ ] DDL 排序算法
- [ ] 美观的卡片设计

### Phase 6: 优化与测试 (Day 5-6)
- [ ] UI 美化
- [ ] 性能优化
- [ ] 真机测试
- [ ] Bug 修复

## 当前进度
- 项目启动: 2026-03-09 03:15
- 当前阶段: Phase 1 - 基础架构
- 状态: 🟡 进行中

## 文件结构
```
iOS-Life-Assistant/
├── LifeAssistant/
│   ├── App/
│   │   └── LifeAssistantApp.swift
│   ├── Models/
│   │   ├── AccountRecord.swift
│   │   ├── TodoItem.swift
│   │   ├── Interview.swift
│   │   └── Conference.swift
│   ├── Views/
│   │   ├── Account/
│   │   ├── Todo/
│   │   ├── AI/
│   │   ├── Interview/
│   │   └── Conference/
│   ├── ViewModels/
│   ├── Services/
│   │   ├── CloudKitService.swift
│   │   ├── EventKitService.swift
│   │   └── AIService.swift
│   └── Utils/
└── LifeAssistant.xcodeproj
```
