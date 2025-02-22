import SwiftUI

struct SceneView: View {
    // 场景分类
    enum SceneCategory: String, CaseIterable {
        case daily = "日常生活"
        case business = "商务职场"
        case travel = "旅游出行"
        case study = "学习教育"
    }
    
    @State private var selectedCategory: SceneCategory = .daily
    
    // 场景数据结构
    struct Scene: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let category: SceneCategory
    }
    
    // 场景数据
    let scenes: [Scene] = [
        // 日常生活场景
        Scene(title: "At the Restaurant", description: "餐厅用餐场景对话", category: .daily),
        Scene(title: "Shopping", description: "购物场景对话", category: .daily),
        Scene(title: "Making Friends", description: "社交场景对话", category: .daily),
        
        // 商务职场场景
        Scene(title: "Job Interview", description: "求职面试对话", category: .business),
        Scene(title: "Business Meeting", description: "商务会议对话", category: .business),
        Scene(title: "Office Communication", description: "办公室交流", category: .business),
        
        // 旅游场景
        Scene(title: "At the Airport", description: "机场场景对话", category: .travel),
        Scene(title: "Hotel Check-in", description: "酒店入住对话", category: .travel),
        Scene(title: "Asking Directions", description: "问路场景对话", category: .travel),
        
        // 学习场景
        Scene(title: "In the Classroom", description: "课堂场景对话", category: .study),
        Scene(title: "Group Discussion", description: "小组讨论对话", category: .study),
        Scene(title: "Library", description: "图书馆场景对话", category: .study)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // 顶部分类标签栏
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(SceneCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category.rawValue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
                
                // 场景列表
                List {
                    ForEach(scenes.filter { $0.category == selectedCategory }) { scene in
                        NavigationLink(destination: Text("场景详情页面待开发")) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(scene.title)
                                    .font(.headline)
                                Text(scene.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("英语学习场景")
        }
    }
}

struct SceneView_Previews: PreviewProvider {
    static var previews: some View {
        SceneView()
    }
}
