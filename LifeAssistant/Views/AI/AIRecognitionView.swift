//
//  AIRecognitionView.swift
//  LifeAssistant
//

import SwiftUI
import PhotosUI
import AppIntents

struct AIRecognitionView: View {
    @StateObject private var service = AIService()
    @StateObject private var accountService = AccountService()
    @StateObject private var todoService = TodoService()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingResultSheet = false
    @State private var showingPreviewSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingShortcutsTip = false
    @State private var saveSuccessMessage: String?
    @State private var selectedHistoryRecord: AIRecognitionRecord?
    @State private var showingHistoryDetail = false

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // 快捷指令提示卡片
                        ShortcutsTipCard(showing: $showingShortcutsTip)
                            .id("top")

                        // 上传区域
                        UploadAreaView(
                            selectedImage: $selectedImage,
                            showingImagePicker: $showingImagePicker,
                            showingCamera: $showingCamera,
                            sourceType: $sourceType
                        )

                        // 错误提示
                        if let error = service.lastError {
                            ErrorCard(message: error)
                        }

                        // 识别结果
                        if service.isProcessing {
                            LoadingCard()
                        } else if let result = service.lastResult {
                            RecognitionResultCard(
                                result: result,
                                onAddToAccount: { showingPreviewSheet = true },
                                onAddToTodo: { showingPreviewSheet = true }
                            )
                        }

                        // 历史记录
                        RecognitionHistorySection(
                            service: service,
                            onSelectRecord: { record in
                                selectedHistoryRecord = record
                                showingHistoryDetail = true
                            }
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
            .navigationTitle("AI 识图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShortcutsTip = true }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.title3)
                            .foregroundStyle(.purple)
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingPreviewSheet) {
                if let result = service.lastResult {
                    RecognitionPreviewSheet(
                        result: result,
                        image: selectedImage,
                        accountService: accountService,
                        todoService: todoService,
                        onSave: { message in
                            saveSuccessMessage = message
                            showingPreviewSheet = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingHistoryDetail) {
                if let record = selectedHistoryRecord {
                    HistoryDetailSheet(record: record)
                }
            }
            .alert("保存成功", isPresented: .init(
                get: { saveSuccessMessage != nil },
                set: { if !$0 { saveSuccessMessage = nil } }
            )) {
                Button("好的", role: .cancel) { saveSuccessMessage = nil }
            } message: {
                Text(saveSuccessMessage ?? "")
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    service.recognizeImage(image) { _ in
                        // 识别完成，自动弹出预览
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if service.lastResult != nil {
                                showingPreviewSheet = true
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 快捷指令提示卡片
struct ShortcutsTipCard: View {
    @Binding var showing: Bool

    var body: some View {
        if showing {
            CardView {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                            .font(.title)
                            .foregroundColor(.purple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("快捷指令")
                                .font(.headline)
                            Text("在桌面快速使用 AI 识图")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("知道了") {
                            showing = false
                        }
                        .font(.subheadline)
                        .buttonStyle(.bordered)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(number: 1, text: "打开「快捷指令」App")
                        InstructionRow(number: 2, text: "点击右上角「+」创建新快捷指令")
                        InstructionRow(number: 3, text: "搜索「生活助手」或「识别截图」")
                        InstructionRow(number: 4, text: "添加到快捷指令即可使用")
                    }

                    HStack(spacing: 12) {
                        Label("支持语音触发", systemImage: "mic.fill")
                            .font(.caption)
                            .foregroundColor(.purple)

                        Label("支持小组件", systemImage: "square.grid.2x2")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding(.horizontal)
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else {
            Button(action: { withAnimation { showing = true } }) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text("如何添加快捷指令？")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.purple)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 错误卡片
struct ErrorCard: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 上传区域
struct UploadAreaView: View {
    @Binding var selectedImage: UIImage?
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    @Binding var sourceType: UIImagePickerController.SourceType

    var body: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                // 已选择图片
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(16)

                    Button(action: { selectedImage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                .padding(.horizontal)
            } else {
                // 上传区域
                GradientCardView(
                    colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
                    cornerRadius: 24,
                    shadowRadius: 12
                ) {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("AI 智能识别")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("拍照或选择图片，自动识别记账或待办信息")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button(action: {
                                sourceType = .camera
                                showingCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("拍照")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(25)
                            }

                            Button(action: {
                                sourceType = .photoLibrary
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                    Text("相册")
                                }
                                .font(.headline)
                                .foregroundColor(Color(hex: "8B5CF6"))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(25)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 加载中卡片
struct LoadingCard: View {
    var body: some View {
        CardView {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))

                Text("正在识别图片...")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("AI 正在分析图片内容，请稍候")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
        }
        .padding(.horizontal)
    }
}

// MARK: - 识别结果卡片
struct RecognitionResultCard: View {
    let result: AIRecognitionResult
    let onAddToAccount: () -> Void
    let onAddToTodo: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // 类型标签
                    CategoryBadge(
                        title: result.type == .receipt ? "记账" : result.type == .todo ? "待办" : "未知",
                        color: result.type == .receipt ? .green : result.type == .todo ? .blue : .gray,
                        icon: result.type == .receipt ? "dollarsign.circle" : result.type == .todo ? "checklist" : "questionmark"
                    )

                    Spacer()

                    // 置信度
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                        Text(String(format: "%.0f%%", result.confidence * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
                }

                Divider()

                // 提取的数据
                if let data = result.extractedData {
                    VStack(alignment: .leading, spacing: 12) {
                        if let title = data.title {
                            InfoRow(icon: "text.quote", title: "标题", value: title)
                        }

                        if let amount = data.amount {
                            InfoRow(icon: "dollarsign.circle", title: "金额", value: String(format: "¥%.2f", amount))
                        }

                        if let category = data.category {
                            InfoRow(icon: "tag", title: "分类", value: category.rawValue)
                        }

                        if let merchant = data.merchant {
                            InfoRow(icon: "building.2", title: "商家", value: merchant)
                        }

                        if let dueDate = data.dueDate {
                            InfoRow(icon: "calendar", title: "截止日期", value: formatDate(dueDate))
                        }
                    }
                }

                Divider()

                // 操作按钮
                if result.type == .receipt {
                    Button(action: onAddToAccount) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加到记账")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                } else if result.type == .todo {
                    Button(action: onAddToTodo) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加到待办")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.purple)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - 历史记录
struct RecognitionHistorySection: View {
    @ObservedObject var service: AIService
    var onSelectRecord: (AIRecognitionRecord) -> Void

    @State private var isEditMode = false
    @State private var selectedRecords: Set<UUID> = []

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("识别历史")
                        .font(.headline)
                    Spacer()
                    Text("\(service.recognitionHistory.count) 条")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !service.recognitionHistory.isEmpty {
                        Button(action: {
                            withAnimation {
                                if isEditMode {
                                    // 退出编辑模式，清空选择
                                    selectedRecords.removeAll()
                                }
                                isEditMode.toggle()
                            }
                        }) {
                            Text(isEditMode ? "取消" : "管理")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                }

                if service.recognitionHistory.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "暂无历史",
                        message: "识别过的图片将显示在这里",
                        accentColor: .purple
                    )
                    .frame(height: 150)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(service.recognitionHistory.prefix(10)) { record in
                            HStack(spacing: 12) {
                                if isEditMode {
                                    // 选择圆圈
                                    Button(action: {
                                        withAnimation {
                                            if selectedRecords.contains(record.id) {
                                                selectedRecords.remove(record.id)
                                            } else {
                                                selectedRecords.insert(record.id)
                                            }
                                        }
                                    }) {
                                        Image(systemName: selectedRecords.contains(record.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundColor(selectedRecords.contains(record.id) ? .purple : .gray)
                                    }
                                }

                                Button(action: { onSelectRecord(record) }) {
                                    HistoryRow(record: record)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // 批量删除按钮
                    if isEditMode && !selectedRecords.isEmpty {
                        Button(role: .destructive) {
                            deleteSelectedRecords()
                        } label: {
                            HStack {
                                Spacer()
                                Label("删除选中的 \(selectedRecords.count) 条记录", systemImage: "trash")
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }

    private func deleteSelectedRecords() {
        for id in selectedRecords {
            if let record = service.recognitionHistory.first(where: { $0.id == id }) {
                service.deleteRecord(record)
            }
        }
        selectedRecords.removeAll()
        if service.recognitionHistory.isEmpty {
            isEditMode = false
        }
    }
}

struct HistoryRow: View {
    let record: AIRecognitionRecord

    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            if let image = record.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    CategoryBadge(
                        title: record.category == .receipt ? "记账" : record.category == .todo ? "待办" : "未知",
                        color: record.category == .receipt ? .green : record.category == .todo ? .blue : .gray,
                        size: .small
                    )

                    Spacer()

                    Text(formatDate(record.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(record.recognizedText.prefix(30) + (record.recognizedText.count > 30 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct AIRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        AIRecognitionView()
    }
}