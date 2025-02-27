import SwiftUI

struct VocabularyReviewPage: View {
    var config: Config
    @State private var reviewStats: [(Date, Int)] = []
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(reviewStats, id: \.0) { date, count in
                        ReviewCard(date: date, wordCount: count) {
                            NavigationLink(destination: VocabularyReviewSessionView(
                                date: date,
                                manager: VocabularyReviewManager(config: config),
                                config: config)
                            ) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                    }
                }
                .padding()
            }
        }
        .task {
            await loadStats()
        }
    }
    
    private func loadStats() async {
        do {
            let manager = VocabularyReviewManager(config: self.config)
            reviewStats = try await manager.getReviewStats()
            isLoading = false
        } catch {
            print("Failed to load review stats: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

struct ReviewCard: View {
    let date: Date
    let wordCount: Int
    let destination: () -> AnyView
    
    init(date: Date, wordCount: Int, @ViewBuilder destination: @escaping () -> some View) {
        self.date = date
        self.wordCount = wordCount
        self.destination = { AnyView(destination()) }
    }
    
    var body: some View {
        ZStack {
            destination()
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDate(date))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(wordCount) 个单词待复习")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Button(action: {
                        // TODO: 实现查看所有生词功能
                    }) {
                        Text("查看所有生词")
                            .font(.footnote)
                            .foregroundColor(wordCount > 0 ? .blue : .gray)
                    }
                    .disabled(wordCount == 0)
                    
                    Spacer()
                    
                    Button(action: {
                        // TODO: 开始复习
                    }) {
                        Text("开始复习")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(wordCount > 0 ? Color.blue : Color.gray)
                            .cornerRadius(16)
                    }
                    .disabled(wordCount == 0)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

struct VocabularyReviewSessionView: View {
    let date: Date
    var config: Config
    var manager: VocabularyReviewManager
    @Environment(\.dismiss) var dismiss
    
    @State private var currentWords: [Vocabulary] = []
    @State private var loadedWords: [Vocabulary] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    
    init(date: Date, manager: VocabularyReviewManager, config: Config) {
        self.date = date
        self.config = config
        self.manager = manager
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if currentWords.isEmpty {
                VStack {
                    Text("没有需要复习的单词")
                    Button("返回") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text(currentWords[currentIndex].text!)
                        .font(.largeTitle)
                    
                    Text(currentWords[currentIndex].translation!)
                        .font(.title2)
                    
                    Text(currentWords[currentIndex].pronunciation!)
                        .font(.body)
                        .padding()
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    HStack(spacing: 40) {
                        Button("记得") {
                            handleReview(timeSpent: 3)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("跳过") {
                            handleReview(timeSpent: 12)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("复习")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWords()
        }
    }
    
    private func loadWords() async {
        do {
            loadedWords = try await self.manager.getReviewWords(for: date)
            currentWords = Array(loadedWords.prefix(20))
            isLoading = false
        } catch {
            print("Failed to load words: \(error)")
        }
    }
    
    private func handleReview(timeSpent: Int) {
        let word = currentWords[currentIndex]
        let result = VocabularyReviewResult(
            vocabulary: word,
            time_spent: timeSpent,
            created_at: Date()
        )
        self.manager.calculateNextReview(result: result)
        
        moveToNextWord()
    }
    
    private func moveToNextWord() {
        if currentIndex + 1 < currentWords.count {
            currentIndex += 1
        } else {
            // Load more words if available
            let nextBatchStart = currentWords.count
            let remainingWords = Array(loadedWords.dropFirst(nextBatchStart))
            
            if remainingWords.isEmpty {
                // No more words to review
                currentWords = []
            } else {
                let nextBatch = Array(remainingWords.prefix(20))
                currentWords = nextBatch
                currentIndex = 0
            }
        }
        
        // If we have 5 or fewer words left, load the next batch
        if currentWords.count - currentIndex <= 5 {
            let nextBatchStart = currentWords.count
            let remainingWords = Array(loadedWords.dropFirst(nextBatchStart))
            if !remainingWords.isEmpty {
                let nextBatch = Array(remainingWords.prefix(20))
                currentWords.append(contentsOf: nextBatch)
            }
        }
    }
}
