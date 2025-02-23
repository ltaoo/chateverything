import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Weekday headers
            HStack {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { weekday in
                    Text(weekday)
                        .font(DesignSystem.Typography.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.xSmall) {
                ForEach(viewModel.dates, id: \.self) { date in
                    DayCell(date: date, isCurrentMonth: isCurrentMonth(date))
                }
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.background)
    }
    
    private func isCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.component(.month, from: date) == Calendar.current.component(.month, from: Date())
    }
}

struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    
    private var calendar: Calendar { Calendar.current }
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        Text("\(calendar.component(.day, from: date))")
            .font(DesignSystem.Typography.bodyMedium)
            .frame(height: 35)
            .frame(maxWidth: .infinity)
            .foregroundColor(isCurrentMonth ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textDisabled)
            .background(isToday ? DesignSystem.Colors.primaryLight : Color.clear)
            .cornerRadius(DesignSystem.Radius.medium)
    }
} 