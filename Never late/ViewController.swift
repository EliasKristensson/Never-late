//
//  ViewController.swift
//  Never late
//
//  Created by Elias Kristensson on 2021-03-27.
//

import UIKit
import CoreData
import EventKit
import EventKitUI
import PencilKit
import PhotosUI


class FullNoteCVCell: UICollectionViewCell {
    var dateAdded: Date!

    @IBOutlet weak var canvasView: PKCanvasView!
    
}

class FullCalendarCell: UICollectionViewCell {
    
    var id = "fullCalendarCell"
    var events: [EKEvent]?
    
    @IBOutlet weak var eventsTV: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    
}

class FullCalendarEventCell: UITableViewCell {
    
    var events: [Item]?
    
    @IBOutlet weak var eventLabel: UILabel!
    
}


class NSAttributedStringHelper {
    static func createBulletedList(fromStringArray strings: [String], font: UIFont? = nil) -> NSAttributedString {

        let fullAttributedString = NSMutableAttributedString()
        let attributesDictionary: [NSAttributedString.Key: Any]

        if font != nil {
            attributesDictionary = [NSAttributedString.Key.font: font!]
        } else {
            attributesDictionary = [NSAttributedString.Key: Any]()
        }

        for index in 0..<strings.count {
            let bulletPoint: String = "\u{2022}"
            var formattedString: String = "\(bulletPoint) \(strings[index])"

            if index < strings.count - 1 {
                formattedString = "\(formattedString)\n"
            }
            
            let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: formattedString, attributes: attributesDictionary)
            let paragraphStyle = NSAttributedStringHelper.createParagraphAttribute()
            attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSMakeRange(0, attributedString.length))
            fullAttributedString.append(attributedString)
        }

        return fullAttributedString
    }

    private static func createParagraphAttribute() -> NSParagraphStyle {
        let paragraphStyle: NSMutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 15, options: NSDictionary() as! [NSTextTab.OptionKey : Any])]
        paragraphStyle.defaultTabInterval = 15
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 11
        return paragraphStyle
    }
}

class NoteCell: UITableViewCell {
    var dateAdded: Date!

    @IBOutlet weak var thumbNail: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var category: UILabel!
    @IBOutlet weak var dateString: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbNail.layer.borderWidth = 0.25
        thumbNail.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        
//        thumbNail.layer.shadowPath = UIBezierPath(rect: thumbNail.bounds).cgPath
//        thumbNail.layer.shadowOpacity = 0.2
//        thumbNail.layer.shadowOffset = CGSize(width: 0, height: 3)
//        thumbNail.clipsToBounds = false

    }
}

class SpecialCharacterCVCell: UICollectionViewCell
{
    @IBOutlet weak var character: UILabel!
    
}

class NoteCVCell: UICollectionViewCell {
    var dateAdded: Date!

    @IBOutlet weak var canvasView: PKCanvasView!
    
}

class CalenderCell: UICollectionViewCell {
    
    var id = "calendarCell"
    var events: [Item]?
    
    @IBOutlet weak var weekday: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var calenderEventTV: UITableView!
    @IBOutlet weak var weekNumber: UILabel!
    
}


class ListCell: UITableViewCell {
    
    var list: List!
    
    @IBOutlet weak var title: UILabel!
    
}

class ItemCell: UITableViewCell {
    
    var event: Item!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var tickBox: UIButton!
}

class CalenderEventCell: UITableViewCell {
    
    var event: Item!
    
    @IBOutlet weak var eventInformation: UILabel!
    @IBOutlet weak var eventStartTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

struct NoteItem {
    var drawings: [PKDrawing]
    var title: String
    var dateAdded: Date
    var dateModified: Date
    var category: String
    var thumbnail: UIImage
    var index: Int
}

struct Filter {
    var category: String
    var text: String?
}

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegateFlowLayout, UITextViewDelegate, DrawingModelControllerObserver, PKCanvasViewDelegate, PKToolPickerObserver, UIScreenshotServiceDelegate, UISceneDelegate {
    
    
    var dataManager = DataManager()
    var appDelegate: AppDelegate!
    
    var currentDay = Calendar.current.component(.day, from: Date())
    var currentDayOfWeek = Calendar.current.component(.weekday, from: Date())-1

    var currentMonth = Calendar.current.component(.month, from: Date())
    var currentYear = Calendar.current.component(.year, from: Date())
    var numberOfDaysInMonth = 31
    var weekNumber = Int()
    var numberOfDays = 14
    var selectedDate = Date()
        
    var items: [Item] = []
    
    var refreshTimer: Timer!
    var saveTimer: Timer!
    var updateTimer: Timer!
    
    var expandedType = "Todo"
    var sortOption = "Date added"
    var noteIndex: [Int] = []
    var notes = [NoteItem]()
    var todos = [Item]()
    var deadlines = [Item]()
    var reminders = [Item]()
    var filter = Filter(category: "All", text: nil)
    
    let eventStore = EKEventStore()
    var accessToCalendars = false
    var selectedItem: Item? = nil
    var selectedList: List? = nil
    var edit: Bool = false
    var selectedTypeAtFullView: Int = 0
    var counter = 0
    var screenDimensions = UIScreen.main.bounds
    
    
    //NOTES
    var notesFullScreen = false
    let toolPicker = PKToolPicker.init()
    var toolPickerIsActive = false
    var selectedNote: NoteItem? = nil
    var drawingModelController = DrawingModelController()
    var drawingIndex = [0, 0]
    var pageNumber = 0
    var noteBackground = UIImage(named: "dots.png")

    
    //CALENDER
    var blanks = Int()
    var datesInView = [Date]()
    var calendarFullScreen = false
    var totalSquaresInMonthCalendar = [String]()
    let calendar = Calendar.current
    
    
    
    @IBOutlet weak var toDoView: UIView!
    @IBOutlet weak var toDoTV: UITableView!
    @IBOutlet weak var deadlineTV: UITableView!
    @IBOutlet weak var calenderCV: UICollectionView!
    @IBOutlet weak var deadlineView: UIView!
    @IBOutlet weak var listView: UIView!
    @IBOutlet weak var remindersView: UIView!
    @IBOutlet weak var listTV: UITableView!
    @IBOutlet weak var listsView: UIView!
    @IBOutlet weak var listLabel: UITextField!
    @IBOutlet weak var listTextField: UITextView!
    @IBOutlet weak var notesTV: UITableView!
    @IBOutlet weak var notesView: UIView!
    @IBOutlet weak var expandedNotesView: UIView!
    @IBOutlet weak var expandedNotesTV: UITableView!
    @IBOutlet weak var remindersTV: UITableView!
    @IBOutlet weak var numberOfWeeksChooser: UISegmentedControl!
    @IBOutlet weak var closeNoteButton: UIBarButtonItem!
    @IBOutlet weak var notesCV: UICollectionView!
    @IBOutlet weak var nextNoteButton: UIButton!
    @IBOutlet weak var prevNoteButton: UIButton!
    @IBOutlet weak var noteBackgroundController: UISegmentedControl!
    @IBOutlet weak var sortButton: UIBarButtonItem!
    @IBOutlet weak var filterButton: UIBarButtonItem!
    @IBOutlet weak var saveToCameraRollButton: UIBarButtonItem!
    @IBOutlet weak var showCompletedTodos: UISwitch!
    @IBOutlet weak var showCompletedReminders: UISwitch!
    @IBOutlet weak var showCompletedDeadlines: UISwitch!
    @IBOutlet weak var specialCharactersCV: UICollectionView!
    @IBOutlet weak var fullCalendarLabel: UILabel!
    @IBOutlet weak var fullCalendarCV: UICollectionView!
    @IBOutlet weak var fullCalendarBackgroundView: UIView!
    @IBOutlet weak var fullNoteButton: UIBarButtonItem!
    @IBOutlet weak var fullNoteBackgroundView: UIView!
    @IBOutlet weak var fullNoteCV: UICollectionView!
    @IBOutlet weak var nextFullNoteButton: UIButton!
    @IBOutlet weak var prevFullNoteButton: UIButton!
    @IBOutlet weak var noteBackgroundView: UIView!
    
    
    // MARK:IBACTIONS
    
    @IBAction func addNewItem(_ sender: Any) {
        edit = false
        performSegue(withIdentifier: "newItemSegue", sender: self)
    }
    
    @IBAction func addList(_ sender: Any) {
        let newList = UIAlertController(title: "New list", message: "What is the title?", preferredStyle: .alert)
        newList.addTextField(configurationHandler: { (name: UITextField) -> Void in
            name.placeholder = "Enter list title"
        })
        newList.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            let title = newList.textFields?[0].text
            
            if title != nil {
                self.listView.isHidden = false
                self.listLabel.text = title
                
                self.dataManager.addOrUpdateList(list: nil, title: title!)
                self.updateView()
            }
            
            newList.dismiss(animated: true, completion: nil)
            
        }))
        newList.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            newList.dismiss(animated: true, completion: nil)
        }))
        present(newList, animated: true, completion: nil)
        
        
    }
    
    @IBAction func chooseCalendar(_ sender: Any) {
        requestAccess()
        showCalendarChooser()
    }
    
    @IBAction func collapseExpandedNoteView(_ sender: Any) {
        expandedNotesView.isHidden = true
    }
 
    @IBAction func expandNotes(_ sender: Any) {
        expandedNotesView.isHidden = false
        expandedNotesTV.reloadData()
        view.bringSubviewToFront(expandedNotesView)
    }
    
    @IBAction func closeListView(_ sender: Any) {
        listView.isHidden = true
        if let tmp = listTextField.text {
            selectedList?.text = tmp
        }
        view.endEditing(true)
        dataManager.addOrUpdateList(list: selectedList!, title: selectedList!.title!)
    }
    
    @IBAction func closeCurrentNote(_ sender: Any) {
        print("closeCurrentNote()")
        
        title = "Never late"
        
        updateAndSaveNote(updateThumbnails: true, hideToolpicker: true)
        
        notesFullScreen = false
        numberOfWeeksChooser.isEnabled = true
        selectedNote = nil
        closeNoteButton.isEnabled = false
        noteBackgroundView.isHidden = true
        fullNoteBackgroundView.isHidden = true
//        prevNoteButton.isHidden = true
//        nextNoteButton.isHidden = true
        filterButton.isEnabled = true
        sortButton.isEnabled = true
        noteBackgroundController.isEnabled = false
        saveToCameraRollButton.isEnabled = false
        
        displayManager()
        updateView()
        
    }
    
    @IBAction func newTodo(_ sender: Any) {
        performSegue(withIdentifier: "newItemSegue", sender: "Todo")
    }
    
    @IBAction func newList(_ sender: Any) {
        
    }
    
    @IBAction func newReminder(_ sender: Any) {
        performSegue(withIdentifier: "newItemSegue", sender: "Reminder")
    }
    
    @IBAction func newDeadline(_ sender: Any) {
        performSegue(withIdentifier: "newItemSegue", sender: "Deadline")
    }
    
    @IBAction func nextMonthPressed(_ sender: Any) {
        selectedDate = CalendarModel().plusMonth(date: selectedDate)
        setMonthView()
    }
    
    @IBAction func noteBackgroundChanged(_ sender: Any) {
        print("noteBackgroundChanged()")
        
        switch noteBackgroundController.selectedSegmentIndex {
        case 0:
            noteBackground = UIImage(named: "dots.png")
        case 1:
            noteBackground = UIImage(named: "lines.png")
        case 2:
            noteBackground = nil
        case 3:
            notesFullScreen.toggle()
            calendarFullScreen = false
            toggleNotesFullScreen()
        default:
            noteBackground = UIImage(named: "dots.png")
        }
        
        displayManager()
        
        if noteBackgroundController.selectedSegmentIndex != 3 {
            updateSelectedNote()
            updateNote(hideToolpicker: false)

            if let background = self.notesCV.viewWithTag(123) {
                background.removeFromSuperview()
            }

            notesCV.reloadData()
        }
        
    }
    
    @IBAction func numberOfWeeksChanged(_ sender: Any) {
        let days = [8, 14, 20]
        if numberOfWeeksChooser.selectedSegmentIndex != 3 {
            calendarFullScreen = false
            numberOfDays = days[ numberOfWeeksChooser.selectedSegmentIndex]
            self.calenderCV.reloadData()
        } else {
            calendarFullScreen = true
            notesFullScreen = false
            self.fullCalendarCV.reloadData()
        }
        
        displayManager()
    }
    
    @IBAction func nextNotePage(_ sender: Any) {
        
        goToNextPage()
        
    }
    
    @IBAction func openThisWeeksNote(_ sender: Any) {
        openWeekNote()
    }
    
    @IBAction func prevMonthPressed(_ sender: Any) {
        selectedDate = CalendarModel().minusMonth(date: selectedDate)
        setMonthView()
    }
    
    @IBAction func prevNotePage(_ sender: Any) {
        
        goToPrevPage()
    }
    
    @IBAction func saveToCameraRollTapped(_ sender: Any) {
        print("saveToCameraRollTapped()")
        
        self.updateAndSaveNote(updateThumbnails: false, hideToolpicker: false)
        self.setSelectedNoteFromController(id: self.selectedNote!.dateAdded)
        
        if fullNoteBackgroundView.isHidden {
            
            if let cell = self.notesCV.cellForItem(at: IndexPath(row: pageNumber, section: 0)) as? NoteCVCell {
                let size = CGSize(width: self.notesCV.bounds.width, height: self.notesCV.bounds.height)
                UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
                cell.canvasView.drawHierarchy(in: cell.canvasView.bounds, afterScreenUpdates: true)
            }
            
        } else {
            
            if let cell = self.fullNoteCV.cellForItem(at: IndexPath(row: pageNumber, section: 0)) as? FullNoteCVCell {
                let size = CGSize(width: self.fullNoteCV.bounds.width, height: self.fullNoteCV.bounds.height)
                UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
                cell.canvasView.drawHierarchy(in: cell.canvasView.bounds, afterScreenUpdates: true)
            }
            
        }
                
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
                
    }
    
    @IBAction func toggleFullNoteViewTapped(_ sender: Any) {
        
        // UPDATE DRAWING, SELECTED NOTE, NO UPDATE ON THUMBNAIL AND NOT HIDE TOOLPICKER (?)
        updateAndSaveNote(updateThumbnails: false, hideToolpicker: false)
        
        notesFullScreen.toggle()
        displayManager()
        
        if notesFullScreen {
            fullNoteCV.reloadData()
        } else {
            notesCV.reloadData()
        }
    }
    
    @IBAction func viewOptionChanged(_ sender: Any) {
        updateView()
    }
    
    @IBAction func listLabelChanged(_ sender: Any) {
        if let currentList = selectedList {
            currentList.title = listLabel.text
            dataManager.addOrUpdateList(list: selectedList, title: listLabel.text ?? "")
            listTV.reloadData()
        }
    }
    
    
    
    
    
    
    
    // MARK: viewDidLoad()
    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = false
        UIApplication.shared.isIdleTimerDisabled = true
        
        drawingModelController.observers.append(self)
        drawingModelController.thumbnailTraitCollection = traitCollection
        
        notesCV.isScrollEnabled = false
        fullNoteCV.isScrollEnabled = false
        noteBackgroundView.isHidden = true
        fullNoteBackgroundView.isHidden = true

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeActionCalendar(swipe:)))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeActionCalendar(swipe:)))
        swipeRight.direction = .right
        fullCalendarCV.addGestureRecognizer(swipeLeft)
        fullCalendarCV.addGestureRecognizer(swipeRight)

        dataManager.loadCoreData()
//        dataManager.deleteCoreData()
        
        listTextField.delegate = self
        
        calenderCV.accessibilityIdentifier = "calendarCV"
        fullCalendarCV.accessibilityIdentifier = "fullCalendarCV"
        
        title = "Never late"
        
        setupView()
        setupNotifications()
        updateView()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressCalendar(press:)))
        longPress.minimumPressDuration = 1
        calenderCV.addGestureRecognizer(longPress)
                
        refreshTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(updateView), userInfo: nil, repeats: true)
        saveTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(updateAndSaveNote), userInfo: nil, repeats: true)

        showListView()
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.expandedNotesTV.deselectSelectedRow(animated: true)
    }
    
    
    
    
    
    
    // MARK: OBJC FUNCTIONS
    @objc func newItem() {
        edit = false
        performSegue(withIdentifier: "newItemSegue", sender: self)
    }
    
    @objc func addNewNote(notification: Notification) {
        let vc = notification.object as! NewNoteOptionsViewController
        if vc.makeNote {
            if let title = vc.noteTitle.text {
                if drawingModelController.titles.first( where: {$0 == title } ) != nil {
                    
                    let alert = UIAlertController(title: "Note already exists", message: "You have already created a note for this week", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    drawingModelController.newDrawing(title: title, category: vc.category)
                }
            }
        }
    }
    
    @objc func filterNotes(notification: Notification) {
        print("filterNotes()")
        
        let vc = notification.object as! FilterViewController
        filter.category = vc.category
        filter.text = vc.searchString.text
        
        updateView()
    }
    
//    @objc func fullCalendarViewClosed(notification: Notification) {
//        print("fullCalendarViewClosed()")
//
//        let vc = notification.object as! FullCalendarViewController
//
//        drawingModelController = vc.drawingModelController
//        setSelectedNoteFromController(id: vc.selectedNote!.dateAdded)
//        selectedDate = vc.selectedDate
//        selectedTypeAtFullView = vc.selectedType
//
//        populateNotes()
//        sortListOfNotes()
//        applyFilterToNotesList()
//
//        self.notesTV.reloadData()
//        self.expandedNotesTV.reloadData()
//        self.notesCV.reloadData()
//
//        refreshTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(updateView), userInfo: nil, repeats: true)
//        saveTimer = Timer.scheduledTimer(timeInterval: 200, target: self, selector: #selector(updateAndSaveNote), userInfo: nil, repeats: true)
//    }
    
    @objc func handleLongPressCalendar(press: UILongPressGestureRecognizer) {
        
        if press.state == .ended {
            
            let point = press.location(in: self.calenderCV)
            if let indexPath = self.calenderCV.indexPathForItem(at: point) {
                let selectedDay = Date().adding(days: indexPath.row)
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM dd"

                let alert = UIAlertController(title: "Add event", message: "Add event on " + formatter.string(from: selectedDay) + "?", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: {(alert: UIAlertAction!) in self.performSegue(withIdentifier: "newItemSegue", sender: indexPath)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func openWeekNote() {
        let weekNumber = Calendar.current.component(.weekOfYear, from: Date())
        let year = Calendar.current.component(.year, from: Date())
        let title = "Weekly note: " + "\(weekNumber)" + " " + "\(year)"
        
        if let index = drawingModelController.titles.firstIndex(where: {$0 == title} ) {
            setSelectedNoteFromController(id: drawingModelController.dateAdded[index])
            openNote()
        } else {
            let alert = UIAlertController(title: "No note this week", message: "You have not created a note for this week yet.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Make one now", style: UIAlertAction.Style.default, handler: {action in
                _ = self.createWeekNote()
            } ))
            self.present(alert, animated: true, completion: nil)
        }
        notesCV.reloadData()
    }
    
    @objc func updateAndSaveNote(updateThumbnails: Bool, hideToolpicker: Bool) {
        print("updateAndSaveNote()")
        
        updateNote(hideToolpicker: hideToolpicker)
        updateSelectedNote()
        drawingModelController.update = updateThumbnails
        drawingModelController.saveDrawingModel()
    }
    
    @objc func sortNotes(notification: Notification) {
        print("sortNotes()")
        
        let vc = notification.object as! SortViewController
        sortOption = vc.sort
        sortListOfNotes()
        updateView()
    }
    
    @objc func swipeActionNotes(swipe: UISwipeGestureRecognizer) {
        switch swipe.direction {
        case .down:
            goToPrevPage()
        case .up:
            goToNextPage()
        default:
            print("Default")
        }
    }

    @objc func swipeActionCalendar(swipe: UISwipeGestureRecognizer) {
        switch swipe.direction {
        case .left:
            selectedDate = CalendarModel().plusMonth(date: selectedDate)
            setMonthView()
        case .right:
            selectedDate = CalendarModel().minusMonth(date: selectedDate)
            setMonthView()
        default:
            print("Default")
        }
        
    }

    @objc func updateView() {
        print("updateView()")
        
        if fullNoteBackgroundView.isHidden == true {
            
            if noteBackgroundView.isHidden == true {
                populateItems()
                populateNotes()
                sortListOfNotes()
                applyFilterToNotesList()

                DispatchQueue.main.async {
                    self.toDoTV.reloadData()
                    self.deadlineTV.reloadData()
                    self.remindersTV.reloadData()
                    self.listTV.reloadData()
                    self.expandedNotesTV.reloadData()
                    self.notesTV.reloadData()
                }

            }

            weekNumber = Calendar.current.component(.weekOfYear, from: Date())
            currentDay = Calendar.current.component(.day, from: Date())
            currentDayOfWeek = Calendar.current.component(.weekday, from: Date())-1
            dataManager.getCalendarEvents()

            DispatchQueue.main.async {
                self.calenderCV.reloadData()
            }
        }
    }
    
    @objc func updateItem(notification: Notification) {
        print("updateItem()")
        
        let vc = notification.object as! InfoViewController
        
        if vc.item.type == "Calendar" {
            if let id = vc.item.eventId {
                if let event = dataManager.eventStore.event(withIdentifier: id) {
                    event.startDate = vc.item.startDate!
                    event.endDate = vc.endDatePicker.date
                    event.title = vc.item.title!
                    do {
                        try dataManager.eventStore.save(event, span: .thisEvent)
                        print("Event updated")
                    } catch {
                        print("Failed updating event")
                    }
                    
                }
            } else {
                print("No id")
            }
            
        } else {
            dataManager.saveCoreData()
        }
        
        updateView()
    }
    
    
    
    
    // MARK: FUNCTIONS
    func applyFilterToNotesList() {
        print("applyFilterToNotesList()")
        
        if filter.category == "All" {
            if filter.text != "" && filter.text != nil {
                notes = notes.filter{$0.title.contains(filter.text!)}
            }
        } else if filter.category == "User defined" {
            if filter.text != "" && filter.text != nil {
                notes = notes.filter{$0.title.contains(filter.text!) || $0.category.contains(filter.text!)}
            }
        } else {
            notes = notes.filter{$0.category == filter.category}
            if filter.text != "" && filter.text != nil {
                notes = notes.filter{$0.title.contains(filter.text!)}
            }
        }
    }
    
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {

        let calendars = Array(calendarChooser.selectedCalendars)

        dataManager.calendars = calendars
        dataManager.updateStoredCalendar(calendars: calendars)
        
        updateView()

        dismiss(animated: true, completion: nil)
    }
    
    func createWeekNote() -> String {
        let weekNumber = Calendar.current.component(.weekOfYear, from: Date())
        let year = Calendar.current.component(.year, from: Date())
        let title = "Weekly note: " + "\(weekNumber)" + " " + "\(year)"
        
        if drawingModelController.titles.firstIndex(where: {$0 == title}) == nil {
            print("Creating weekly note")
            self.drawingModelController.newDrawing(title: title, category: "Weekly note")
            return title
        } else {
            print("Weekly note already exists")
            return title
        }
    }
    
    func displayManager() {
        
        fullCalendarBackgroundView.isHidden = !calendarFullScreen
        
        if selectedNote == nil {
            fullNoteBackgroundView.isHidden = true
            noteBackgroundView.isHidden = true
        } else {
            numberOfWeeksChooser.isEnabled = !notesFullScreen

            if notesFullScreen {
                fullNoteBackgroundView.isHidden = false
                noteBackgroundView.isHidden = true
                view.bringSubviewToFront(fullNoteBackgroundView)
            } else {
                fullNoteBackgroundView.isHidden = true
                noteBackgroundView.isHidden = false
                
                view.bringSubviewToFront(noteBackgroundView)
            }
        }
        
        if calendarFullScreen {
            view.bringSubviewToFront(fullCalendarBackgroundView)
        }
        
    }
    
    func drawingModelChanged() {
        print("drawingModelChanged()")
        
        if selectedNote != nil {
            setSelectedNoteFromController(id: selectedNote!.dateAdded)
        }
        
        populateNotes()
        applyFilterToNotesList()
        sortListOfNotes()
        updateView()
        
        //KLAGAR ÖVER ATT DETTA SKER FRÅN EN BACKGROUND THREAD
//        notesTV.reloadData() //POPULERAR MED NYA THUMBNAILS
//        expandedNotesTV.reloadData() //POPULERAR MED NYA THUMBNAILS
        
//        notesCV.reloadData() //TA BORT: RENSAR BORT NY INFO MAN SKRIVIT MEDAN DATA SPARADES OCH LADDADES IGEN?
    }
    
    func getEventsOnDay(date: Date) -> [Item] {
//        print("getEventsOnDay()")
        
        let day = date.get(.day, .month, .year)
        
        let startDayMatched = dataManager.calendarItems.filter{$0.startDate?.get(.day, .month, .year) == day}
        let endDayMatched = dataManager.calendarItems.filter{$0.endDate?.get(.day, .month, .year) == day}
        let inBetweenMatched = dataManager.calendarItems.filter{$0.startDate! < date && $0.endDate! > date}
        
        if !inBetweenMatched.isEmpty {
//            print("inBetweenMatched")
//            print(inBetweenMatched[0].title)
//            print(inBetweenMatched[0].startDate)
//            print(inBetweenMatched[0].endDate)
//            print(date)
        }
        
        var filtered: [Item] = startDayMatched
        for item in endDayMatched {
            filtered.append(item)
        }
        for item in inBetweenMatched {
            filtered.append(item)
        }

        return filtered
    }
    
    func getDaysInMonth(month: Int, year: Int) -> Int? {
            let calendar = Calendar.current

            var startComps = DateComponents()
            startComps.day = 1
            startComps.month = month
            startComps.year = year

            var endComps = DateComponents()
            endComps.day = 1
            endComps.month = month == 12 ? 1 : month + 1
            endComps.year = month == 12 ? year + 1 : year

            
            let startDate = calendar.date(from: startComps)!
            let endDate = calendar.date(from:endComps)!

            let diff = calendar.dateComponents([Calendar.Component.day], from: startDate, to: endDate)

            return diff.day
        }
    
    func goToNextPage() {
        print("goToNextPage()")
        
        // SPARAR DRAWING MAN LÄMNAR
        updateAndSaveNote(updateThumbnails: false, hideToolpicker: false)

        // UPPDATERAR SELECTEDNOTE VID CURRENT PAGENUMBER INNAN DEN ÄNDRAS
        updateSelectedNote()
//        setSelectedNoteFromController(id: selectedNote!.dateAdded) ÄR DETTA RÄTT ATT GÖRA??? BORDE VÄL INTE LÄSA FRÅN SPARAD DATA?
        
        pageNumber = pageNumber + 1
        // GÅR TILL NÄSTA DRAWING
        
        if !notesFullScreen {
            if nextNoteButton.currentImage == UIImage(systemName: "arrowshape.turn.up.forward.fill") {
                if pageNumber >= selectedNote!.drawings.count - 1 {
                    nextNoteButton.setImage(UIImage(systemName: "plus"), for: .normal)
                }
            } else {
                drawingModelController.newSubDrawing(mainIndex: selectedNote!.index)
                setSelectedNoteFromController(id: drawingModelController.dateAdded[selectedNote!.index])
                notesCV.reloadData() //FUNKAR DETTA?
            }
        } else {
            if nextFullNoteButton.currentImage == UIImage(systemName: "arrowshape.turn.up.forward.fill") {
                if pageNumber >= selectedNote!.drawings.count - 1 {
                    nextFullNoteButton.setImage(UIImage(systemName: "plus"), for: .normal)
                }
            } else {
                drawingModelController.newSubDrawing(mainIndex: selectedNote!.index)
                setSelectedNoteFromController(id: drawingModelController.dateAdded[selectedNote!.index])
                fullNoteCV.reloadData() //FUNKAR DETTA?
            }
        }
        
        if !notesFullScreen {
            // DET FINNS FÖREGÅENDE NOTE
            prevNoteButton.isHidden = false

//            self.notesCV.reloadItems(at: [IndexPath(row: pageNumber, section: 0)])
            self.notesCV.scrollToItem(at: IndexPath(row: pageNumber, section: 0), at: .top, animated: true)
        } else {
            // DET FINNS FÖREGÅENDE NOTE
            prevFullNoteButton.isHidden = false
//            self.fullNoteCV.reloadItems(at: [IndexPath(row: pageNumber, section: 0)])
            self.fullNoteCV.scrollToItem(at: IndexPath(row: pageNumber, section: 0), at: .top, animated: true)
        }
        
    }

    func goToPrevPage() {
        print("goToPrevPage()")
        
        updateSelectedNote()
        
        if pageNumber > 0 {
            // SPARAR DRAWING MAN LÄMNAR
            updateAndSaveNote(updateThumbnails: false, hideToolpicker: false)
            
            // DET FINNS EN DRAWING EFTER, ÄNDRA IKON
            if !notesFullScreen {
                nextNoteButton.setImage(UIImage(systemName: "arrowshape.turn.up.forward.fill"), for: .normal)
            } else {
                nextFullNoteButton.setImage(UIImage(systemName: "arrowshape.turn.up.forward.fill"), for: .normal)
            }
            
            pageNumber = pageNumber - 1
            // GÅR TILL FÖRRA DRAWING
            if pageNumber < 0 {
                pageNumber = 0
            }
            
            if pageNumber == 0 {
                if !notesFullScreen {
                    prevNoteButton.isHidden = true
                } else {
                    prevFullNoteButton.isHidden = true
                }
            }

            if !notesFullScreen {
//                self.notesCV.reloadItems(at: [IndexPath(row: pageNumber, section: 0)]) SKA MAN GÖRA DETTA?
                self.notesCV.scrollToItem(at: IndexPath(row: pageNumber, section: 0), at: .top, animated: true)
            } else {
                self.fullNoteCV.scrollToItem(at: IndexPath(row: pageNumber, section: 0), at: .top, animated: true)
            }
        }
    }
    
    func toggleNotesFullScreen() {
        
        if notesFullScreen {
            notesCV.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
            notesCV.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        } else {
            notesCV.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width/2, height: UIScreen.main.bounds.size.height)
            notesCV.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width/2, height: UIScreen.main.bounds.size.height)
        }
        
        view.bringSubviewToFront(notesCV)
        view.bringSubviewToFront(prevNoteButton)
        view.bringSubviewToFront(nextNoteButton)

        notesCV.reloadData()
        
    }
    
    func openNote() {
        
        if selectedNote != nil {
            title = selectedNote!.title
        }
        
        // BÖRJAR ALLTID I 1/2 MODE (notesCV)
        notesFullScreen = false
        noteBackgroundView.isHidden = false
        fullNoteBackgroundView.isHidden = true
        
        notesCV.reloadData()
        fullNoteCV.reloadData()
        
        view.bringSubviewToFront(noteBackgroundView)
        
        if selectedNote!.drawings.count > 1 {
            nextNoteButton.setImage(UIImage(systemName: "arrowshape.turn.up.forward.fill"), for: .normal)
            nextFullNoteButton.setImage(UIImage(systemName: "arrowshape.turn.up.forward.fill"), for: .normal)
        } else {
            nextNoteButton.setImage(UIImage(systemName: "plus"), for: .normal)
            nextFullNoteButton.setImage(UIImage(systemName: "plus"), for: .normal)
        }
        
        nextNoteButton.isHidden = false
        filterButton.isEnabled = false
        sortButton.isEnabled = false
        closeNoteButton.isEnabled = true
        prevNoteButton.isHidden = true
        noteBackgroundController.isEnabled = true
        saveToCameraRollButton.isEnabled = true
        
        pageNumber = 0
        self.notesCV.scrollToItem(at: IndexPath(row: pageNumber, section: 0), at: .top, animated: true)
        
    }
    
    func requestAccess() {
        eventStore.requestAccess(to: .event) { (granted, error) in
            if granted {
                self.accessToCalendars = true
                DispatchQueue.main.async {
                    self.showCalendarChooser()
                }
            }
        }
    }
    
    func populateNotes() {
        print("populateNotes()")
        
        notes.removeAll()
        
        for index in 0..<drawingModelController.drawings.count {
            let note = NoteItem(drawings: drawingModelController.drawings[index], title: drawingModelController.titles[index], dateAdded: drawingModelController.dateAdded[index], dateModified: drawingModelController.dateModified[index], category: drawingModelController.categories[index], thumbnail: drawingModelController.thumbnails[index], index: index)
            notes.append(note)
        }
    }
    
    func populateItems() {
        print("populateItems()")
        
        todos = [Item]()
        todos = dataManager.items.filter{$0.type == "To do"}
        todos = todos.sorted {dataManager.priorityStringToValue[$0.priority!]! > dataManager.priorityStringToValue[$1.priority!]!}
        todos = todos.sorted {!$0.completed && $1.completed}

        deadlines = [Item]()
        deadlines = dataManager.items.filter{$0.type == "Deadline"}
        deadlines = deadlines.sorted {dataManager.priorityStringToValue[$0.priority!]! > dataManager.priorityStringToValue[$1.priority!]!}
        deadlines = deadlines.sorted {!$0.completed && $1.completed}
        
        reminders = [Item]()
        reminders = dataManager.items.filter{$0.type == "Reminder"}
        reminders = reminders.sorted {dataManager.priorityStringToValue[$0.priority!]! > dataManager.priorityStringToValue[$1.priority!]!}
        reminders = reminders.sorted {$0.startDate! < $1.startDate!}
        
    }
    
    func prefersHomeIndicatorAutoHidden() -> Bool {
        print("prefersHomeIndicatorAutoHidden()")
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("segue: " + segue.identifier!)
        
        if (segue.identifier == "newItemSegue") {
            
            let destination = segue.destination as! AddNewItemViewController
            if let indexPath = sender as? IndexPath {
                destination.date = Date().adding(days: indexPath.row)
            } else {
                destination.date = Date()
            }
            if let type = sender as? String {
                destination.selectedType = type
            }
            destination.selectedItem = selectedItem
            destination.dataManager = dataManager
            
            let backItem = UIBarButtonItem()
            backItem.title = "Cancel"
            navigationItem.backBarButtonItem = backItem
            
        } else if (segue.identifier == "infoSegue") {
            let destination = segue.destination as! InfoViewController
            
            destination.item = selectedItem
            destination.dataManager = dataManager
            destination.preferredContentSize = CGSize(width: 752, height: 400)

        } else if (segue.identifier == "addNoteSegue") {
            let destination = segue.destination as! NewNoteOptionsViewController
            destination.preferredContentSize = CGSize(width: 400, height: 200)
            
        } else if (segue.identifier == "sortSegue") {
            let destination = segue.destination as! SortViewController
            destination.sort = sortOption
            destination.preferredContentSize = CGSize(width: 360, height: 72)
            
        } else if (segue.identifier == "filterSegue") {
            let destination = segue.destination as! FilterViewController
            destination.preferredContentSize = CGSize(width: 430, height: 160)
            
        } else if (segue.identifier == "addNoteSegueExpandedView") {
            let destination = segue.destination as! NewNoteOptionsViewController
            
            destination.preferredContentSize = CGSize(width: 400, height: 200)
            
        } else if (segue.identifier == "fullCalendarViewSegue") {
            let destination = segue.destination as! FullCalendarViewController
            
            updateAndSaveNote(updateThumbnails: false, hideToolpicker: true)
            
            destination.selectedDate = selectedDate
            destination.dataManager = dataManager
            destination.zoom = notesCV.bounds

            if selectedNote == nil {
                let title = createWeekNote()
                
                if let index = drawingModelController.titles.firstIndex(where: {$0 == title} ) {
                    setSelectedNoteFromController(id: drawingModelController.dateAdded[index])
                }
            }
            
            destination.noteID = selectedNote?.dateAdded
            destination.selectedType = selectedTypeAtFullView
            destination.drawingModelController = drawingModelController
            
            if refreshTimer != nil {
                refreshTimer.invalidate()
            }
            if saveTimer != nil {
                saveTimer.invalidate()
            }
            
        }
        
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
        
        fullCalendarLabel.text = CalendarModel().monthString(date: selectedDate) + " " + CalendarModel().yearString(date: selectedDate)
        title = "Calendar view"
        
        fullCalendarCV.reloadData()
    }
    
    func setNoteCell(cell: NoteCell, index: Int) -> NoteCell {
        
        cell.dateAdded = notes[index].dateAdded
        cell.thumbNail.image = notes[index].thumbnail//drawingModelController.thumbnails[index]
        cell.title.text = notes[index].title // drawingModelController.titles[index]
        cell.category.text = notes[index].category //drawingModelController.categories[index]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd YYYY HH:mm"
        cell.dateString.text = "Changed: " + formatter.string(from: notes[index].dateModified) //drawingModelController.dateModified[index])
        
        if notes[index].category == "Weekly note" {
            cell.category.textColor = .blue
        } else if notes[index].category == "Meeting" {
            cell.category.textColor = .red
        } else {
            cell.category.textColor = .black
        }
        
        return cell
    }
    
    func setSelectedNoteFromController(id: Date) {
        print("setSelectedNoteFromController()")
        
        print(id)
        if let index = drawingModelController.dateAdded.firstIndex(where: {$0 == id} ) {
            print(drawingModelController.titles[index])
            let tmp = NoteItem(drawings: drawingModelController.drawings[index], title: drawingModelController.titles[index], dateAdded: drawingModelController.dateAdded[index], dateModified: drawingModelController.dateModified[index], category: drawingModelController.categories[index], thumbnail: drawingModelController.thumbnails[index], index: index)
            selectedNote = tmp
        } else {
            selectedNote = nil
        }
        print(selectedNote)
    }
    
    func setItemCell(item: Item, cell: ItemCell) -> ItemCell {
        cell.event = item
        cell.mainLabel.text = item.title
        cell.layer.cornerRadius = 5
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        if let startDate = item.startDate {
            cell.dateLabel.text = formatter.string(from: startDate)
        } else {
            cell.dateLabel.text = ""
        }

        if item.completed {
            cell.tickBox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            cell.contentView.alpha = 0.5
            
        } else {
            switch item.priority {
            case "Low":
                cell.tickBox.setImage(UIImage(systemName: "circle"), for: .normal)
            case "Medium":
                cell.tickBox.setImage(UIImage(systemName: "smallcircle.fill.circle"), for: .normal)
            case "High":
                cell.tickBox.setImage(UIImage(systemName: "largecircle.fill.circle"), for: .normal)
            default:
                cell.tickBox.setImage(UIImage(systemName: "circle"), for: .normal)
            }
            
            cell.contentView.alpha = 1
        }
        
        return cell
    }

    func setPortraitView() {
//        self.monthCalendarView.isHidden = false
//        self.view.bringSubviewToFront(self.monthCalendarView)
//        self.saveToCameraRollButton.isEnabled = false
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: NSNotification.Name(rawValue: "updateView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.addNewNote), name: NSNotification.Name(rawValue: "addNewNote"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sortNotes), name: NSNotification.Name(rawValue: "sortNotes"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.filterNotes), name: NSNotification.Name(rawValue: "filterNotes"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateItem), name: NSNotification.Name(rawValue: "updateItem"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(self.fullCalendarViewClosed), name: NSNotification.Name(rawValue: "fullCalendarViewClosed"), object: nil)
    }
    
    func setupView() {
        print("setupView")
        
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        self.edgesForExtendedLayout = []
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM YYYY"
        title = formatter.string(from: Date())
        
        let month = Calendar.current.component(.month, from: Date())
        let year = Calendar.current.component(.year, from: Date())
        if let tmp = getDaysInMonth(month: month, year: year) {
            numberOfDaysInMonth = tmp
        }
        
        setMonthView()
        
        numberOfWeeksChooser.selectedSegmentIndex = 1
        
        self.navigationItem.setHidesBackButton(true, animated: true)

        expandedNotesTV.backgroundColor = .clear
        expandedNotesView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        expandedNotesView.layer.borderWidth = 2
        expandedNotesView.layer.cornerRadius = 10
        expandedNotesView.backgroundColor = .white
        expandedNotesView.isHidden = true
        
        notesTV.backgroundColor = .clear
        notesView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        notesView.layer.borderWidth = 2
        notesView.layer.cornerRadius = 10
        notesView.backgroundColor = .white
        
        calenderCV.layer.borderColor = CGColor(red: 1/10, green: 1/10, blue: 1/10, alpha: 1)
        calenderCV.layer.borderWidth = 2
        calenderCV.layer.cornerRadius = 10
        calenderCV.backgroundColor = .white
        calenderCV.isScrollEnabled = false
        
        notesCV.layer.borderColor = CGColor(red: 1/10, green: 1/10, blue: 1/10, alpha: 1)
        notesCV.layer.borderWidth = 2
        notesCV.layer.cornerRadius = 10
                
        let alpha = CGFloat(0.4)
        
        toDoTV.backgroundColor = .clear
        toDoView.layer.cornerRadius = 10
        toDoView.layer.borderWidth = 2
        toDoView.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: alpha)
        toDoView.layer.borderColor = CGColor(red: 0, green: 0, blue: 1, alpha: 1)
        
        deadlineTV.backgroundColor = .clear
        deadlineView.layer.cornerRadius = 10
        deadlineView.layer.borderWidth = 2
        deadlineView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: alpha)
        deadlineView.layer.borderColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        
        remindersTV.backgroundColor = .clear
        remindersView.layer.cornerRadius = 10
        remindersView.layer.borderWidth = 2
        remindersView.backgroundColor = UIColor(red: 1, green: 1, blue: 0, alpha: alpha)
        remindersView.layer.borderColor = CGColor(red: 1, green: 1, blue: 0, alpha: 1)

        listTV.backgroundColor = .clear
        listsView.layer.cornerRadius = 10
        listsView.layer.borderWidth = 2
        listsView.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: alpha)
        listsView.layer.borderColor = CGColor(red: 0, green: 1, blue: 0, alpha: 1)

        listView.layer.cornerRadius = 10
        listView.layer.borderWidth = 2
        listView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        listView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        listView.isHidden = true
        
        displayManager()
        
        prevNoteButton.isHidden = true
        nextNoteButton.isHidden = true
        closeNoteButton.isEnabled = false
        noteBackgroundController.isEnabled = false
        saveToCameraRollButton.isEnabled = false
        filterButton.isEnabled = true
        sortButton.isEnabled = true

        weekNumber = Calendar.current.component(.weekOfYear, from: Date())
        
//        if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
//            if interfaceOrientation.isPortrait {
//                performSegue(withIdentifier: "fullCalendarViewSegue", sender: nil)
//            }
//        }

    }
    
    func showCalendarChooser() {
        
        let vc = EKCalendarChooser(selectionStyle: .multiple, displayStyle: .allCalendars, entityType: .event, eventStore: eventStore)
        // customization
        vc.showsDoneButton = true
        vc.showsCancelButton = true
        
        // dont forget the delegate
        vc.delegate = self
        
        let nvc = UINavigationController(rootViewController: vc)
        
        self.present(nvc, animated: true, completion: nil)
    }
    
    func showListView() {
        let stringArray: [String] = []
        listTextField.attributedText = NSAttributedStringHelper.createBulletedList(fromStringArray: stringArray, font: UIFont.systemFont(ofSize: 15))
//        listLabel.numberOfLines = stringArray.count
//        listLabel.attributedText = NSAttributedStringHelper.createBulletedList(fromStringArray: stringArray, font: UIFont.systemFont(ofSize: 15))
    }
    
    func sortToDos() {
        
    }
    
    func sortListOfNotes() {
        print("sortListOfNotes()")
        
        if sortOption == "Date added" {
            notes = notes.sorted{ $0.dateModified > $1.dateModified}
        } else {
            notes = notes.sorted{ $0.dateAdded > $1.dateAdded}
        }
        
    }

    func updateListText() {
        
    }
    
    func updateNote(hideToolpicker: Bool) {
        print("updateNote(): " + "\(hideToolpicker)")
        
        if !notesFullScreen {
            if let cell = notesCV.cellForItem(at: IndexPath(row: pageNumber, section: 0)) as? NoteCVCell {
//                if let index = selectedNote?.index { //Testar byta mot raden under (20210917)
                if let index = drawingModelController.dateAdded.firstIndex(where: { $0 == cell.dateAdded }) {
                    drawingModelController.updateDrawing(cell.canvasView.drawing, at: index, at: pageNumber)
                    if hideToolpicker {
                        toolPicker.setVisible(false, forFirstResponder: cell.canvasView)
                        toolPicker.removeObserver(cell.canvasView)
                    }
                }
            }
        } else {
            if let cell = fullNoteCV.cellForItem(at: IndexPath(row: pageNumber, section: 0)) as? FullNoteCVCell {
                if let index = drawingModelController.dateAdded.firstIndex(where: { $0 == cell.dateAdded }) {
                    drawingModelController.updateDrawing(cell.canvasView.drawing, at: index, at: pageNumber)
                    if hideToolpicker {
                        toolPicker.setVisible(false, forFirstResponder: cell.canvasView)
                        toolPicker.removeObserver(cell.canvasView)
                    }
                }
            }
        }
        
        
    }
    
    func updateSelectedNote() {
        print("updateSelectedNote()")
        
        if selectedNote != nil {
            if !notesFullScreen {
                if let cell = notesCV.cellForItem(at: IndexPath(row: pageNumber, section: 0)) as? NoteCVCell {
                    selectedNote!.drawings[pageNumber] = cell.canvasView.drawing
                }
            } else {
                if let cell = fullNoteCV.cellForItem(at: IndexPath(row: pageNumber, section: 0)) as? FullNoteCVCell {
                    selectedNote!.drawings[pageNumber] = cell.canvasView.drawing
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if dataManager.calendars.isEmpty {
            requestAccess()
        }
    }
        
    func textViewDidChange(_ textView: UITextView) {
//        let bulletPoint: String = "\u{2022}"
//
//        var addEnter = false
//        if var text = textView.text {
//
//            if text.contains("\n\n") {
//                text = text.replacingOccurrences(of: "\n\n", with: "\n \n")
//            }
//
//            if text.last == "\n" {
//                addEnter = true
//            }
//            text = text.replacingOccurrences(of: bulletPoint + " ", with: "")
//            var stringArray: [String] = []
//
//            let array = text.split(separator: "\n")
//
//            for line in array {
//                stringArray.append(String(line))
//            }
//
//            if addEnter {
//                stringArray.append("\n")
//            }
//
//            listTextField.attributedText = NSAttributedStringHelper.createBulletedList(fromStringArray: stringArray, font: UIFont.systemFont(ofSize: 15))
//
//            if addEnter {
//                listTextField.text.removeLast()
//            }
//
//            if listTextField.text.contains("\n \n") {
//                listTextField.text = listTextField.text.replacingOccurrences(of: "\n \n", with: "\n\n")
//            }
//
//
//        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        drawingModelController.thumbnailTraitCollection = traitCollection
    }
    
    
    
    
    // MARK: UI INTERFACE
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isPortrait {
            print("portrait")
            print(notesCV.bounds)
//            notesCV.bounds = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
//            performSegue(withIdentifier: "fullCalendarViewSegue", sender: self)
        } else {
            print("landscape")
            print(notesCV.bounds)
//            notesCV.bounds = CGRect(x: 0, y: 0, width: view.bounds.width/2, height: view.bounds.height)
        }
        updateView()
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "n", modifierFlags: .command, action: #selector(newItem), discoverabilityTitle: "Add new item"),
            UIKeyCommand(input: "o", modifierFlags: .command, action: #selector(openWeekNote), discoverabilityTitle: "Open this week's note")
        ]
    }
    
    
    // MARK: TABLE VIEW
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.notesTV || tableView == self.expandedNotesTV {
            return self.notes.count
        
        } else if tableView == self.toDoTV || tableView == self.deadlineTV || tableView == self.listTV {
            return 1
            
        } else {
            
            if tableView.accessibilityIdentifier == "fullCalendarCell" {
                
                var components = calendar.dateComponents([.month, .year], from: selectedDate)
                components.day = tableView.tag
                let date = calendar.date(from: components)!
                
                let events = dataManager.getCalendarEventsOn(day: date)
                
                if events != nil {
                    return events!.count
                } else {
                    return 0
                }
            } else {
                return 1
            }

        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.toDoTV {
            if showCompletedTodos.isOn {
                return todos.count
            } else {
                return todos.filter{$0.completed != true}.count
            }
        } else if tableView == self.deadlineTV {
            if showCompletedDeadlines.isOn {
                return deadlines.count
            } else {
                return deadlines.filter{$0.completed != true}.count
            }
        } else if tableView == self.listTV {
            return dataManager.lists.count
            
        } else if tableView == self.remindersTV {
            if showCompletedReminders.isOn {
                return reminders.count
            } else {
                return reminders.filter{$0.startDate! > Date()}.count
            }
            
        } else if tableView == self.notesTV  {
            return 1
            
        } else if tableView == self.expandedNotesTV  {
            return 1
            
        } else {
            if tableView.accessibilityIdentifier == "fullCalendarCell" {
                return 1
            } else {
                let day = Date().adding(days: tableView.tag).get(.day, .month, .year)
                let filtered = dataManager.calendarItems.filter{$0.startDate?.get(.day, .month, .year) == day}.count
                return filtered
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.toDoTV || tableView == self.deadlineTV || tableView == self.remindersTV {
            
            let cell = tableView.cellForRow(at: indexPath) as! ItemCell
            selectedItem = cell.event
            
            performSegue(withIdentifier: "infoSegue", sender: self)

        } else if tableView == self.listTV {
            
            let cell = tableView.cellForRow(at: indexPath) as! ListCell
            selectedList = cell.list
            listView.isHidden = false
            self.view.bringSubviewToFront(listView)
            listLabel.text = selectedList!.title
            if let text = selectedList?.text {
                listTextField.text = text
            }
            
        } else if tableView == self.notesTV || tableView == self.expandedNotesTV {
            
            setSelectedNoteFromController(id: notes[indexPath.row].dateAdded)
            openNote()
               
        } else if tableView.accessibilityIdentifier == "fullCalendarCell" {
            
            let cell = tableView.cellForRow(at: indexPath) as! FullCalendarEventCell
            
        } else {
            
            if !calendarFullScreen {
                let cell = tableView.cellForRow(at: indexPath) as! CalenderEventCell
                selectedItem = cell.event
                performSegue(withIdentifier: "infoSegue", sender: nil)
            }
        }

        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.notesTV {
            return 123
        } else if tableView == self.expandedNotesTV {
            return 123
        } else {
            return 20
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.tableHeaderView?.backgroundColor = .clear
        
        if tableView == self.toDoTV {
            var cell = tableView.dequeueReusableCell(withIdentifier: "todoCell") as! ItemCell
            
            cell = setItemCell(item: todos[indexPath.section], cell: cell)
            
            return cell
          
        } else if tableView == self.deadlineTV {
            
            var cell = tableView.dequeueReusableCell(withIdentifier: "deadlineCell") as! ItemCell
            
            cell = setItemCell(item: deadlines[indexPath.section], cell: cell)
            
            return cell

        } else if tableView == self.remindersTV {
            
            var cell = tableView.dequeueReusableCell(withIdentifier: "reminderCell") as! ItemCell
            
            let items = dataManager.items.filter{$0.type == "Reminder"}
            let item = items[indexPath.section]
            
            if let date = item.startDate {
                if date < Date() {
                    item.completed = true
                }
            }
            
            cell = setItemCell(item: item, cell: cell)

            return cell
            
        } else if tableView == self.notesTV || tableView == self.expandedNotesTV {
            
            if let index = indexPath.last, index < notes.count {
                if tableView == self.expandedNotesTV {
                    var cell = tableView.dequeueReusableCell(withIdentifier: "expandedNoteCell") as! NoteCell
                    cell = setNoteCell(cell: cell, index: index)
                    return cell
                } else {
                    var cell = tableView.dequeueReusableCell(withIdentifier: "noteCell") as! NoteCell
                    cell = setNoteCell(cell: cell, index: index)
                    return cell
                }
            } else {
                let cell = UITableViewCell()
                return cell
            }
            
        } else if tableView == self.listTV {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "listCell") as! ListCell
            
            let list = dataManager.lists[indexPath.section]
            
            selectedList = list

            cell.layer.cornerRadius = 5
            cell.title.text = list.title
            cell.list = list
            
            return cell
            
        } else if tableView.accessibilityIdentifier == "fullCalendarCell" {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "fullCalendarEventCell") as! FullCalendarEventCell
            
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
            
        } else {
            
            if tableView.accessibilityIdentifier == "fullCalendarCell" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "fullCalendarEventCell") as! FullCalendarEventCell
                
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

            } else {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "calenderEventCell") as! CalenderEventCell
                
    //            let day = Date().adding(days: tableView.tag).get(.day, .month, .year)
    //            let filtered = dataManager.calendarItems.filter{$0.startDate?.get(.day, .month, .year) == day}
                let filtered = getEventsOnDay(date: Date().adding(days: tableView.tag))
                
                cell.backgroundColor = dataManager.getCalendarColor(calendarId: filtered[indexPath.section].calendarId)
                
                cell.eventInformation.text = filtered[indexPath.section].title
                cell.eventInformation.textColor = .black
                cell.event = filtered[indexPath.section]
                
                if !CalendarModel().isOverNightEvent(startDate: filtered[indexPath.section].startDate, endDate: filtered[indexPath.section].endDate) {// !filtered[indexPath.section].isAllDay {
                    if let startTime = filtered[indexPath.section].startDate {
                        
                        print(filtered[indexPath.section].isAllDay)
                        
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        
                        if filtered[indexPath.section].isAllDay {
                            cell.eventStartTime.text = "All day"
                        } else {
                            cell.eventStartTime.text = formatter.string(from: startTime)
                        }
                        cell.eventStartTime.textColor = .black
                        cell.layer.cornerRadius = 5
                    } else {
                        cell.eventStartTime.text = ""
                    }
                }
                
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == self.remindersTV {
            return false
        } else {
            return true
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if tableView == self.toDoTV {
            let todo = todos[indexPath.section]
            
            if todo.completed {
                let completeAction = UIContextualAction(style: .normal, title: "Not completed") { _, _, completionHandler in
                    
                    todo.completed = false
                    if let index = self.dataManager.items.firstIndex(where: { $0.title == todo.title && $0.type == "To do" && $0.added == todo.added}) {
                        self.dataManager.items[index] = todo
                        DispatchQueue.main.async {
                            self.dataManager.saveCoreData()
                            self.updateView()
                        }
                    }
                                        
                    completionHandler(true)
                }
                completeAction.backgroundColor = .blue
                let configuration = UISwipeActionsConfiguration(actions: [completeAction])
                configuration.performsFirstActionWithFullSwipe = true
                return configuration
            
            } else {
                let notCompleteAction = UIContextualAction(style: .normal, title: "Completed") { _, _, completionHandler in
                    
                    todo.completed = true
                    if let index = self.dataManager.items.firstIndex(where: { $0.title == todo.title && $0.type == "To do" && $0.added == todo.added}) {
                        self.dataManager.items[index] = todo
                        DispatchQueue.main.async {
                            self.dataManager.saveCoreData()
                            self.updateView()
                        }
                    }
                    
                    completionHandler(true)
                }
                notCompleteAction.backgroundColor = .red
                let configuration = UISwipeActionsConfiguration(actions: [notCompleteAction])
                configuration.performsFirstActionWithFullSwipe = true
                return configuration
            }
            
        } else if tableView == self.deadlineTV {
                let deadline = deadlines[indexPath.section]
                
                if deadline.completed {
                    let completeAction = UIContextualAction(style: .normal, title: "Not completed") { _, _, completionHandler in
                        
                        deadline.completed = false
                        if let index = self.dataManager.items.firstIndex(where: { $0.title == deadline.title && $0.type == "Deadline" && $0.added == deadline.added}) {
                            self.dataManager.items[index] = deadline
                            DispatchQueue.main.async {
                                self.dataManager.saveCoreData()
                                self.updateView()
                            }
                        }
                                            
                        completionHandler(true)
                    }
                    completeAction.backgroundColor = .blue
                    let configuration = UISwipeActionsConfiguration(actions: [completeAction])
                    configuration.performsFirstActionWithFullSwipe = true
                    return configuration
                
                } else {
                    let notCompleteAction = UIContextualAction(style: .normal, title: "Completed") { _, _, completionHandler in
                        
                        deadline.completed = true
                        if let index = self.dataManager.items.firstIndex(where: { $0.title == deadline.title && $0.type == "Deadline" && $0.added == deadline.added}) {
                            self.dataManager.items[index] = deadline
                            DispatchQueue.main.async {
                                self.dataManager.saveCoreData()
                                self.updateView()
                            }
                        }
                        
                        completionHandler(true)
                    }
                    notCompleteAction.backgroundColor = .red
                    let configuration = UISwipeActionsConfiguration(actions: [notCompleteAction])
                    configuration.performsFirstActionWithFullSwipe = true
                    return configuration
                }
        } else if tableView == self.notesTV {
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            
                print("Deleting note")
                if let cell = self.notesTV.cellForRow(at: indexPath) as? NoteCell {
                    if let index = self.drawingModelController.dateAdded.firstIndex(where: { $0 == cell.dateAdded }) {
                        self.drawingModelController.drawings.remove(at: index)
                        self.drawingModelController.categories.remove(at: index)
                        self.drawingModelController.dateAdded.remove(at: index)
                        self.drawingModelController.titles.remove(at: index)
                        self.drawingModelController.dateModified.remove(at: index)

                        self.drawingModelController.saveDrawingModel()
//                        self.drawingModelController.loadDrawingModel()
                    }
                }
                
                completionHandler(true)
            }
            
            deleteAction.backgroundColor = .red
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
            
        } else {
            return nil
        }
    }
    
    
    
    
    // MARK: COLLECTION VIEW
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.calenderCV {
            return numberOfDays
        } else if collectionView == self.notesCV || collectionView == self.fullNoteCV {
            if self.selectedNote == nil {
                return 0
            } else {
                return self.selectedNote!.drawings.count
            }
        } else if collectionView == self.specialCharactersCV {
            return dataManager.specialCharacters.count
        } else if collectionView == self.fullCalendarCV {
            return totalSquaresInMonthCalendar.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == calenderCV {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "calenderCell", for: indexPath) as! CalenderCell
            
            let weekday = currentDayOfWeek + indexPath.row
            var date = currentDay + indexPath.row
            
            if indexPath.row == 0 {
                weekNumber = Calendar.current.component(.weekOfYear, from: Date())
            }
            
            if date > numberOfDaysInMonth {
                date = date - numberOfDaysInMonth
            }
            
            if dataManager.weekdays[weekday] == "Monday" || indexPath.row == 0 {
                cell.weekNumber.isHidden = false
                cell.weekNumber.text = "\(weekNumber)"
                weekNumber = weekNumber + 1
            } else {
                cell.weekNumber.isHidden = true
            }
            
            cell.weekday.text = dataManager.weekdays[weekday]
            cell.dateLabel.text = "\(date)"
            cell.layer.borderWidth = 0.25
            cell.layer.borderColor = UIColor.black.cgColor
            
            cell.backgroundColor = .white
            
            if cell.weekday.text == "Saturday" {
                cell.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.25)
            }
            if cell.weekday.text == "Sunday" {
                cell.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.25)
            }
            
            cell.calenderEventTV.tag = indexPath.row
            cell.calenderEventTV.reloadData()
            
            return cell
            
        } else if collectionView == self.notesCV {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "noteCVCell", for: indexPath) as! NoteCVCell
            
            cell.accessibilityIdentifier = "noteCV"

            if !notesFullScreen {
                
//                print("Number of subviews: " + "\(cell.canvasView.subviews.count)")
                
                /*
                var subviewAdded = false
                for i in 0..<cell.canvasView.subviews.count {
                    if cell.canvasView.subviews[i].tag == 123 {
                        print("Subview already added")
                        subviewAdded = true
                        //VARFÖR BEHÖVS DESSA? 2021-08-26
//                        let view = cell.canvasView.subviews[i] as! UIImageView
//                        view.image = noteBackground
                    }
                }
                */
                
                let backgroundImage = UIImageView(image: noteBackground)
                
                cell.layer.cornerRadius = 10
                cell.layer.borderWidth = 2
                cell.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
                
                cell.dateAdded = selectedNote!.dateAdded
                cell.canvasView.bounds = cell.bounds
                cell.canvasView.drawing = PKDrawing()
                
                //MÅSTE VARA LIKA BRED SOM I PORTRAIT ANNARS HAMNAR TEXT UTANFÖR BOUNDS
                cell.canvasView.minimumZoomScale = 1
                cell.canvasView.maximumZoomScale = 6
                cell.canvasView.delegate = self
                cell.canvasView.backgroundColor = .clear
                cell.canvasView.drawingPolicy = .anyInput // .pencilOnly
                cell.canvasView.drawing = selectedNote!.drawings[indexPath.row]
                
//                cell.layer.shadowColor = UIColor.black.cgColor
//                cell.layer.shadowOpacity = 1
//                cell.layer.shadowOffset = .zero
//                cell.layer.shadowRadius = 10

                //TA BORT PRICKAR
                if let background = self.notesCV.viewWithTag(123) {
                    background.removeFromSuperview()
                }
                
                backgroundImage.contentMode = .scaleToFill
                backgroundImage.frame = cell.canvasView.bounds
                backgroundImage.tag = 123
//                backgroundImage.translatesAutoresizingMaskIntoConstraints = false
//                backgroundImage.autoresizingMask = [.flexibleBottomMargin, .flexibleHeight, .flexibleWidth, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
                backgroundImage.backgroundColor = .white
                
                cell.canvasView.insertSubview(backgroundImage, at: 0)
                cell.canvasView.zoomScale = 1
                
            }
            
            return cell
            
        } else if collectionView == self.fullNoteCV {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "noteCVCellFullView", for: indexPath) as! FullNoteCVCell
            
            cell.accessibilityIdentifier = "fullNoteCV"

            if notesFullScreen {
                
                let backgroundImage = UIImageView(image: noteBackground)
                
                cell.dateAdded = selectedNote!.dateAdded
                cell.canvasView.drawing = PKDrawing()

                cell.canvasView.minimumZoomScale = 1
                cell.canvasView.maximumZoomScale = 6
                cell.canvasView.delegate = self
                cell.canvasView.backgroundColor = .clear
                cell.canvasView.drawingPolicy = .anyInput // .pencilOnly
                cell.canvasView.drawing = selectedNote!.drawings[indexPath.row]
                
//                cell.layer.shadowColor = UIColor.black.cgColor
//                cell.layer.shadowOpacity = 1
//                cell.layer.shadowOffset = .zero
//                cell.layer.shadowRadius = 10
                
                // TAR BORT PRICKAR
                if let background = self.notesCV.viewWithTag(234) {
                    background.removeFromSuperview()
                }
                
                // LÄGGER TILL PRICKAR
//                backgroundImage.contentMode = .scaleAspectFit //.scaleAspectFill //.scaleToFill
                let ratioW = fullNoteCV.bounds.width / notesCV.bounds.width
                let tmp = CGRect(x: 0, y: 0, width: cell.canvasView.bounds.width/ratioW, height: cell.canvasView.bounds.height)

                backgroundImage.frame = cell.canvasView.bounds
                backgroundImage.tag = 234
                backgroundImage.image = noteBackground?.aspectFitImage(inRect: tmp)
                backgroundImage.contentMode = .left
                
//                backgroundImage.translatesAutoresizingMaskIntoConstraints = false
//                backgroundImage.autoresizingMask = [.flexibleBottomMargin, .flexibleHeight, .flexibleWidth, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
                backgroundImage.backgroundColor = .white

                cell.canvasView.insertSubview(backgroundImage, at: 0)

                cell.canvasView.zoomScale = cell.canvasView.minimumZoomScale
                
            }
            
            return cell
            
        } else if collectionView == self.specialCharactersCV {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "specialCharacterCVCell", for: indexPath) as! SpecialCharacterCVCell
            
            cell.character.text = dataManager.specialCharacters[indexPath.row]
            cell.layer.borderWidth = 1
            cell.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
            
            return cell
        
        } else if collectionView == self.fullCalendarCV {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fullCalendarCell", for: indexPath) as! FullCalendarCell
                        
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
            cell.eventsTV.accessibilityIdentifier = cell.id
            cell.eventsTV.reloadData()
            
            return cell
            
        } else {
            return UICollectionViewCell.init()
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == self.specialCharactersCV {
            listTextField.insertText(dataManager.specialCharacters[indexPath.row])
//            print(dataManager.specialCharacters[indexPath.row])
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == self.calenderCV {
            
            let width = calenderCV.bounds.width/2
            let height = calenderCV.bounds.height/CGFloat(numberOfDays/2)
            return CGSize(width: width, height: height)
        
        } else if collectionView == self.notesCV {
            
            return CGSize(width: notesCV.bounds.width, height: notesCV.bounds.height)

        } else if collectionView == self.fullNoteCV {
            
//            return CGSize(width: fullNoteCV.bounds.width, height: (notesCV.bounds.height/notesCV.bounds.width)*fullNoteCV.bounds.width)
            return CGSize(width: fullNoteCV.bounds.width, height: fullNoteCV.bounds.height)

        } else if collectionView == self.specialCharactersCV {
            return CGSize(width: 30, height: 30)
            
        } else if collectionView == self.fullCalendarCV {
            return CGSize(width: fullCalendarCV.bounds.width/7, height: fullCalendarCV.bounds.height/6)
            
        } else {
            return CGSize(width: 0, height: 0)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        if collectionView == notesCV {
            if let tmp = cell as? NoteCVCell {
                if !collectionView.isHidden {
                    toolPicker.setVisible(true, forFirstResponder: tmp.canvasView)
                    tmp.canvasView.becomeFirstResponder()
                    toolPicker.addObserver(tmp.canvasView)
                    toolPicker.addObserver(self)
                    //tmp.canvasView.drawingPolicy // HUR ÄNDRAR JAG DENNA?
                }
            }
        }

        if collectionView == fullNoteCV {
            if let tmp = cell as? FullNoteCVCell {
//                collectionView.contentOffset = CGPoint(x: -500, y: 0)
                if !collectionView.isHidden {
                    toolPicker.setVisible(true, forFirstResponder: tmp.canvasView)
                    tmp.canvasView.becomeFirstResponder()
                    toolPicker.addObserver(tmp.canvasView)
                }
            }
        }

    }
    
    
    
    
    // MARK: MISCEALLENOUS
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        print("canvasViewDrawingDidChange()")
        
        counter += counter
        if counter > 10 {
            updateNote(hideToolpicker: false)
            counter = 0
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        for subview in scrollView.subviews {
            
            if subview.tag == 123 {
                subview.setAnchorPoint(CGPoint(x: 0, y: 0))
                let transformZoom = scaleTransform(for: subview, scaledBy: CGPoint(x: scrollView.zoomScale, y: scrollView.zoomScale), aroundAnchorPoint: subview.layer.anchorPoint)
                subview.transform = transformZoom
            }
            
            if subview.tag == 234 {
                subview.setAnchorPoint(CGPoint(x: 0, y: 0))
                let transformZoom = scaleTransform(for: subview, scaledBy: CGPoint(x: scrollView.zoomScale, y: scrollView.zoomScale), aroundAnchorPoint: subview.layer.anchorPoint)
                subview.transform = transformZoom
            }
            
        }
    }
    
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        print("here")
        print(toolPicker.showsDrawingPolicyControls)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        print("sceneDidDisconnect")
        drawingModelController.saveDrawingModel()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("sceneDidEnterBackground")
    }
    
    
}





//MARK: EXTENSIONS
extension ViewController: EKCalendarChooserDelegate {
    
    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        print("Changed selection")
    }
    
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        print("Cancel tapped")
        dismiss(animated: true, completion: nil)
    }
}

extension Date {
    func adding(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
    
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

extension UITableView {

    func deselectSelectedRow(animated: Bool)
    {
        if let indexPathForSelectedRow = self.indexPathForSelectedRow {
            self.deselectRow(at: indexPathForSelectedRow, animated: animated)
        }
    }

}

extension String {
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    func indexes(of character: String) -> [Int] {
        
        precondition(character.count == 1, "Must be single character")
        
        return self.enumerated().reduce([]) { partial, element  in
            if String(element.element) == character {
                return partial + [element.offset]
            }
            return partial
        }
    }
    
}

extension UIImage {

    func aspectFitImage(inRect rect: CGRect) -> UIImage? {
        let width = self.size.width
        let height = self.size.height
        let aspectWidth = rect.width / width
        let aspectHeight = rect.height / height
        let scaleFactor = aspectWidth > aspectHeight ? rect.size.height / height : rect.size.width / width

        UIGraphicsBeginImageContextWithOptions(CGSize(width: width * scaleFactor, height: height * scaleFactor), false, 0.0)
        self.draw(in: CGRect(x: 0.0, y: 0.0, width: width * scaleFactor, height: height * scaleFactor))

        defer {
            UIGraphicsEndImageContext()
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}


@IBDesignable extension UILabel {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.masksToBounds = true
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}


@IBDesignable extension UIButton {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            //            layer.masksToBounds = true
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}

extension UIView {
    func setAnchorPoint(_ point: CGPoint) {
        var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
        var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y);

        newPoint = newPoint.applying(transform)
        oldPoint = oldPoint.applying(transform)

        var position = layer.position

        position.x -= oldPoint.x
        position.x += newPoint.x

        position.y -= oldPoint.y
        position.y += newPoint.y

        layer.position = position
        layer.anchorPoint = point
    }
}

@IBDesignable extension UIView {
    
    @IBInspectable var radius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
        }
    }
}

@IBDesignable public class Gradient: UIView {
    @IBInspectable var startColor:   UIColor = .black { didSet { updateColors() }}
    @IBInspectable var endColor:     UIColor = .white { didSet { updateColors() }}
    @IBInspectable var startLocation: Double =   0.05 { didSet { updateLocations() }}
    @IBInspectable var endLocation:   Double =   0.95 { didSet { updateLocations() }}
    @IBInspectable var horizontalMode:  Bool =  false { didSet { updatePoints() }}
    @IBInspectable var diagonalMode:    Bool =  false { didSet { updatePoints() }}

    override public class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    func updatePoints() {
        if horizontalMode {
            gradientLayer.startPoint = diagonalMode ? .init(x: 1, y: 0) : .init(x: 0, y: 0.5)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 0, y: 1) : .init(x: 1, y: 0.5)
        } else {
            gradientLayer.startPoint = diagonalMode ? .init(x: 0, y: 0) : .init(x: 0.5, y: 0)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 1, y: 1) : .init(x: 0.5, y: 1)
        }
    }
    func updateLocations() {
        gradientLayer.locations = [startLocation as NSNumber, endLocation as NSNumber]
    }
    func updateColors() {
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePoints()
        updateLocations()
        updateColors()
    }

}

@IBDesignable extension UINavigationController {
    @IBInspectable var barTintColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            navigationBar.barTintColor = uiColor
        }
        get {
            guard let color = navigationBar.barTintColor else { return nil }
            return color
        }
    }
}
