import SwiftUI

struct KeyButton: View {
    let letter: String
    let action: (String) -> Void
    
    var body: some View {
        Button(action: { action(letter) }) {
            Text(letter.uppercased())
                .font(.system(size: 28, weight: .medium))
                .frame(width: 65, height: 65)
                .background(Color.gray.opacity(0.15))
                .foregroundColor(.primary)
        }
    }
}

struct DeleteButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "delete.left.fill")
                .font(.system(size: 24))
                .frame(width: 65, height: 65)
                .background(Color.gray.opacity(0.15))
                .foregroundColor(.primary)
        }
    }
}

struct CustomKeyboardView: View {
    let onKeyTap: (String) -> Void
    let onDelete: () -> Void
    
    // 元音字母
    private let vowels = ["a", "e", "i", "o", "u"]
    
    // 辅音字母，重新排列以留出右下角的位置
    private let consonants = [
        ["b", "c", "d", "f", "g", "h", "j", "k"],
        ["l", "m", "n", "p", "q", "r", "s", "t"],
        ["u", "v", "w", "x", "y", "z"]  // 最后一行较短，为删除键留位置
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 元音区域
            HStack(spacing: 0) {
                ForEach(vowels, id: \.self) { letter in
                    KeyButton(letter: letter, action: onKeyTap)
                }
            }
            
            // 辅音区域
            VStack(spacing: 0) {
                ForEach(consonants, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(row, id: \.self) { letter in
                            KeyButton(letter: letter, action: onKeyTap)
                        }
                        // 在最后一行补充空白和删除键
                        if row == consonants.last {
                            Spacer()
                            DeleteButton(action: onDelete)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: -2)
    }
}

struct CustomKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        CustomKeyboardView(
            onKeyTap: { letter in
                print("Tapped letter: \(letter)")
            },
            onDelete: {
                print("Delete tapped")
            }
        )
    }
} 