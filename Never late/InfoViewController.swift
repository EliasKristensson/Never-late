//
//  InfoViewController.swift
//  Never late
//
//  Created by Elias Kristensson on 2021-04-23.
//

import UIKit

class InfoViewController: UIViewController {

    var item: Item!
    var dataManager: DataManager!
    var priorities = ["None", "Low", "Medium", "High"]

    @IBOutlet weak var mainLabel: UITextField!
    @IBOutlet weak var notes: UITextView!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var window: UIView!
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    
    
    @IBAction func clickedOutside(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func eraseItem(_ sender: Any) {
        let alert = UIAlertController(title: "Erase item?", message: "Are you sure you want to delete this item?", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: {action in
            
            if self.item.type == "Calendar" {
                self.dataManager.eraseCalendarItem(item: self.item)
            } else {
                self.dataManager.context.delete(self.item)
                self.dataManager.saveCoreData()
            }
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateItem"), object: self)
            self.dismiss(animated: true, completion: nil)
        } ))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))

        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func updateItem(_ sender: Any) {
        item.title = mainLabel.text
        item.body = notes.text
        item.startDate = startDatePicker.date
        item.endDate = endDatePicker.date
        item.priority = priorities[prioritySelector.selectedSegmentIndex]
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateItem"), object: self)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func priorityChanged(_ sender: Any) {
        item.priority = dataManager.priorityValueToString[prioritySelector.selectedSegmentIndex]
    }
    
    @IBAction func startDateChanged(_ sender: Any) {

        if let prevStartDate = item.startDate {
            
            item.startDate = startDatePicker.date
            
            let delta = item.startDate! - prevStartDate
            print(delta)
            
            if let endDate = item.endDate {
//                let duration = endDate - prevStartDate
                print("HERE")
//                print(duration)
//                print(endDatePicker.date)
                endDatePicker.date = endDate.addingTimeInterval(TimeInterval(delta))
//                print(endDatePicker.date)
            }
        }
        
    }
    
    @IBAction func endDateChanged(_ sender: Any) {
        item.endDate = endDatePicker.date
        
//        if let startDate = item.startDate {
//            if let endDate = item.endDate {
//                if startDate > endDate {
//                    startDatePicker.date = endDatePicker.date.addingTimeInterval(TimeInterval(3600))
//                }
//            }
//        }

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        window.layer.cornerRadius = 15
        window.layer.borderWidth = 1
        window.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)

        print(item)
        
        mainLabel.text = item.title
        notes.text = item.body
        if let startDate = item.startDate {
            startDatePicker.date = startDate
        }
        
        if let endDate = item.endDate {
            endDatePicker.date = endDate
        }
        
        if let priority = item.priority {
            prioritySelector.selectedSegmentIndex = dataManager.priorityStringToValue[priority]! + 1
        } else {
            prioritySelector.selectedSegmentIndex = 0
        }

    }
    


}
