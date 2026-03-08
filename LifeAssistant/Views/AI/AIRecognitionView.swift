//
//  AIRecognitionView.swift
//  LifeAssistant
//

import SwiftUI
import PhotosUI

struct AIRecognitionView: View {
    @StateObject private var service = AIService()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingResultSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 上传区域
                    UploadAreaView(
                        selectedImage: $selectedImage,
                        showingImagePicker: $showingImagePicker,
                        showingCamera: $showingCamera,
                        sourceType: $sourceType
                    )
                    
                    // 识别结果
                    if service.isProcessing {
                        LoadingCard()
                    } else if let result = service.lastResult {
                        RecognitionResultCard(result: result) {
                            showingResultSheet = true
                        }
                    }
                    
                    // 历史记录
                    RecognitionHistorySection(service: service)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("AI 识图")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingResultSheet) {
                if let result = service.lastResult {
                    ResultActionSheet(result: result)
                }
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    service.recognizeImage(image) { _ in
                        // 识别完成
                    }
                }
            }
        }
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
    let onAction: () -> Void
    
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
                Button(action: onAction) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("添加到应用")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
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
                        ForEach(service.recognitionHistory.prefix(5)) { record in
                            HistoryRow(record: record)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        service.deleteRecord(record)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
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

// MARK: - 结果操作表
struct ResultActionSheet: View {
    let result: AIRecognitionResult
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("识别结果")) {
                    if let data = result.extractedData {
                        if result.type == .receipt {
                            if let amount = data.amount {
                                HStack {
                                    Text("金额")
                                    Spacer()
                                    Text(String(format: "¥%.2f", amount))
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            if let category = data.category {
                                HStack {
                                    Text("分类")
                                    Spacer()
                                    Text(category.rawValue)
                                }
                            }
                            
                            if let merchant = data.merchant {
                                HStack {
                                    Text("商家")
                                    Spacer()
                                    Text(merchant)
                                }
                            }
                        } else if result.type == .todo {
                            if let title = data.title {
                                HStack {
                                    Text("标题")
                                    Spacer()
                                    Text(title)
                                }
                            }
                            
                            if let dueDate = data.dueDate {
                                HStack {
                                    Text("截止日期")
                                    Spacer()
                                    Text(formatDate(dueDate))
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("操作")) {
                    if result.type == .receipt {
                        Button(action: {
                            // 添加到记账
                            dismiss()
                        }) {
                            Label("添加到记账", systemImage: "dollarsign.circle.fill")
                        }
                    } else if result.type == .todo {
                        Button(action: {
                            // 添加到待办
                            dismiss()
                        }) {
                            Label("添加到待办", systemImage: "checklist")
                        }
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Label("重新识别", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("识别结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
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
