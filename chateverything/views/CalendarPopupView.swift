import SwiftUI

struct CalendarPopupView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Title and close button
            HStack {
                Text(viewModel.showFullMonth ? 
                    "\(viewModel.currentMonthYear)" : 
                    "\(viewModel.currentWeekRange)")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            CalendarView()
            
            Spacer()
        }
        .padding(.top)
        .background(Color(.systemBackground))
    }
}

struct WeekGridView: View {
    let dates: [Date]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(dates, id: \.self) { date in
                DayCell(date: date, isCurrentMonth: false)
            }
        }
        .padding(.horizontal)
    }
}

struct MonthGridView: View {
    let dates: [Date]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(dates, id: \.self) { date in
                DayCell(date: date, isCurrentMonth: false)
            }
        }
        .padding(.horizontal)
    }
}

// struct DayCell: View {
//     let date: Date
//     let calendar = Calendar.current
    
//     private var isToday: Bool {
//         calendar.isDateInToday(date)
//     }
    
//     var body: some View {
//         VStack {
//             Text("\(calendar.component(.day, from: date))")
//                 .font(.system(size: 16, weight: isToday ? .bold : .regular))
//             Text(weekdayString(from: date))
//                 .font(.system(size: 12))
//                 .foregroundColor(.gray)
//         }
//         .frame(height: 50)
//         .frame(maxWidth: .infinity)
//         .background(isToday ? Color.blue.opacity(0.1) : Color.clear)
//         .cornerRadius(8)
//     }
    
//     private func weekdayString(from date: Date) -> String {
//         let formatter = DateFormatter()
//         formatter.locale = Locale(identifier: "zh_CN")
//         formatter.dateFormat = "E"
//         return formatter.string(from: date)
//     }
// } 
