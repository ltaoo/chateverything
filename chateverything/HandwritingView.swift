import SwiftUI
import PencilKit
import Vision

struct HandwritingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var handwritingManager = HandwritingManager()
    let onRecognized: (String) -> Void
    
    var body: some View {
        NavigationStack {
            if #available(iOS 14.0, *) {
                VStack {
                    DrawingView(manager: handwritingManager)
                        .frame(height: 300)
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                    
                    Spacer()
                }
                .gesture(DragGesture())
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
                            handwritingManager.clearDrawing()
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        Button("识别") {
                            handwritingManager.recognizeHandwriting { text in
                                onRecognized(text)
                                dismiss()
                            }
                        }
                    }
                }
                .interactiveDismissDisabled()
            } else {
                VStack {
                    LegacyDrawingView(manager: handwritingManager)
                        .frame(height: 300)
                        .padding()
                    
                    Spacer()
                }
                .navigationBarItems(
                    leading: Button("取消") { dismiss() },
                    trailing: Button("清除") { handwritingManager.clearDrawing() }
                )
                .navigationBarItems(
                    trailing: Button("识别") {
                        handwritingManager.recognizeHandwriting { text in
                            onRecognized(text)
                            dismiss()
                        }
                    }
                )
            }
        }
    }
}

// 处理手写识别的管理类
class HandwritingManager: ObservableObject {
    private var canvasView: PKCanvasView
    
    init() {
        canvasView = PKCanvasView()
        setupCanvas()
    }
    
    private func setupCanvas() {
        // 使用更适合手写的笔画设置
        let ink = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.tool = ink
        
        // 设置画布背景
        canvasView.backgroundColor = .white
        
        // 配置画布行为
        if #available(iOS 14.0, *) {
            canvasView.drawingPolicy = .anyInput
        }
        
        // 禁用所有可能影响绘画的手势
        canvasView.isMultipleTouchEnabled = true
        canvasView.allowsFingerDrawing = true
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 1.0
        canvasView.alwaysBounceVertical = false
        canvasView.alwaysBounceHorizontal = false
        canvasView.isScrollEnabled = false
        canvasView.delaysContentTouches = false
        
        // 设置画布代理
        canvasView.delegate = DrawingDelegate.shared
        
        // 禁用系统手势
        if let window = UIApplication.shared.windows.first {
            window.gestureRecognizers?.forEach { gesture in
                gesture.isEnabled = false
            }
        }
    }
    
    func clearDrawing() {
        canvasView.drawing = PKDrawing()
    }
    
    func recognizeHandwriting(completion: @escaping (String) -> Void) {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion("")
                }
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let result = recognizedStrings.joined(separator: " ")
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        guard let cgImage = image.cgImage else { return }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    func getCanvasView() -> PKCanvasView {
        return canvasView
    }
}

// 添加一个画布代理类来处理触摸事件
class DrawingDelegate: NSObject, PKCanvasViewDelegate {
    static let shared = DrawingDelegate()
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // 确保绘画内容保持显示
        canvasView.drawing = canvasView.drawing
    }
    
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        // 确保工具保持活跃
        canvasView.becomeFirstResponder()
    }
    
    func canvasViewDidFinishRendering(_ canvasView: PKCanvasView) {
        // 强制重新渲染以保持内容可见
        canvasView.setNeedsDisplay()
    }
}

// iOS 14+ 的绘图视图
struct DrawingView: UIViewRepresentable {
    let manager: HandwritingManager
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = manager.getCanvasView()
        
        // 设置画布尺寸和样式
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 300)
        canvas.frame = frame
        
        // 设置边框和圆角
        canvas.layer.borderWidth = 1.0
        canvas.layer.borderColor = UIColor.gray.cgColor
        canvas.layer.cornerRadius = 12
        canvas.clipsToBounds = true
        
        // 禁用所有系统手势识别器
        canvas.gestureRecognizers?.forEach { gesture in
            if !gesture.isKind(of: UIPanGestureRecognizer.self) {
                gesture.isEnabled = false
            }
        }
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 300)
    }
}

// iOS 13 的后备绘图视图
struct LegacyDrawingView: UIViewRepresentable {
    let manager: HandwritingManager
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = manager.getCanvasView()
        
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 300)
        canvas.frame = frame
        
        canvas.layer.borderWidth = 1.0
        canvas.layer.borderColor = UIColor.gray.cgColor
        canvas.layer.cornerRadius = 12
        canvas.clipsToBounds = true
        
        // 禁用所有系统手势识别器
        canvas.gestureRecognizers?.forEach { gesture in
            if !gesture.isKind(of: UIPanGestureRecognizer.self) {
                gesture.isEnabled = false
            }
        }
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 300)
    }
} 
