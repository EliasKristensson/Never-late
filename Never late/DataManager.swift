//
//  DataManager.swift
//  Never late
//
//  Created by Elias Kristensson on 2021-03-30.
//

import Foundation
import UIKit
import CloudKit
import CoreData
import PDFKit
import EventKit
import EventKitUI
import PencilKit

struct calendarEvent {
    var title: String
    var date: Date
}

class DataManager {

//    var privateDatabase: CKDatabase! = nil
//    var recordZone: CKRecordZone! = nil
    var context: NSManagedObjectContext!
    var todoItems: [Item] = []
    var deadlineItems: [Item] = []
    var calendarItems: [Item] = []
    var storedCalendars: [StoredCalendar] = []
    var storedNotes: [Note] = []
    var calendars: [EKCalendar] = []
    let eventStore = EKEventStore()
    let typeValueToString: [Int: String] = [0: "Calendar", 1: "To do", 2: "Deadline", 3: "Reminder", 4: "List"]
    let priorityValueToString: [Int: String] = [0: "Low", 1: "Medium", 2: "High"]
    let priorityStringToValue: [String: Int] = ["Low": 0, "Medium": 1, "High": 2]
    var recurranceRule: EKRecurrenceRule? = nil
    var specialCharacters = ["\u{2022}", "\u{002A}", "\u{2023}", "\u{21E8}", "\u{25CB}", "\u{2713}"]
    
    var mainPath: URL!
    
    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday","Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday","Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday","Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var items: [Item] = []
    var lists: [List] = []
    var notes: [Note] = []
    
    
    // MARK: FUNCTIONS
    func addItemToCalendar(item: Item) {
        print("addItemToCalendar()")
        
        if let calendar = eventStore.calendar(withIdentifier: item.calendarId!) {
            
            let event: EKEvent = EKEvent(eventStore: eventStore)
            
            event.title = item.title
            event.startDate = item.startDate
            event.endDate = item.endDate
            event.notes = item.body
            event.calendar = calendar
            event.isAllDay = item.isAllDay
            
            if let rule = recurranceRule {
                event.addRecurrenceRule(rule)
                print(rule)
            }
            
            if item.alert {
                event.alarms = [EKAlarm(relativeOffset: -item.alertTime)]
            }
            
            do {
                try eventStore.save(event, span: .thisEvent)
            } catch let error as NSError {
                print("failed to save event with error : \(error)")
            }
            
            print("Saved Event")
        }
        
    }
    
    func addOrUpdateList(list: List?, title: String) {
        if list == nil {
            let newList = List(context: context)
            newList.dateAdded = Date()
            newList.active = true
            newList.text = ""
            newList.title = title
            
            lists.append(newList)
            
        } else {
            let currentList = lists.first(where: { $0.dateAdded == list!.dateAdded })
        }
        saveCoreData()
    }
    
    func addNewNote(filename: String, title: String, mainPath: URL) {
        
        let newNote = Note(context: context)
        newNote.dateAdded = Date()
        newNote.title = title
        newNote.url = mainPath.appendingPathComponent(filename + ".data")
        
        notes.append(newNote)
        
        saveCoreData()
    }
    
    func deleteCoreData() {
        for item in items {
            context.delete(item)
        }
//        for calendar in storedCalendars {
//            context.delete(calendar)
//        }
        saveCoreData()
    }
    
    func eraseCalendarItem(item: Item) {
        print("eraseCalendarItem()")

        if let event = eventStore.event(withIdentifier: item.eventId!) {
            do {
                try eventStore.remove(event, span: .thisEvent)
            } catch let error as NSError {
                print("failed to remove event with error : \(error)")
            }
            print("Event deleted")
        } else {
            print("Failed to get event")
        }
    }
    
    func getCalendarEvents() {
        
        calendarItems.removeAll()
        
        if !calendars.isEmpty {
            
            let predicate = eventStore.predicateForEvents(withStart: Date().adding(days: -1), end: Date().adding(days: 22), calendars: calendars)
            let events = eventStore.events(matching: predicate)
            
            for event in events {
                
                let newItem = Item(context: context)
                newItem.title = event.title
                newItem.startDate = event.startDate
                newItem.endDate = event.endDate
                newItem.isAllDay = event.isAllDay
                newItem.trash = false
                newItem.type = "Calendar"
                newItem.calendarTitle = event.calendar.title
                newItem.body = event.notes
                newItem.calendarId = event.calendar.calendarIdentifier
                newItem.eventId = event.eventIdentifier
                
                calendarItems.append(newItem)
            }
        }
    }
    
    func getCalendarEventsOn(day: Date) -> [EKEvent]? {
        
        if !calendars.isEmpty {
            let predicate = eventStore.predicateForEvents(withStart: day, end: day.adding(days: 1), calendars: calendars)
            let events = eventStore.events(matching: predicate)
            return events
        } else {
            return nil
        }
    }
    
    func getCalendarColor(calendarId: String?) -> UIColor {
        
        if let calendar = calendars.first(where: { $0.calendarIdentifier == calendarId }) {
            if let color = calendar.cgColor {
                return UIColor(cgColor: color)
            } else {
                return UIColor(red: 0, green: 0, blue: 1, alpha: 0.3)
            }
        } else {
            return UIColor(red: 0, green: 0, blue: 1, alpha: 0.3)
        }
    }

    func loadCoreData() {
        print("loadCoreData")

        do {
            items = try context.fetch(Item.fetchRequest())
//            for item in items {
//                if item.type == "To do" {
//                    print(item)
//                }
//                print(item.title)
//                context.delete(item)
//            }
//            saveCoreData()
        } catch {
            print(error)
        }

        do {
            lists = try context.fetch(List.fetchRequest())
//            for list in lists {
//                context.delete(list)
//            }
//            lists = []
        } catch {
            print(error)
        }
        
        do {
            notes = try context.fetch(Note.fetchRequest())
//            for note in notes {
//                context.delete(note)
//            }
            saveCoreData()
        } catch {
            print(error)
        }
        
        do {
            storedCalendars = try context.fetch(StoredCalendar.fetchRequest())
            storedCalendars = Array(Set(storedCalendars))
            
            if !storedCalendars.isEmpty {
                for cal in storedCalendars {
                    if let tmp = eventStore.calendar(withIdentifier: cal.identifier!) {
                        calendars.append(tmp)
                    }
                }
                getCalendarEvents()
            } else {
                print("No stored calendars")
            }
        } catch {
            print(error)
        }

    }
    
    func saveCoreData() {
        print("saveCoreData")

        do {
            try context.save()
        } catch {
            print(error)
        }
    }
    
    func updateStoredCalendar(calendars: [EKCalendar]) {
        print("updateStoredCalendar")
        
        for oldCalendar in storedCalendars {
            context.delete(oldCalendar)
        }
        storedCalendars.removeAll()

        for calendar in calendars {
            let newCalendar = StoredCalendar(context: context)
            newCalendar.identifier = calendar.calendarIdentifier
            storedCalendars.append(newCalendar)
        }
        
        saveCoreData()
        
    }
    
}


