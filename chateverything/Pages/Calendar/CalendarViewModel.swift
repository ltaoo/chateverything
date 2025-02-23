import Foundation

class CalendarViewModel: ObservableObject {
    @Published var dates: [Date] = []
    @Published var showFullMonth: Bool = true
    @Published var selectedDate: Date = Date()
    
    private let calendar = Calendar.current
    
    var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: selectedDate)
    }
    
    var currentWeekRange: String {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfMonth, for: selectedDate)
        guard let firstDay = weekInterval?.start,
              let lastDay = calendar.date(byAdding: .day, value: 6, to: firstDay) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日"
        
        return "\(formatter.string(from: firstDay)) - \(formatter.string(from: lastDay))"
    }
    
    init() {
        updateDates()

	print("init \(dates.count)")

	// 遍历打印 dates
	for date in dates {
	print("date: \(date.formatted(date: .long, time: .omitted))")
	}

    }
    
    func updateDates() {
            dates = calculateMonthDates()
        // if showFullMonth {
        // } else {
        //     dates = calculateWeekDates()
        // }
    }
    
    private func calculateWeekDates() -> [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // 获取本周的第一天 (从周一开始)
        let weekStart = calendar.date(byAdding: .day, value: 2-weekday, to: today)!
        
        return (0..<7).map { day in
            calendar.date(byAdding: .day, value: day, to: weekStart)!
        }
    }
    
    private func calculateMonthDates() -> [Date] {
        let today = Date()
        let interval = calendar.dateInterval(of: .month, for: today)!
        let monthStart = interval.start
        
        // 获取月初是周几
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        // 需要补充的上月天数
        let prefixDays = (firstWeekday + 5) % 7 // 转换为周一开始
        
        // 获取这个月的总天数
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)!.count
        
        // 计算需要补充的下月天数，确保总是显示6周
        let totalDays = 42 // 6周 * 7天
        let suffixDays = totalDays - daysInMonth - prefixDays
        
        var dates: [Date] = []
        
        // 添加上月日期
        for day in (1...prefixDays).reversed() {
            let date = calendar.date(byAdding: .day, value: -day, to: monthStart)!
            dates.append(date)
        }
        
        // 添加本月日期
        for day in 0..<daysInMonth {
            let date = calendar.date(byAdding: .day, value: day, to: monthStart)!
            dates.append(date)
        }
        
        // 添加下月日期
        let monthEnd = calendar.date(byAdding: .day, value: daysInMonth - 1, to: monthStart)!
        for day in 1...suffixDays {
            let date = calendar.date(byAdding: .day, value: day, to: monthEnd)!
            dates.append(date)
        }
        
        return dates
    }
    
    func toggleMonthView() {
        showFullMonth.toggle()
        updateDates()
    }
} 