import Foundation
import UIKit

class CalendarModel {
    
    let calendar = Calendar.current
    
    func plusMonth(date: Date) -> Date {
        return calendar.date(byAdding: .month, value: 1, to: date)!
    }

    func minusMonth(date: Date) -> Date {
        return calendar.date(byAdding: .month, value: -1, to: date)!
    }

    func plusYear(date: Date) -> Date {
        return calendar.date(byAdding: .year, value: 1, to: date)!
    }

    func minusYear(date: Date) -> Date {
        return calendar.date(byAdding: .year, value: -1, to: date)!
    }
    
    func monthString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        return dateFormatter.string(from: date)
    }
    
    func yearString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: date)
    }
    
    func daysInMonth(date: Date) -> Int {
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    func dayOfMonth(date: Date) -> Int {
        let components = calendar.dateComponents([.day], from: date)
        return components.day!
    }
    
    func firstOfMonth(date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components)!
    }
    
    func weekday(date: Date) -> Int {
        let components = calendar.dateComponents([.weekday], from: date)
        return components.weekday! - 2
    }
    
    func isOverNightEvent(startDate: Date?, endDate: Date?) -> Bool {
        if startDate != nil && endDate != nil {
            if startDate!.get(.day, .month, .year) != endDate!.get(.day, .month, .year) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}
