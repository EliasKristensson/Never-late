//
//  AddNewItemViewController.swift
//  Never late
//
//  Created by Elias Kristensson on 2021-03-29.
//

import UIKit
import CoreData
import EventKit
import EventKitUI

class CalendarChooserCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var selectedIcon: UIImageView!
}

enum getType: Int {
    case calendar = 1
    case todo = 2
    case deadline = 3
    case reminder = 4
    
    func value() -> Int {
        return self.rawValue
    }
    
}

class AddNewItemViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var dataManager: DataManager!
    var date: Date? = nil
    var priorityString = "low"
    var selectedCalendar: Int = 0
    var eventStore: EKEventStore? = nil
    var selectedItem: Item? = nil
    var edit: Bool = false
    var selectedType = "Calendar"
    var defaultDurations = [1800, 3600, 7200, 14400, 32400, 86400]
    var alarmTimes = [900, 3600, 7200, 86400, 172800, 604800]
//    let recurrenceString = ["For ever", "1", "2", "3", "4", "5", "6", ]
    
    // OUTLETS
    @IBOutlet weak var type: UISegmentedControl!
    @IBOutlet weak var eventDescription: UITextField!
    @IBOutlet weak var notes: UITextView!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var priority: UISegmentedControl!
    @IBOutlet weak var calendarSelectorTV: UITableView!
    @IBOutlet weak var isAllDayEvent: UISwitch!
    @IBOutlet weak var addToCalendar: UISwitch!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var defaultDuration: UISegmentedControl!
    @IBOutlet weak var addToCalendarView: UIView!
    @IBOutlet weak var hasStartDate: UISwitch!
    @IBOutlet weak var recurringSwitch: UISwitch!
    @IBOutlet weak var eventAlarmSwitch: UISwitch!
    @IBOutlet weak var eventAlarmTimes: UISegmentedControl!
    @IBOutlet weak var numberOfRecurrenceEvents: UIPickerView!
    @IBOutlet weak var allDayView: UIView!
    
    
    // ACTIONS
    @IBAction func saveItem(_ sender: Any) {
        addNewItem()
        navigationController?.popViewController(animated: true)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateView"), object: nil)
    }
    
    @IBAction func typeChanged(_ sender: Any) {
        updateView()
    }
    
    @IBAction func startDateChanged(_ sender: Any) {
        endDatePicker.date = startDatePicker.date.addingTimeInterval(Double(defaultDurations[defaultDuration.selectedSegmentIndex]))
//        if endDatePicker.date <= startDatePicker.date {
//            endDatePicker.date = startDatePicker.date.addingTimeInterval(3600)
//        }
    }
    
    @IBAction func defaultDurationChanged(_ sender: Any) {
        
        endDatePicker.date = startDatePicker.date.addingTimeInterval(Double(defaultDurations[defaultDuration.selectedSegmentIndex]))
    }
    
    @IBAction func allDayChanged(_ sender: Any) {
        if isAllDayEvent.isOn {
            let calendar = Calendar.current
            var selectedDay = calendar.dateComponents([.year, .month, .day], from: startDatePicker.date)
            selectedDay.hour = 00
            selectedDay.minute = 00
            selectedDay.second = 00
                
            startDatePicker.setDate(calendar.date(from: selectedDay)!, animated: false)
            endDatePicker.date = startDatePicker.date.addingTimeInterval(86400)
            defaultDuration.isEnabled = false
            defaultDuration.selectedSegmentIndex = 6
        } else {
            defaultDuration.isEnabled = true
            defaultDuration.selectedSegmentIndex = 1
        }
    }
    
    @IBAction func hasStartDateChanged(_ sender: Any) {
        if hasStartDate.isOn {
            startDatePicker.isEnabled = true
        } else {
            startDatePicker.isEnabled = false
        }
    }
    
    @IBAction func recurringSwitchChanged(_ sender: Any) {
//        recurringOption.isEnabled = recurringSwitch.isOn
        numberOfRecurrenceEvents.isHidden = !recurringSwitch.isOn
//        endRecurrenceDatePicker.isEnabled = recurringSwitch.isOn
    }
    
    @IBAction func eventAlarmSwitchChanged(_ sender: Any) {
        eventAlarmTimes.isEnabled = eventAlarmSwitch.isOn
    }
    
    @IBAction func recurringOptionChanged(_ sender: Any) {
        
    }
    
    
    
    
    // MARK: VIEWDIDLOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        updateView()
        
        calendarSelectorTV.dataSource = self
        calendarSelectorTV.delegate = self
        
        if let date = date {
            startDatePicker.date = date
            endDatePicker.date = date.addingTimeInterval(3600)
        }
        
        
    }
    
    
    
    
    // MARK: FUNCTIONS
    func addNewItem() {
        
        if let itemType = dataManager.typeValueToString[type.selectedSegmentIndex] {
        
            let uuid = UUID().uuidString

            if eventDescription.text == "" {
                
                let alert = UIAlertController(title: "No title", message: "Event title missing", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            } else if itemType == "Calendar" && dataManager.calendars.isEmpty {
                
                let alert = UIAlertController(title: "No calendars", message: "Go back to the main window and add at least one calendar", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            } else {
                
                if itemType == "Reminder" {
                    
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { success, error in
                        if success {
                            DispatchQueue.main.async {
                                let content = UNMutableNotificationContent()
                                content.sound = .default
                                content.title = self.eventDescription.text ?? "My title"
                                content.body = self.notes.text ?? ""
                                let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self.startDatePicker.date), repeats: false)
                                let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)
                                UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
                                    print("Funkade")
                                })
                            }
                        } else {
                            print("Could not add reminder")
                        }
                    })
                }
                
                let newItem = Item(context: dataManager.context)
                newItem.added = Date()
                newItem.active = true
                newItem.title = eventDescription.text
                newItem.body = notes.text
                newItem.type = itemType
                newItem.priority = dataManager.priorityValueToString[priority.selectedSegmentIndex]
                newItem.isAllDay = isAllDayEvent.isOn
                newItem.trash = false
                newItem.id = uuid
                newItem.alert = eventAlarmSwitch.isOn
                newItem.recurring = recurringSwitch.isOn
                newItem.completed = false
                
                if eventAlarmSwitch.isOn {
                    newItem.alertTime = Double(alarmTimes[eventAlarmTimes.selectedSegmentIndex])
                }
                
                if hasStartDate.isOn {
                    newItem.startDate = startDatePicker.date
                    newItem.endDate = endDatePicker.date
                } else {
                    newItem.startDate = nil
                    newItem.endDate = nil
                }
                
                if newItem.type != "Calendar" {
                    dataManager.items.append(newItem)
                    if addToCalendar.isOn {
                        print("FIX: ADD TO CALENDAR")
                    }
                } else {
                    if !dataManager.calendars.isEmpty {

                        if recurringSwitch.isOn {
                            dataManager.recurranceRule = setRecurringRule()
                        }
                        
                        newItem.calendarTitle = dataManager.calendars[selectedCalendar].title
                        newItem.calendarId = dataManager.calendars[selectedCalendar].calendarIdentifier
                        dataManager.addItemToCalendar(item: newItem)
                    }
                }
                
                dataManager.saveCoreData()
                
            }
        }
            
        
    }
    
    func setRecurringRule() -> EKRecurrenceRule {
        
        var repeatedEvents: Int = numberOfRecurrenceEvents.selectedRow(inComponent: 1)
        if repeatedEvents == 0 {
            repeatedEvents = 500
        }
        
        switch numberOfRecurrenceEvents.selectedRow(inComponent: 0) {
        case 0:
            let recurrenceRule = EKRecurrenceRule.init(
                recurrenceWith: .daily,
                interval: 1,
                daysOfTheWeek: nil,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: .init(occurrenceCount: repeatedEvents)
            )
            return recurrenceRule
            
        case 1:
            let recurrenceRule = EKRecurrenceRule.init(
                recurrenceWith: .weekly,
                interval: 1,
                daysOfTheWeek: nil,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: .init(occurrenceCount: repeatedEvents)
            )
            return recurrenceRule
            
        case 2:
            let recurrenceRule = EKRecurrenceRule.init(
                recurrenceWith: .weekly,
                interval: 2,
                daysOfTheWeek: nil,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: .init(occurrenceCount: repeatedEvents)
            )
            return recurrenceRule
            
        case 3:
            let recurrenceRule = EKRecurrenceRule.init(
                recurrenceWith: .monthly,
                interval: 1,
                daysOfTheWeek: nil,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: .init(occurrenceCount: repeatedEvents)
            )
            return recurrenceRule
            
        case 4:
            let recurrenceRule = EKRecurrenceRule.init(
                recurrenceWith: .yearly,
                interval: 1,
                daysOfTheWeek: nil,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: .init(occurrenceCount: repeatedEvents)
            )
            return recurrenceRule
            
        default:
            let recurrenceRule = EKRecurrenceRule.init(
                recurrenceWith: .weekly,
                interval: 1,
                daysOfTheWeek: [EKRecurrenceDayOfWeek.init(EKWeekday.saturday)],
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: .init(occurrenceCount: numberOfRecurrenceEvents.selectedRow(inComponent: 0)) //EKRecurrenceEnd.init(end:endDate)
            )
            return recurrenceRule
        }
        
        
    }
    
    func setupView() {
                
        eventAlarmTimes.isEnabled = eventAlarmSwitch.isOn
//        recurringOption.isEnabled = recurringSwitch.isOn
//        endRecurrenceDatePicker.isEnabled = recurringSwitch.isOn
        numberOfRecurrenceEvents.isHidden = !recurringSwitch.isOn
        
        switch selectedType {
        case "Calendar":
            type.selectedSegmentIndex = 0
        case "Todo":
            type.selectedSegmentIndex = 1
        case "Deadline":
            type.selectedSegmentIndex = 2
        case "Reminder":
            type.selectedSegmentIndex = 3
        default:
            type.selectedSegmentIndex = 0
        }
        
        defaultDuration.selectedSegmentIndex = 1
        
        if selectedItem != nil && edit {
            eventDescription.text = selectedItem?.title
            notes.text = selectedItem?.body
            startDatePicker.date = (selectedItem?.startDate)!
            endDatePicker.date = (selectedItem?.endDate)!
        } else {
            eventDescription.text = ""
            notes.text = ""
            startDatePicker.date = Date()
            endDatePicker.date = Date().addingTimeInterval(3600)
        }
     
        addToCalendarView.layer.cornerRadius = 10
        addToCalendarView.layer.borderWidth = 1
        addToCalendarView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        allDayView.layer.cornerRadius = 10
        allDayView.layer.borderWidth = 1
        allDayView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        eventDescription.becomeFirstResponder()
    }
    
    func updateView() {
        
        switch dataManager.typeValueToString[type.selectedSegmentIndex] {
            
        case "Calendar":
            
            if dataManager.calendars.isEmpty {
                
                let alert = UIAlertController(title: "No calendars", message: "Go back to the main window and add at least one calendar", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            } else {
                
                endDatePicker.isEnabled = true
                startDateLabel.text = "Start date"
                endDateLabel.text = "End date"
                defaultDuration.isEnabled = true
                calendarSelectorTV.layer.opacity = 1
                addToCalendar.isOn = true
                addToCalendarView.layer.opacity = 0.5
                allDayView.layer.opacity = 1
                priority.layer.opacity = 0.5
            }
            
        case "To do":
            addToCalendar.isOn = false
            endDatePicker.isEnabled = false
            startDateLabel.text = "Due date?"
            endDateLabel.text = " "
            defaultDuration.isEnabled = false
            calendarSelectorTV.layer.opacity = 0.5
            addToCalendarView.layer.opacity = 1
            allDayView.layer.opacity = 0.5
            priority.layer.opacity = 1
            
        case "Deadline":
            endDatePicker.isEnabled = false
            startDateLabel.text = "Due date?"
            endDateLabel.text = " "
            defaultDuration.isEnabled = false
            calendarSelectorTV.layer.opacity = 1
            addToCalendar.isOn = false
            addToCalendarView.layer.opacity = 1
            allDayView.layer.opacity = 0.5
            priority.layer.opacity = 1
            
        case "Reminder":
            endDatePicker.isEnabled = false
            startDateLabel.text = "Due date?"
            endDateLabel.text = " "
            defaultDuration.isEnabled = false
            calendarSelectorTV.layer.opacity = 0.5
            addToCalendar.isOn = false
            addToCalendarView.layer.opacity = 1
            allDayView.layer.opacity = 0.5
            priority.layer.opacity = 1
            
        default:
            print("Default 2")
        }
    }
    
    
    //MARK: PICKERVIEW
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 5
        } else {
            return 50
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            let options = ["Daily", "Weekly", "2 weeks", "Monthly", "Yearly"]
            return options[row]
        } else {
            if row == 0 {
                return "For ever"
            } else {
                return "\(row+1)"
            }
        }
    }
    
    
    // MARK: TABLEVIEW
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager.calendars.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "calendarChooserCell") as! CalendarChooserCell
        cell.title.text = dataManager.calendars[indexPath.row].title
        cell.selectedIcon.tintColor = UIColor(cgColor: dataManager.calendars[indexPath.row].cgColor)
        if selectedCalendar == indexPath.row {
            cell.selectedIcon.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            cell.selectedIcon.image = UIImage(systemName: "circle")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCalendar = indexPath.row
        
        print(dataManager.calendars[selectedCalendar])
        
        DispatchQueue.main.async {
            self.calendarSelectorTV.reloadData()
        }
    }

    
   
    

}
