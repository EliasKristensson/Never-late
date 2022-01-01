import UIKit
import EventKit
import EventKitUI
import PencilKit
import PhotosUI

class MonthCalendarCell: UICollectionViewCell {
    
    var events: [EKEvent]?
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var eventsTV: UITableView!
    
}

class EventCell: UITableViewCell {
    
    var events: [Item]?
    
    @IBOutlet weak var eventLabel: UILabel!
    
}

//class FullNoteCVCell: UICollectionViewCell {
//    var dateAdded: Date!
//
//    @IBOutlet weak var canvasView: PKCanvasView!
//    
//}


class FullCalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegateFlowLayout, UITextViewDelegate, DrawingModelControllerObserver, PKCanvasViewDelegate, PKToolPickerObserver, UIScreenshotServiceDelegate {
    
    var drawingModelController: DrawingModelController!
    var totalSquaresInMonthCalendar = [String]()
    var selectedDate = Date()
    let toolPicker = PKToolPicker.init()
    var selectedNote: NoteItem? = nil
    var dataManager: DataManager!
    let calendar = Calendar.current
    var blanks = Int()
    var datesInView = [Date]()
    var noteBackground = UIImage(named: "dots2.png")
    var pageNumber = 0
    var noteID: Date!
    var selectedType: Int = 0
    var saveTimer: Timer!
    var zoom: CGRect!
    
    @IBOutlet weak var calendarCV: UICollectionView!
    @IBOutlet weak var mainDateLabel: UILabel!
    @IBOutlet weak var notesCV: UICollectionView!
    @IBOutlet weak var prevPageButton: UIButton!
    @IBOutlet weak var nextPageButton: UIButton!
    @IBOutlet weak var typeSelector: UISegmentedControl!
    @IBOutlet weak var noteBackgroundController: UISegmentedControl!
    @IBOutlet weak var saveToCameraRollButton: UIBarButtonItem!
    
    
    
    
    @IBAction func nextMonthPressed(_ sender: Any) {
        selectedDate = CalendarModel().plusMonth(date: selectedDate)
        setMonthView()
    }
    
    @IBAction func nextPagePressed(_ sender: Any) {
        goToNextPage()
    }
    
    @IBAction func prevPagePressed(_ sender: Any) {
        goToPrevPage()
    }
    
    @IBAction func prevMonthPressed(_ sender: Any) {
        selectedDate = CalendarModel().minusMonth(date: selectedDate)
        setMonthView()
    }
    
    @IBAction func typeChanged(_ sender: Any) {
        
        selectedType = typeSelector.selectedSegmentIndex
        
        if typeSelector.selectedSegmentIndex == 0 {
            title = "Calendar view"
            calendarCV.reloadData()
            calendarCV.isHidden = false
            notesCV.isHidden = true
            closeCurrentNote()
        } else {
            if self.selectedNote != nil {
                title = "Note view"
                notesCV.reloadData()
                calendarCV.isHidden = true
                notesCV.isHidden = false
                nextPageButton.isHidden = false
                prevPageButton.isHidden = false
            } else {
                let alert = UIAlertController(title: "No selected note", message: "Go back to main menu and select a note.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)

                typeSelector.selectedSegmentIndex = 0
            }
        }
    }
    
    @IBAction func noteBackgroundChanged(_ sender: Any) {
        switch noteBackgroundController.selectedSegmentIndex {
        case 0:
            noteBackground = UIImage(named: "dots2.png")
        case 1:
            noteBackground = UIImage(named: "lines-large.png")
        case 2:
            noteBackground = nil
        default:
            noteBackground = UIImage(named: "dots2.png")
        }
        updateNote(hideToolpicker: false)
        notesCV.reloadData()
    }
    
    @IBAction func saveToCameraRollPressed(_ sender: Any) {
        print("saveToCameraRollPressed()")
        
        self.updateAndSaveNote(updateThumbnails: false, hideToolpicker: false)
        self.setSelectedNote(id: self.selectedNote!.dateAdded)
        
        if let cell = self.notesCV.cellForItem(at: IndexPath(row: pageNumber, section: 0)) as? FullNoteCVCell {
            let size = CGSize(width: self.notesCV.bounds.width, height: self.notesCV.bounds.height)
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            cell.canvasView.drawHierarchy(in: cell.canvasView.bounds, afterScreenUpdates: true)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if image != nil {
                PHPhotoLibrary.shared().performChanges ( {
                    PHAssetChangeRequest.creationRequestForAsset(from: image!)
                }, completionHandler: { (success, error) in
                    if success {
                        AudioServicesPlaySystemSound(1001)
                        print("Saved " + "\(self.pageNumber)" + " to camera roll")
                    }
                })
            } else {
                print("Image is nil")
            }
        } else {
            print("Could not access NoteCV cell")
        }
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        print("FullCalendarViewController viewDidLoad()")
        
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        
        calendarCV.isScrollEnabled = false
        notesCV.isScrollEnabled = false

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(swipe:)))
        swipeUp.direction = .up
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(swipe:)))
        swipeDown.direction = .down
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(swipe:)))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(swipe:)))
        swipeLeft.direction = .left
        
        saveTimer = Timer.scheduledTimer(timeInterval: 120, target: self, selector: #selector(updateAndSaveNote), userInfo: nil, repeats: true)

        calendarCV.addGestureRecognizer(swipeRight)
        calendarCV.addGestureRecognizer(swipeLeft)
        notesCV.addGestureRecognizer(swipeUp)
        notesCV.addGestureRecognizer(swipeDown)
        
        setMonthView()
        setSelectedNote(id: noteID)
        
        typeSelector.selectedSegmentIndex = selectedType
        
        if typeSelector.selectedSegmentIndex == 0 {
            calendarCV.isHidden = false
            notesCV.isHidden = true
            prevPageButton.isHidden = true
            nextPageButton.isHidden = true
            title = "Calender view"
        } else {
            prevPageButton.isHidden = false
            nextPageButton.isHidden = false
            calendarCV.isHidden = true
            title = "Note view"
            openNote()
        }
    }
    
    
    
    //MARK: OBJC FUNCTIONS
    @objc func swipeAction(swipe: UISwipeGestureRecognizer) {
        switch swipe.direction {
        case .left:
            if typeSelector.selectedSegmentIndex == 0 {
                selectedDate = CalendarModel().plusMonth(date: selectedDate)
                setMonthView()
            }
        case .right:
            if typeSelector.selectedSegmentIndex == 0 {
                selectedDate = CalendarModel().minusMonth(date: selectedDate)
                setMonthView()
            }
        case .down:
            if typeSelector.selectedSegmentIndex == 1 {
                goToPrevPage()
            }
        case .up:
            if typeSelector.selectedSegmentIndex == 1 {
                goToNextPage()
            }
        default:
            print("Default")
        }
        
    }
    
    @objc func updateAndSaveNote(updateThumbnails: Bool, hideToolpicker: Bool) {
        print("updateAndSaveNote()")
        
        updateNote(hideToolpicker: hideToolpicker)
        drawingModelController.update = updateThumbnails
        drawingModelController.saveDrawingModel()
    }
    
    
    
    
    //MARK: FUNCTIONS
    private func closeCurrentNote() {
        print("closeCurrentNote()")
        
        if selectedNote != nil {
            updateAndSaveNote(updateThumbnails: true, hideToolpicker: true)
        }
        
        notesCV.isHidden = true
        prevPageButton.isHidden = true
        nextPageButton.isHidden = true
        noteBackgroundController.isEnabled = false
        saveToCameraRollButton.isEnabled = false
        
    }
    
    func drawingModelChanged() {
        print("drawingModelChanged() in FullCalendarViewController")
        
        if selectedNote != nil {
            setSelectedNote(id: selectedNote!.dateAdded)
        }
        
    }
    
    func getDay(day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = selectedDate.get(.year)
        dateComponents.month = selectedDate.get(.month)
        dateComponents.day = day
        let date = calendar.date(from: dateComponents)
        return date!
    }
    
    func goToNextPage() {
        print("goToNextPage()")
        
        // SPARAR DRAWING MAN LÄMNAR
        updateAndSaveNote(updateThumbnails: false, hideToolpicker: false)
        setSelectedNote(id: selectedNote!.dateAdded)
//        self.notesCV.reloadData()
        
        pageNumber = pageNumber + 1
        // GÅR TILL NÄSTA DRAWING
        if nextPageButton.currentImage == UIImage(systemName: "arrow.forward.circle.fill") {
            if pageNumber >= selectedNote!.drawings.count - 1 {
                nextPageButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            }
        } else {
            drawingModelController.newSubDrawing(mainIndex: selectedNote!.index)
            setSelectedNote(id: drawingModelController.dateAdded[selectedNote!.index])
            notesCV.reloadData() //FUNKAR DETTA?
        }
        
        // DET FINNS FÖREGÅENDE NOTE
        prevPageButton.isHidden = false
        
//        self.notesCV.reloadData() //ANNARS TAPPAR DEN SAKER MAN SKRIVIT????
        self.notesCV.reloadItems(at: [IndexPath(row: pageNumber, section: 0)])
        self.notesCV.scrollToItem(at: IndexPath(row: pageNumber, section: 0), at: .top, animated: true)
    }

    private func goToPrevPage() {
        print("goToPrevPage()")
        
        if pageNumber > 0 {
            // SPARAR DRAWING MAN LÄMNAR
            updateAndSaveNote(updateThumbnails: false, hideToolpicker: false)
            
            // DET FINNS EN DRAWING EFTER, ÄNDRA IKON
            nextPageButton.setImage(UIImage(systemName: "arrow.forward.circle.fill"), for: .normal)
            
            pageNumber = pageNumber - 1
            // GÅR TILL FÖRRA DRAWING
            if pageNumber < 0 {
                pageNumber = 0
            }
            
            if pageNumber == 0 {
                prevPageButton.isHidden = true
            }
            
            self.notesCV.reloadItems(at: [IndexPath(row: pageNumber, section: 0)]) //TESTAR BARA LADDA OM KOMMANDE
            self.notesCV.scrollToItem(at: IndexPath(row: pageNumber, section: 0), at: .centeredVertically, animated: true)
        }
    }
    
    private func openNote() {
        print("openNote()")
        
        notesCV.isHidden = false
        notesCV.backgroundColor = .white
        notesCV.reloadData()
        
        view.bringSubviewToFront(notesCV)
        view.bringSubviewToFront(nextPageButton)
        view.bringSubviewToFront(prevPageButton)
        
        if selectedNote!.drawings.count > 1 {
            nextPageButton.setImage(UIImage(systemName: "arrow.forward.circle.fill"), for: .normal)
        } else {
            nextPageButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        }
        
        nextPageButton.isHidden = false
        prevPageButton.isHidden = true
        noteBackgroundController.isEnabled = true
//        saveToCameraRollButton.isEnabled = true
        
        pageNumber = 0
        self.notesCV.scrollToItem(at: IndexPath(row: pageNumber, section: 0), at: .top, animated: true)
        
    }
    
    func scaleTransform(for view: UIView, scaledBy scale: CGPoint, aroundAnchorPoint relativeAnchorPoint: CGPoint) -> CGAffineTransform {
        let bounds = view.bounds
        let anchorPoint = CGPoint(x: bounds.width * relativeAnchorPoint.x, y: bounds.height * relativeAnchorPoint.y)
        return CGAffineTransform.identity
            .translatedBy(x: anchorPoint.x, y: anchorPoint.y)
            .scaledBy(x: scale.x, y: scale.y)
            .translatedBy(x: -anchorPoint.x, y: -anchorPoint.y)
    }
    
    func setMonthView() {
        print("setMonthView()")
        
        totalSquaresInMonthCalendar.removeAll()
        datesInView.removeAll()
        
        let daysInMonth = CalendarModel().daysInMonth(date: selectedDate)
        let firstDayOfMonth = CalendarModel().firstOfMonth(date: selectedDate)
        blanks = CalendarModel().weekday(date: firstDayOfMonth)
        
        var count: Int = 1
        
        while(count <= 42) {
            var components = calendar.dateComponents([.month, .year], from: selectedDate)
            components.day = count-blanks
            let date = calendar.date(from: components)!
            datesInView.append(date)

            if (count <= blanks || count - blanks > daysInMonth) {
                totalSquaresInMonthCalendar.append("")
            } else {
                totalSquaresInMonthCalendar.append(String(count-blanks))
            }
            
            count += 1
        }
        
        mainDateLabel.text = CalendarModel().monthString(date: selectedDate) + " " + CalendarModel().yearString(date: selectedDate)
        title = "Calendar view"
        
        calendarCV.reloadData()
    }
    
    func setSelectedNote(id: Date) {
        if let index = drawingModelController.dateAdded.firstIndex(where: {$0 == id} ) {
            let tmp = NoteItem(drawings: drawingModelController.drawings[index], title: drawingModelController.titles[index], dateAdded: drawingModelController.dateAdded[index], dateModified: drawingModelController.dateModified[index], category: drawingModelController.categories[index], thumbnail: drawingModelController.thumbnails[index], index: index)
            selectedNote = tmp
        } else {
            selectedNote = nil
        }
    }
    
    private func updateNote(hideToolpicker: Bool) {
        print("updateNote()")
        
        if !notesCV.isHidden {
            if let cell = notesCV.cellForItem(at: IndexPath(row: pageNumber, section: 0)) as? FullNoteCVCell {
                if let index = drawingModelController.dateAdded.firstIndex(where: { $0 == cell.dateAdded }) {
                    drawingModelController.updateDrawing(cell.canvasView.drawing, at: index, at: pageNumber)
                    if hideToolpicker {
                        print("Hiding toolpicker")
                        toolPicker.setVisible(false, forFirstResponder: cell.canvasView)
                    }
                }
            }
        }
    }
    
    
    
    // MARK: UI INTERFACE
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if UIDevice.current.orientation.isLandscape {
            updateAndSaveNote(updateThumbnails: true, hideToolpicker: true)
//            updateNote(hideToolpicker: true)

            if saveTimer != nil {
                saveTimer.invalidate()
            }

            navigationController?.popViewController(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fullCalendarViewClosed"), object: self)
        }
    }

    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var components = calendar.dateComponents([.month, .year], from: selectedDate)
        components.day = tableView.tag
        let date = calendar.date(from: components)!

        let events = dataManager.getCalendarEventsOn(day: date)
        if events != nil {
            return events!.count
        } else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! EventCell
        
        var components = calendar.dateComponents([.month, .year], from: selectedDate)
        components.day = tableView.tag
        let date = calendar.date(from: components)!
        let events = dataManager.getCalendarEventsOn(day: date)
        
        if events != nil {
            cell.backgroundColor = dataManager.getCalendarColor(calendarId: events![indexPath.row].calendar.calendarIdentifier)
            cell.eventLabel.text = events![indexPath.row].title
            cell.eventLabel.textColor = .black
            cell.layer.cornerRadius = 5
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20
    }

    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.calendarCV {
            return totalSquaresInMonthCalendar.count
        } else {
            if self.selectedNote != nil {
                return self.selectedNote!.drawings.count
            } else {
                return 0
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.calendarCV {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "monthCalendarCell", for: indexPath) as! MonthCalendarCell
            
            let todayComponents = calendar.dateComponents([.day, .month, .year], from: Date())
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d"
            
            cell.dateLabel.text = dateFormatter.string(from: datesInView[indexPath.row])
            
            if datesInView[indexPath.row].get(.month) == selectedDate.get(.month) {
                
                cell.layer.borderWidth = 0.25
                cell.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
                cell.dateLabel.layer.borderColor = nil
                
                let dayComponents = calendar.dateComponents([.day, .month, .year], from: datesInView[indexPath.row])
                let day = calendar.date(from: dayComponents)
                let today = calendar.date(from: todayComponents)
                
                if day == today {
                    cell.dateLabel.layer.cornerRadius = cell.dateLabel.bounds.width/2
                    cell.dateLabel.layer.borderWidth = 1
                    cell.dateLabel.layer.backgroundColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
                    cell.dateLabel.textColor = .white
                    cell.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.25)
                } else {
                    cell.dateLabel.layer.backgroundColor = .none
                    cell.dateLabel.layer.borderWidth = 0
                    cell.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
                }
            } else {
                cell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
                cell.layer.borderWidth = 0
                cell.layer.borderColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
                cell.dateLabel.layer.borderWidth = 0
                cell.dateLabel.layer.backgroundColor = .none
            }
            
            cell.eventsTV.backgroundColor = .clear
            cell.eventsTV.tag = indexPath.row-blanks+1
            cell.eventsTV.reloadData()
            
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "noteCVCellFullView", for: indexPath) as! FullNoteCVCell
            
            if !collectionView.isHidden {
                
                var subviewAdded = false
                for i in 0..<cell.canvasView.subviews.count {
                    if cell.canvasView.subviews[i].tag == 123 {
                        subviewAdded = true
                        let view = cell.canvasView.subviews[i] as! UIImageView
                        view.image = noteBackground
                    }
                }
                
                let backgroundImage = UIImageView(image: noteBackground)
                
                cell.dateAdded = selectedNote!.dateAdded
//                cell.canvasView.layer.cornerRadius = 10
                cell.canvasView.drawing = PKDrawing()
                cell.canvasView.minimumZoomScale = 1 //notesCV.bounds.width/zoom.width
                cell.canvasView.maximumZoomScale = 5
                cell.canvasView.delegate = self
                cell.canvasView.backgroundColor = .clear
                cell.canvasView.isOpaque = false
                cell.canvasView.drawingPolicy = .anyInput // .pencilOnly
                cell.canvasView.drawing = selectedNote!.drawings[indexPath.row]
                
                if !subviewAdded {
                    backgroundImage.contentMode = .scaleToFill
                    backgroundImage.frame = cell.canvasView.bounds
                    backgroundImage.tag = 123
                    backgroundImage.translatesAutoresizingMaskIntoConstraints = false
                    backgroundImage.autoresizingMask = [.flexibleBottomMargin, .flexibleHeight, .flexibleWidth, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
                    backgroundImage.backgroundColor = .white
                    cell.canvasView.insertSubview(backgroundImage, at: 0)
                }
                
                cell.canvasView.zoomScale = cell.canvasView.minimumZoomScale
                
            }
            
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
     
        if collectionView == self.calendarCV {
            return CGSize(width: calendarCV.bounds.width/7, height: calendarCV.bounds.height/6)
        } else {
            return CGSize(width: notesCV.bounds.width, height: notesCV.bounds.height)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        if collectionView == notesCV {
            if let tmp = cell as? FullNoteCVCell {
                if !collectionView.isHidden {
                    print("Setting toolpicker visible")
                    toolPicker.setVisible(true, forFirstResponder: tmp.canvasView)
                    tmp.canvasView.becomeFirstResponder()
                    toolPicker.addObserver(tmp.canvasView)
                    //tmp.canvasView.drawingPolicy // HUR ÄNDRAR JAG DENNA?
                }
            }
        }
        
    }

    
    //MARK: CANVASVIEW
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        print("canvasViewDrawingDidChange()")
        updateNote(hideToolpicker: false)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        for subview in scrollView.subviews {
            if subview.tag == 123 {
                subview.setAnchorPoint(CGPoint(x: 0, y: 0))
                let transformZoom = scaleTransform(for: subview, scaledBy: CGPoint(x: scrollView.zoomScale, y: scrollView.zoomScale), aroundAnchorPoint: subview.layer.anchorPoint)
                subview.transform = transformZoom
            }
        }
    }
    

}
