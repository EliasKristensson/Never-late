//
//  FilterViewController.swift
//  Never late
//
//  Created by Elias Kristensson on 2021-04-30.
//

import UIKit

class FilterViewController: UIViewController {

    var category: String!
    var search: String?
    let categories = ["All", "Weekly note", "Meeting", "User defined"]
    
    @IBOutlet weak var searchString: UITextField!
    @IBOutlet weak var categorySelector: UISegmentedControl!
    
    @IBAction func categorySelectorChanged(_ sender: Any) {
        if categorySelector.selectedSegmentIndex == 3 {
            searchString.becomeFirstResponder()
        }
    }
    
    @IBAction func applyFilter(_ sender: Any) {
        category = categories[categorySelector.selectedSegmentIndex]
        if searchString.text != "" {
            search = nil
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "filterNotes"), object: self)
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categorySelector.selectedSegmentIndex = 0
        searchString.text = ""
    }
    

}
