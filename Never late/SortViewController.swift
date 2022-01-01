//
//  SortViewController.swift
//  Never late
//
//  Created by Elias Kristensson on 2021-04-27.
//

import UIKit

class SortViewController: UIViewController {

    var sort: String!
    
    @IBOutlet weak var sortOption: UISegmentedControl!
    
    @IBAction func sortOptionChanged(_ sender: Any) {
        switch sortOption.selectedSegmentIndex {
        case 0:
            sort = "Date modified"
        case 1:
            sort = "Date added"
        default:
            sort = "Date modified"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch sort {
        case "Date modified":
            sortOption.selectedSegmentIndex = 0
        case "Date added":
            sortOption.selectedSegmentIndex = 1
        default:
            sortOption.selectedSegmentIndex = 0
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "sortNotes"), object: self)
    }
    
}
