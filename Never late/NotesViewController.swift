//
//  NotesViewController.swift
//  Never late
//
//  Created by Elias Kristensson on 2021-04-10.
//

import UIKit
import PencilKit

class NotesViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver, UIScreenshotServiceDelegate {

    let toolPicker = PKToolPicker.init()
    
    //FRÅN EXEMPEL
    static let canvasOverscrollHeight: CGFloat = 500
//    var dataModelController: DataModelController!
    var drawingIndex = 0
    var hasModifiedDrawing = false


    //OUTLETS
    @IBOutlet weak var canvasView: PKCanvasView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
//        canvasView.backgroundColor = .clear
        canvasView.delegate = self
//        canvasView.drawing = dataModelController.drawings[drawingIndex]
        canvasView.bounds = CGRect(x: 597, y: 0, width: 597, height: 1000)
        canvasView.alwaysBounceVertical = false
        canvasView.drawingPolicy = .pencilOnly
        
//        title = dataModelController.titles[drawingIndex]
        
        setupView()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
        super.viewWillDisappear(animated)
        
        // Update the drawing in the data model, if it has changed.
//        dataModelController.updateDrawing(canvasView.drawing, at: drawingIndex)
        
    }
    
    
    
    
    private func setupView() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }
    
}
