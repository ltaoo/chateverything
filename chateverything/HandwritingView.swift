import SwiftUI
import PencilKit

struct HandwritingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HandwritingViewModel()
    let onComplete: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                CanvasView(canvasView: viewModel.canvasView)
                    .frame(height: 300)
                    .background(Color.white)
                    .border(Color.gray)
                    .padding()
                
                Spacer()
                
                Button("完成") {
                    // 将绘制的内容转换为图片
                    let image = viewModel.canvasView.drawing.image(from: viewModel.canvasView.bounds, scale: UIScreen.main.scale)
                    // TODO: 这里可以之后添加文字识别功能
                    onComplete("测试文本")
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("手写输入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("清除") {
                        viewModel.clearCanvas()
                    }
                }
            }
        }
    }
}

class HandwritingViewModel: ObservableObject {
    let canvasView: PKCanvasView
    
    init() {
        canvasView = PKCanvasView()
        setupCanvas()
    }
    
    private func setupCanvas() {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 12)
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy = .anyInput

        // 基本设置
        canvasView.allowsFingerDrawing = true
        // canvasView.isOpaque = false
    }
    
    func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }
}

struct CanvasView: UIViewRepresentable {
    let canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 不需要更新
    }
}

#Preview {
    HandwritingView { text in
        print(text)
    }
} 
