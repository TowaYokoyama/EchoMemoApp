

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute, .second], from: self, to: now)
        
        if let year = components.year, year >= 1 {
            return year == 1 ? "1年前" : "\(year)年前"
        }
        
        if let month = components.month, month >= 1 {
            return month == 1 ? "1ヶ月前" : "\(month)ヶ月前"
        }
        
        if let week = components.weekOfYear, week >= 1 {
            return week == 1 ? "1週間前" : "\(week)週間前"
        }
        
        if let day = components.day, day >= 1 {
            return day == 1 ? "1日前" : "\(day)日前"
        }
        
        if let hour = components.hour, hour >= 1 {
            return hour == 1 ? "1時間前" : "\(hour)時間前"
        }
        
        if let minute = components.minute, minute >= 1 {
            return minute == 1 ? "1分前" : "\(minute)分前"
        }
        
        return "たった今"
    }
    
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    func isYesterday() -> Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    func isThisWeek() -> Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}
