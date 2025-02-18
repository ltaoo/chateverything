import SwiftUI

// 题目类型枚举
enum QuestionType {
    case multipleChoice
    case trueFalse
    case fillInBlank
}

// 题目模型
struct Question: Identifiable {
    let id = UUID()
    let type: QuestionType
    let question: String
    let options: [String]      // 选择题的选项
    let correctAnswer: String  // 正确答案
    var userAnswer: String?    // 用户答案
}

struct Challenge: View {
    @State private var questions: [Question] = [
        Question(type: .multipleChoice, 
                question: "1 + 1 = ?", 
                options: ["1", "2", "3", "4"], 
                correctAnswer: "2"),
        Question(type: .trueFalse, 
                question: "地球是圆的", 
                options: ["对", "错"], 
                correctAnswer: "对"),
        Question(type: .fillInBlank, 
                question: "中国的首都是____", 
                options: [], 
                correctAnswer: "北京")
    ]
    
    @State private var currentQuestionIndex = 0
    @State private var showResult = false
    @State private var userInput = ""
    
    var body: some View {
        VStack {
            if showResult {
                resultView
            } else {
                questionView
            }
        }
        .padding()
    }
    
    var questionView: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(questions.count))
            
            Text("问题 \(currentQuestionIndex + 1)/\(questions.count)")
                .font(.headline)
            
            Text(questions[currentQuestionIndex].question)
                .font(.title2)
                .padding()
            
            switch questions[currentQuestionIndex].type {
            case .multipleChoice:
                ForEach(questions[currentQuestionIndex].options, id: \.self) { option in
                    Button(action: {
                        selectAnswer(option)
                    }) {
                        Text(option)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(questions[currentQuestionIndex].userAnswer == option ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(questions[currentQuestionIndex].userAnswer == option ? .white : .black)
                            .cornerRadius(10)
                    }
                }
                
            case .trueFalse:
                HStack {
                    ForEach(questions[currentQuestionIndex].options, id: \.self) { option in
                        Button(action: {
                            selectAnswer(option)
                        }) {
                            Text(option)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(questions[currentQuestionIndex].userAnswer == option ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(questions[currentQuestionIndex].userAnswer == option ? .white : .black)
                                .cornerRadius(10)
                        }
                    }
                }
                
            case .fillInBlank:
                TextField("请输入答案", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("提交答案") {
                    selectAnswer(userInput)
                }
                .buttonStyle(.bordered)
            }
            
            if currentQuestionIndex < questions.count - 1 {
                Button("下一题") {
                    currentQuestionIndex += 1
                    userInput = ""
                }
                .buttonStyle(.bordered)
                .disabled(questions[currentQuestionIndex].userAnswer == nil)
            } else {
                Button("查看结果") {
                    showResult = true
                }
                .buttonStyle(.bordered)
                .disabled(questions[currentQuestionIndex].userAnswer == nil)
            }
        }
    }
    
    var resultView: some View {
        VStack(spacing: 20) {
            Text("答题结果")
                .font(.title)
            
            let correctCount = questions.filter { $0.userAnswer == $0.correctAnswer }.count
            
            Text("总分: \(correctCount)/\(questions.count)")
                .font(.headline)
            
            ForEach(questions.indices, id: \.self) { index in
                VStack(alignment: .leading) {
                    Text("问题 \(index + 1): \(questions[index].question)")
                    Text("你的答案: \(questions[index].userAnswer ?? "未作答")")
                    Text("正确答案: \(questions[index].correctAnswer)")
                    Text(questions[index].userAnswer == questions[index].correctAnswer ? "✅ 正确" : "❌ 错误")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button("重新开始") {
                resetQuiz()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func selectAnswer(_ answer: String) {
        questions[currentQuestionIndex].userAnswer = answer
    }
    
    private func resetQuiz() {
        for index in questions.indices {
            questions[index].userAnswer = nil
        }
        currentQuestionIndex = 0
        showResult = false
        userInput = ""
    }
}

#Preview {
    Challenge()
}
