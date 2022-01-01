/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's data model for storing drawings, thumbnails, and signatures.
*/

/// Underlying the app's data model is a cross-platform `PKDrawing` object. `PKDrawing` adheres to `Codable`
/// in Swift, or you can fetch its data representation as a `Data` object through its `dataRepresentation()`
/// method. `PKDrawing` is the only PencilKit type supported on non-iOS platforms.

/// From `PKDrawing`'s `image(from:scale:)` method, you can get an image to save, or you can transform a
/// `PKDrawing` and append it to another drawing.

/// If you already have some saved `PKDrawing`s, you can make them available in this sample app by adding them
/// to the project's "Assets" catalog, and adding their asset names to the `defaultDrawingNames` array below.

import UIKit
import PencilKit
import os

/// `DataModel` contains the drawings that make up the data model, including multiple image drawings and a signature drawing.
struct DrawingModel: Codable {
    
    /// The width used for drawing canvases.
    static let dimensions = UIScreen.main.bounds
//    static let canvasWidth: CGFloat = 597 // 834 // 768
//    static let canvasHeight: CGFloat = 784 // 1120 //FANNS INTE INNAN
    
    /// The drawings that make up the current data model.
    var drawings = [[PKDrawing]]()
    var titles: [String] = []
    var categories: [String] = []
    var dateAdded: [Date] = []
    var dateModified: [Date] = []
}

/// `DrawingModelControllerObserver` is the behavior of an observer of data model changes.
protocol DrawingModelControllerObserver {
    /// Invoked when the data model changes.
    func drawingModelChanged()
}

/// `DrawingModelController` coordinates changes to the data  model.
class DrawingModelController {
    
    /// The underlying data model.
    var drawingModel = DrawingModel()
    
    /// Thumbnail images representing the drawings in the data model.
    var thumbnails = [UIImage]()
    var thumbnailTraitCollection = UITraitCollection() {
        didSet {
            print("User interface style changed, regenerating all thumbnails")
            // If the user interface style changed, regenerate all thumbnails.
            if oldValue.userInterfaceStyle != thumbnailTraitCollection.userInterfaceStyle {
                generateAllThumbnails()
            }
        }
    }
    
    /// Dispatch queues for the background operations done by this controller.
    private let thumbnailQueue = DispatchQueue(label: "ThumbnailQueue", qos: .background)
    private let serializationQueue = DispatchQueue(label: "SerializationQueue", qos: .background)
    
    /// Observers add themselves to this array to start being informed of data model changes.
    var observers = [DrawingModelControllerObserver]()
    
    /// The size to use for thumbnail images.
    static let thumbnailSize = CGSize(width: 199, height: 261)
    
    /// Computed property providing access to the drawings in the data model.
    var drawings: [[PKDrawing]] {
        get { drawingModel.drawings }
        set { drawingModel.drawings = newValue }
    }

    var titles: [String] {
        get { drawingModel.titles }
        set { drawingModel.titles = newValue }
    }

    var categories: [String] {
        get { drawingModel.categories }
        set { drawingModel.categories = newValue }
    }
    
    var dateAdded: [Date] {
        get { drawingModel.dateAdded }
        set { drawingModel.dateAdded = newValue }
    }
    
    var dateModified: [Date] {
        get { drawingModel.dateModified }
        set { drawingModel.dateModified = newValue }
    }
    
    var update: Bool = false
    
    /// Initialize a new data model.
    init() {
        print("init() drawingModel")
        loadDrawingModel()
        update = true
    }
    
    /// Update a drawing at `index` and generate a new thumbnail.
    func updateDrawing(_ drawing: PKDrawing, at mainIndex: Int, at subIndex: Int) {
        print("updateDrawing() at: " + "\(mainIndex)" + " and sub: " + "\(subIndex)")
        
        drawingModel.drawings[mainIndex][subIndex] = drawing
        drawingModel.dateModified[mainIndex] = Date()
        
        generateThumbnail(mainIndex)
//        saveDrawingModel() //TESTAR ATT KOMMENTERA BORT DETTA, MÅSTE KANSKE INTE SPARA VARJE GÅNG
    }
    
    /// Helper method to cause regeneration of all thumbnails.
    private func generateAllThumbnails() {
        print("generateAllThumbnails()")
        
        if !drawings.isEmpty {
            for index in drawings.indices {
                generateThumbnail(index)
            }
//        } else {
//            didChange()
        }
        
        didChange()
    }
    
    /// Helper method to cause regeneration of a specific thumbnail, using the current user interface style
    /// of the thumbnail view controller.
    private func generateThumbnail(_ index: Int) {
        print("generateThumbnail()")
        
        var thumbnailRect = CGRect()

        if DrawingModel.dimensions.width > DrawingModel.dimensions.height {
            thumbnailRect = CGRect(x: 0, y: 0, width: DrawingModel.dimensions.width/2, height: DrawingModel.dimensions.height)
        } else {
            thumbnailRect = CGRect(x: 0, y: 0, width: DrawingModel.dimensions.height/2, height: DrawingModel.dimensions.width)
        }
        
        let drawing = drawings[index][0]
        
        let thumbnailScale = UIScreen.main.scale * DrawingModelController.thumbnailSize.width / DrawingModelController.thumbnailSize.height // DrawingModel.canvasHeight
        let traitCollection = thumbnailTraitCollection

        thumbnailQueue.async {
            traitCollection.performAsCurrent {
                let image = drawing.image(from: thumbnailRect, scale: thumbnailScale)
                DispatchQueue.main.async {
                    self.thumbnails[index] = image
//                    self.updateThumbnail(image, at: index)
                }
            }
//            self.didChange()
        }
    }
    
//    /// Helper method to replace a thumbnail at a given index.
//    private func updateThumbnail(_ image: UIImage, at index: Int) {
//        print("updateThumbnail(" + "\(index)" + ")")
//
//        thumbnails[index] = image
//        if update {
//            didChange()
//            update = false
//        }
//    }
    
    /// Helper method to notify observer that the data model changed.
    private func didChange() {
        print("didChange()")
        for observer in self.observers {
            observer.drawingModelChanged()
        }
    }
    
    /// The URL of the file in which the current data model is saved.
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths.first!
//        return documentsDirectory.appendingPathComponent("NeverLate.data")
        return documentsDirectory.appendingPathComponent("test7.data")
    }
    
    /// Save the data model to persistent storage.
    func saveDrawingModel() {
        print("saveDrawingModel()")
        
        let savingDrawingModel = drawingModel
        let url = saveURL
        serializationQueue.async {
            do {
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(savingDrawingModel)
                try data.write(to: url)
                print("Data saved")
            } catch {
                os_log("Could not save data model: %s", type: .error, error.localizedDescription)
            }
        }
    }
    
    /// Load the data model from persistent storage
    func loadDrawingModel() {
        print("loadDrawingModel()")
        var worked = true
        
        let url = saveURL
        serializationQueue.async {
            // Load the data model, or the initial test data.
            let drawingModel: DrawingModel
            
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let decoder = PropertyListDecoder()
                    let data = try Data(contentsOf: url)
                    drawingModel = try decoder.decode(DrawingModel.self, from: data)

                    DispatchQueue.main.async {
                        self.setLoadedDrawingModel(drawingModel)
                    }

                } catch {
                    os_log("Could not load data model: %s", type: .error, error.localizedDescription)
                }
            } else {
                DispatchQueue.main.async {
                    self.didChange()
                }
                print("File does not exist")
            }
            
        }
        
    }
    
    /// Helper method to set the current data model to a data model created on a background queue.
    private func setLoadedDrawingModel(_ drawingModel: DrawingModel) {
        print("setLoadedDrawingModel()")
        
        self.drawingModel = drawingModel
        thumbnails = Array(repeating: UIImage(), count: drawingModel.drawings.count)
        generateAllThumbnails()
    }
    
    /// Create a new drawing in the data model.
    func newDrawing(title: String, category: String) {
        print("newDrawing()")
        
        let newDrawing = PKDrawing()
        drawingModel.drawings.append([newDrawing]) //Skapar en ny drawing, som kan senare innehålla subDrawings
        drawingModel.titles.append(title)
        drawingModel.categories.append(category)
        drawingModel.dateAdded.append(Date())
        drawingModel.dateModified.append(Date())
        
        thumbnails.append(UIImage())
        updateDrawing(newDrawing, at: drawingModel.drawings.count-1, at: 0)
    }
    
    func newSubDrawing(mainIndex: Int) {
        print("newSubDrawing()")
        
        let newDrawing = PKDrawing()
        drawingModel.drawings[mainIndex].append(newDrawing)
        updateDrawing(newDrawing, at: mainIndex, at: drawingModel.drawings[mainIndex].count-1)
    }
}
