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
    
    @IBOutlet var gazeImplementationSegmentedControl: UISegmentedControl!
    
    private var pdfListDataSource: PDFListDataSource?
    private var iTrackerModel: iTracker_v2?
    
    private var pageTurningImplementation: PageTurningImplementation = .scrolling
    private var gazeDetectionImplementation: GazeDetectionImplementation = .SeeSo
    
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
            destination.configure(with: pdf, pageTurningImplementation: self.pageTurningImplementation, gazeTrackingImplementation: self.gazeDetectionImplementation, iTrackerModel: self.iTrackerModel!)
        } else if segue.identifier == Constants.showDoubleAnimatedPDFSegue,
                  let destination = segue.destination as? TwoPartAnimationViewController,
                  let cell = sender as? UITableViewCell,
                  let indexPath = tableView.indexPath(for: cell) {
            let pdf = PDF.testData[indexPath.row]
            destination.configure(with: pdf, pageTurningImplementation: self.pageTurningImplementation, gazeDetectionMethod: self.gazeDetectionImplementation)
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
        do {
            self.iTrackerModel = try iTracker_v2(configuration: MLModelConfiguration())
        } catch {
            fatalError("Error while initialising iTracker model")
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "calibrationDescriptionModalVC")
        self.present(vc, animated: true)

    }
    
    func predict() {
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
        } catch {
            fatalError("Error while initialising iTracker model")
        }
        
        // Detect Features
        guard let imageForDetection = UIImage(named: "sample2_data") else { return }
        
        let predictionEngine = PredictionEngine(model: iTrackerModel)
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
    

    @IBAction func gazeImplementationControlChanged(_ sender: Any) {
        self.gazeDetectionImplementation = GazeDetectionImplementation(rawValue: gazeImplementationSegmentedControl.selectedSegmentIndex) ?? .SeeSo
    }
}

// Delegate extensions
extension PDFListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch self.pageTurningImplementation {
        case .scrolling:
            if (self.gazeDetectionImplementation == .SeeSo) {
                self.performSegue(withIdentifier: Constants.showPDFSegue, sender: cell)
            } else {
                self.performSegue(withIdentifier: Constants.showPDFiTrackerSegue, sender: cell)
            }
        case .singleAnimation:
            self.performSegue(withIdentifier: Constants.showAnimatedPDFSegue, sender: cell)
        case .doubleAnimation:
            self.performSegue(withIdentifier: Constants.showDoubleAnimatedPDFSegue, sender: cell)
        }
    }
    
}

