import SwiftUI

struct WordDefinition {
    var word: String
    var phonetic: String
    var meanings: [String]
}

struct SearchView: View {
    @State private var searchText = ""
    @State private var wordResult: WordDefinition?
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                TextField("输入要查询的单词", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        wordResult = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
            }
            .frame(height: 44)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if isSearching {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            if let result = wordResult {
                // 单词展示区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(result.word)
                                .font(.system(size: 32, weight: .bold))
                            
                            HStack(spacing: 12) {
                                Text(result.phonetic)
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    // TODO: 添加发音功能
                                }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("释义")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            ForEach(result.meanings, id: \.self) { meaning in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                    Text(meaning)
                                        .lineSpacing(4)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
        //     Spacer()
            
        //     // 默认显示键盘
        //     CustomKeyboardView { letter in
        //         searchText += letter
        //     } onDelete: {
        //         searchText.removeLast()
        //     }
        }
        .onSubmit(of: .text) {
            if !searchText.isEmpty {
                searchWord()
            }
        }
    }
    
    private func searchWord() {
        isSearching = true
        
        // 示例数据 - love
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            wordResult = WordDefinition(
                word: "love",
                phonetic: "/lʌv/",
                meanings: [
                    "n. 爱；爱情；喜爱；热爱",
                    "v. 爱；热爱；喜欢；赞美",
                    "n. 恋爱；爱情，爱意",
                    "n. 亲爱的人；心爱的人",
                    "v. 深深喜欢；对...感兴趣"
                ]
            )
            isSearching = false
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
