//
//  NewNoteOptionsViewController.swift
//  Never late
//
//  Created by Elias Kristensson on 2021-04-25.
//

import UIKit

class NewNoteOptionsViewController: UIViewController {

    let weekNumber = Calendar.current.component(.weekOfYear, from: Date())
    let year = Calendar.current.component(.year, from: Date())
    let month = Calendar.current.component(.month, from: Date())
    let day = Calendar.current.component(.day, from: Date())
    var makeNote: Bool = false
    var category = "Weekly note"
    
    @IBOutlet weak var categoryController: UISegmentedControl!
    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var userCategory: UITextField!
    
    
    @IBAction func categoryChanged(_ sender: Any) {
        switch categoryController.selectedSegmentIndex {
        case 0:
            noteTitle.isEnabled = false
            noteTitle.text = "Weekly note: " + "\(weekNumber)" + " " + "\(year)"
        case 1:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, YYYY"
            noteTitle.isEnabled = true
            noteTitle.text = "New meeting note: " + formatter.string(from: Date())
        case 2:
            noteTitle.isEnabled = true
            noteTitle.text = "New note"
        default:
            noteTitle.isEnabled = false
            noteTitle.text = "Weekly note: " + "\(weekNumber)" + " " + "\(year)"
        }
    }
    
    @IBAction func makeNoteTapped(_ sender: Any) {
        makeNote = true
        switch categoryController.selectedSegmentIndex {
        case 0:
            category = "Weekly note"
        case 1:
            category = "Meeting"
        case 2:
            if userCategory.text == nil || userCategory.text == "" {
                category = "Miscellaneous"
            } else {
                category = userCategory.text!
            }
        default:
            category = "Weekly note"
        }
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addNewNote"), object: self)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        noteTitle.isEnabled = false
        noteTitle.text = "Weekly note: " + "\(weekNumber)" + " " + "\(year)"
        
    }
    
}
