import SwiftUI

struct ErrorOverlayView: View {
    let error: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
                
                Text(error)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red)
                
                Button(action: onDismiss) {
                    Text("返回")
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 8)
            .padding(24)
            
            Spacer()
        }
        .background(Color.black.opacity(0.4))
        .edgesIgnoringSafeArea(.all)
    }
}

