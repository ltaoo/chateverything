import SwiftUI

struct UserCardView: View {
    let userName: String
    let userAvatar: String
    let userLevel: Int
    let abilities: [String]
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部用户信息区域
            HStack(spacing: 12) {
                // 头像
                AsyncImage(url: URL(string: userAvatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                // 用户名和等级
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Level \(userLevel)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // 能力标签区域
            FlowLayoutV2(spacing: 8) {
                ForEach(abilities, id: \.self) { ability in
                    AbilityTag(title: ability)
                }
            }
            .padding(.horizontal)
            
            // 底部统计信息
            HStack(spacing: 24) {
                StatItem(title: "对话", value: "128")
                StatItem(title: "收藏", value: "32")
                StatItem(title: "点赞", value: "256")
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}

// 能力标签组件
struct AbilityTag: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
    }
}

// 统计项组件
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// 流式布局组件
struct FlowLayoutV2: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return computeSize(rows: rows, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        placeViews(rows: rows, in: bounds)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if size.width > remainingWidth {
                currentRow += 1
                rows.append([])
                remainingWidth = (proposal.width ?? 0) - size.width - spacing
                rows[currentRow].append(subview)
            } else {
                remainingWidth -= size.width + spacing
                rows[currentRow].append(subview)
            }
        }
        
        return rows
    }
    
    private func computeSize(rows: [[LayoutSubviews.Element]], proposal: ProposedViewSize) -> CGSize {
        var height: CGFloat = 0
        var width: CGFloat = 0
        
        for row in rows {
            var rowWidth: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            
            width = max(width, rowWidth)
            height += rowHeight + spacing
        }
        
        return CGSize(width: width - spacing, height: height - spacing)
    }
    
    private func placeViews(rows: [[LayoutSubviews.Element]], in bounds: CGRect) {
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
}

#Preview {
    UserCardView(
        userName: "测试用户",
        userAvatar: "https://example.com/avatar.jpg",
        userLevel: 5,
        abilities: ["写作", "编程", "设计", "翻译", "数据分析"]
    )
    .padding()
} 