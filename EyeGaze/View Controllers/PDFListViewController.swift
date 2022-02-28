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
    @IBOutlet var implementationSegmentedControl: UISegmentedControl!
    
    private var pdfListDataSource: PDFListDataSource?
    private var iTrackerModel: iTracker_v2?
    
    private var pageTurningImplementation: PageTurningImplementation = .scrolling
    
    var faceRect: CGRect?
    var currentGazeEstimate: (Double,Double)?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.showPDFSegue,
           let destination = segue.destination as? PDFViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let pdf = PDF.testData[indexPath.row]
            destination.configure(with: pdf, pageTurningImplementation: self.pageTurningImplementation)
        } else if segue.identifier == Constants.showPDFiTrackerSegue,
                  let destination = segue.destination as? PDFViewControllerITracker,
                  let cell = sender as? UITableViewCell,
                  let indexPath = tableView.indexPath(for: cell) {
            let pdf = PDF.testData[indexPath.row]
            destination.configure(with: pdf, pageTurningImplementation: self.pageTurningImplementation, iTrackerModel: self.iTrackerModel!)
        } else if segue.identifier == Constants.showAnimatedPDFSegue,
                  let destination = segue.destination as? ParentAnimatedPDFViewController,
                  let cell = sender as? UITableViewCell,
                  let indexPath = tableView.indexPath(for: cell) {
            let pdf = PDF.testData[indexPath.row]
            destination.configure(with: pdf, pageTurningImplementation: self.pageTurningImplementation)
        } else if segue.identifier == Constants.showDoubleAnimatedPDFSegue,
                  let destination = segue.destination as? ModalPDFViewController,
                  let cell = sender as? UITableViewCell,
                  let indexPath = tableView.indexPath(for: cell) {
            let pdf = PDF.testData[indexPath.row]
            destination.configure(with: pdf, pageTurningImplementation: self.pageTurningImplementation)
        } else if segue.identifier == Constants.liveFeedViewSegue,
                  let destination = segue.destination as? LiveFeedViewController {
            destination.configure(with: self.iTrackerModel!)
        } else if segue.identifier == Constants.debugViewSegue,
                  let destination = segue.destination as? DebugViewController {
            destination.configure(with: self.iTrackerModel!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pdfListDataSource = PDFListDataSource()
        tableView.dataSource = pdfListDataSource
        navigationItem.title = NSLocalizedString("Sheet Music Library", comment: "PDFList nav title")
        do {
            self.iTrackerModel = try iTracker_v2(configuration: MLModelConfiguration())
        } catch {
            fatalError("Error while initialising iTracker model")
        }
        //        navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(segueToLiveFeed)), UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(segueToDebugView))]
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(segueToStaticFeed))
        //        predict()
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
        var iTrackerModel: iTracker_v2
        do {
            iTrackerModel = try iTracker_v2(configuration: MLModelConfiguration())
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
        guard let imageForDetection = UIImage(named: "sample2_data") else { return }
        // Test facegrid function
        //        PredictionUtilities.faceGridFromFaceRect(originalImage: imageForDetection, detectedFaceRect: <#T##CGRect#>, gridW: <#T##Int#>, gridH: <#T##Int#>)
        
        //        testImage.image = imageForDetection
        
        let predictionEngine = PredictionEngine(model: iTrackerModel)
//        let gazePrediction = predictionEngine.predictGaze(image: imageForDetection.cgImage!) { [weak self] result in
//            switch result {
//                case
//            }
//        }
//        print(gazePrediction)
//        print(predictionEngine.currentGazePredictionCM)
//        DispatchQueue.main.async {
//            if let faceCGImage = predictionEngine.faceCGImage {
//                self.testImage.image = UIImage(cgImage: faceCGImage)
//            } else {
//                self.testImage.image = imageForDetection
//            }
//        }
        //        let featureDetector = DetectFeatures()
        //        featureDetector.detectFeatures(model: iTrackerModel, image: (imageForDetection?.cgImage)!) { [weak self] result in
        //            switch result {
        //            case .success(let (xPos, yPos, rawImages)):
        //                DispatchQueue.main.async {
        ////                    self?.testImage.image = UIImage(cgImage: rawImages[1])
        ////                    self?.faceRect = detectedFaceRect
        //                    self?.currentGazeEstimate = (xPos, yPos)
        //                    print(self?.currentGazeEstimate)
        //                }
        //            case .notFound:
        //                print("Face or facial features not found")
        //                DispatchQueue.main.async { self?.testImage.image = imageForDetection }
        //            case .failure(let error):
        //                print("Unexpected error while trying to detect face and eyes: \(error).")
        //                DispatchQueue.main.async { self?.testImage.image = imageForDetection }
        //            }
        //        }
    }
    
    @objc
    func segueToLiveFeed() {
        self.performSegue(withIdentifier: Constants.liveFeedViewSegue, sender: self)
    }
    
    @objc
    func segueToStaticFeed() {
        self.performSegue(withIdentifier: Constants.staticViewSegue, sender: self)
    }
    
    @objc
    func segueToDebugView() {
        self.performSegue(withIdentifier: Constants.debugViewSegue, sender: self)
    }
    
    
    @IBAction func implementationControlChanged(_ sender: Any) {
        self.pageTurningImplementation = PageTurningImplementation(rawValue: implementationSegmentedControl.selectedSegmentIndex) ?? .scrolling
    }
}

// Delegate extensions
extension PDFListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch self.pageTurningImplementation {
        case .scrolling:
            self.performSegue(withIdentifier: Constants.showPDFiTrackerSegue, sender: cell)
        case .singleAnimation:
            self.performSegue(withIdentifier: Constants.showAnimatedPDFSegue, sender: cell)
        case .doubleAnimation:
            self.performSegue(withIdentifier: Constants.showDoubleAnimatedPDFSegue, sender: cell)
        }
    }
    
}

