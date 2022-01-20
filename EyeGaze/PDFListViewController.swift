//
//  ViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 21/12/2021.
//

import PDFKit
import UIKit
import Vision

class PDFListViewController: UITableViewController {

    @IBOutlet var testImage: UIImageView!
    
    static let showPDFSegueIdentifier = "ShowPDFSegue"
    static let liveFeedViewSegue = "showLiveFeedSegue"
    static let staticViewSegue = "showStaticViewSegue"
    
    private var pdfListDataSource: PDFListDataSource?
    private var iTrackerModel: iTracker?
    
    var faceRect: CGRect?
    var currentGazeEstimate: (Double,Double)?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.showPDFSegueIdentifier,
           let destination = segue.destination as? PDFViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let pdf = PDF.testData[indexPath.row]
            destination.configure(with: pdf)
        } else if segue.identifier == Self.liveFeedViewSegue,
                  let destination = segue.destination as? LiveFeedViewController {
            destination.configure(with: self.iTrackerModel!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pdfListDataSource = PDFListDataSource()
        tableView.dataSource = pdfListDataSource
        navigationItem.title = NSLocalizedString("Sheet Music Library", comment: "PDFList nav title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(segueToLiveFeed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(segueToStaticFeed))
        predict()
    }
    
    func predict() {
//        let faceGridInput = UIImage(named: "sample_data_face_grid")
//        let faceGrid = PredictionUtilities.buffer(from: faceGridInput!, isGreyscale: true)
        
        // Load eye and face images, convert to CVPixelBuffer
        let leftEyeInput = UIImage(named: "sample2_data_left_eye")
        let rightEyeInput = UIImage(named: "sample2_data_right_eye")
        let faceInput = UIImage(named: "sample2_data_face")
        let leftEye = PredictionUtilities.buffer(from: leftEyeInput!, isGreyscale: false)
        let rightEye = PredictionUtilities.buffer(from: rightEyeInput!, isGreyscale: false)
        let face = PredictionUtilities.buffer(from: faceInput!, isGreyscale: false)
        
        // Set up facegrid as mlmultiarray
        let doubles: [Double] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        let shape = [1, 625, 1] as [NSNumber]
        guard let doubleMultiarray = try? MLMultiArray(shape: shape, dataType: .float) else {
            fatalError("Couldn't initialise mlmultiarry from facegrid")
        }
        for (i, element) in doubles.enumerated() {
            let key = [0, i, 0] as [NSNumber]
            doubleMultiarray[key] = element as NSNumber
        }
        
        // Prediction
        var iTrackerModel: iTracker
        do {
            iTrackerModel = try iTracker(configuration: MLModelConfiguration())
            self.iTrackerModel = iTrackerModel
            guard let gazePredictionOutput = try? iTrackerModel.prediction(facegrid: doubleMultiarray, image_face: face!, image_left: leftEye!, image_right: rightEye!) else {
                fatalError("Unexpected runtime error with prediction")
            }
            let result = gazePredictionOutput.fc3
            print("Manual Gaze Prediction: [\(result[0]),\(result[1])]")
//            if let b = try? UnsafeBufferPointer<Double>(result) {
//              let c = Array(b)
//              print(c)
//            }
        } catch {
            fatalError("Error while initialising iTracker model")
        }
        
        // Detect Features
        let imageForDetection = UIImage(named: "sample2_data")
        // Test facegrid function
//        PredictionUtilities.faceGridFromFaceRect(originalImage: imageForDetection, detectedFaceRect: <#T##CGRect#>, gridW: <#T##Int#>, gridH: <#T##Int#>)
        
//        testImage.image = imageForDetection
        let featureDetector = DetectFeatures()
        featureDetector.detectFeatures(model: iTrackerModel, image: (imageForDetection?.cgImage)!) { [weak self] result in
            switch result {
            case .success(let (xPos, yPos)):
                DispatchQueue.main.async {
//                    self?.testImage.image = UIImage(cgImage: cgImage[2]).resized(to: CGSize(width: 224, height: 224))
//                    self?.faceRect = detectedFaceRect
                    self?.currentGazeEstimate = (xPos, yPos)
                    print(self?.currentGazeEstimate)
                }
            case .notFound:
                print("Face or facial features not found")
                DispatchQueue.main.async { self?.testImage.image = imageForDetection }
            case .failure(let error):
                print("Unexpected error while trying to detect face and eyes: \(error).")
                DispatchQueue.main.async { self?.testImage.image = imageForDetection }
            }
        }
    }
    
    @objc
    func segueToLiveFeed() {
        self.performSegue(withIdentifier: Self.liveFeedViewSegue, sender: self)
    }
    
    @objc
    func segueToStaticFeed() {
        self.performSegue(withIdentifier: Self.staticViewSegue, sender: self)
    }
}

