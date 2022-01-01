//
//  LoadingViewController.swift
//  Never late
//
//  Created by Elias Kristensson on 2021-03-30.
//

import UIKit
import PDFKit
import CoreData
import CloudKit


class LoadingViewController: UIViewController, DrawingModelControllerObserver {
    

//    var appDelegate: AppDelegate!
    var icloudAvailable: Bool!
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var privateDatabase: CKDatabase?
    let container = CKContainer.default
    var recordZone: CKRecordZone?
    var dataManager = DataManager()
    var drawingModelController = DrawingModelController()


    override func viewDidLoad() {
        print("loading view loaded")
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        dataManager.context = context
        drawingModelController.observers.append(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! ViewController
        destination.dataManager = dataManager
        destination.drawingModelController = drawingModelController
    }
    
    
    func drawingModelChanged() {
        performSegue(withIdentifier: "segueMainVC", sender: self)
        drawingModelController.observers.removeAll()
    }
    

    
}
