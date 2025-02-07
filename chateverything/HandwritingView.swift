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
                    .onAppear {
                        // 确保视图出现时重新配置画布
                        viewModel.reconfigureCanvas()
                    }
                
                Spacer()
                
                Button("完成") {
                    let image = viewModel.canvasView.drawing.image(from: viewModel.canvasView.bounds, scale: UIScreen.main.scale)
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
    
    let canvasView = PKCanvasView()
    private let toolPicker = PKToolPicker()
    
    init() {
//        canvasView = PKCanvasView()
        setupCanvas()
    }
    
    private func setupCanvas() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
                // Make the canvas respond to tool changes
        toolPicker.addObserver(canvasView)
                // Make the canvas active -- first responder
        canvasView.becomeFirstResponder()
        // 基本设置
        
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        
        // 配置画笔
//        let ink = PKInkingTool(.pen, color: .black, width: 12)
//        ink.setVisible(true, forFirstResponder: canvasView)
//        canvasView.tool = ink
        
        // 禁用不需要的功能
        canvasView.isScrollEnabled = false
        canvasView.maximumZoomScale = 1.0
        canvasView.minimumZoomScale = 1.0
        
        // iOS 18.3 特定设置
        if #available(iOS 14.0, *) {
            canvasView.drawingGestureRecognizer.isEnabled = true
        }
        
        // 确保可以接收触摸事件
        canvasView.isUserInteractionEnabled = true
        canvasView.isMultipleTouchEnabled = true
    }
    
    func reconfigureCanvas() {
        // 重新配置画布大小和布局
        let bounds = UIScreen.main.bounds
        canvasView.frame = CGRect(x: 0, y: 0, width: bounds.width - 32, height: 300)
        canvasView.becomeFirstResponder()
        
        // 重新应用设置
        setupCanvas()
    }
    
    func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }
}

struct CanvasView: UIViewRepresentable {
    let canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        // 设置代理
        canvasView.delegate = context.coordinator
        
        // 配置基本属性
        canvasView.isUserInteractionEnabled = true
        
        // 禁用所有默认手势识别器
        if let gestureRecognizers = canvasView.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer is UIPanGestureRecognizer {
                    recognizer.isEnabled = true
                    recognizer.cancelsTouchesInView = false
                } else {
                    recognizer.isEnabled = false
                }
            }
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 确保画布保持正确的大小
        let bounds = UIScreen.main.bounds
        uiView.frame = CGRect(x: 0, y: 0, width: bounds.width - 32, height: 300)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            canvasView.setNeedsDisplay()
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            canvasView.becomeFirstResponder()
        }
    }
}

#Preview {
    HandwritingView { text in
        print(text)
    }
} 
