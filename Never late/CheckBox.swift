//
//  CheckBox.swift
//  Never late
//
//  Created by Elias Kristensson on 2022-05-07.
//

import UIKit

class CheckBox: UIButton {

    let checkedImage = UIImage(named: "checkboxChecked")
    let uncheckedImage = UIImage(named: "checkboxUnchecked")
    var uuid = ""
//    var item: Item? = nil
    
    var completed: Bool = false {
        didSet{
            print("didSet")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "checkBoxUpdated"), object: self)
            if completed == true {
                self.setImage(checkedImage, for: .normal)
            } else {
                self.setImage(uncheckedImage, for: .normal)
            }
        }
    }
    
    override func awakeFromNib() {
        print("awakeFromNib()")
        self.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        self.completed = false
    }
    
    @objc func buttonClicked(sender: UIButton) {
        if(sender == self) {
            if completed == false {
                completed = true
            } else {
                completed = false
            }
            print(completed)
        }
    }
    

}
