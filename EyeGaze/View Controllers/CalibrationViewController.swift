//
//  CalibrationViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 02/03/2022.
//

import Foundation
import UIKit
import SeeSo
import AVFoundation
import CodableCSV

class CalibrationViewController: UIViewController {
    
    private var predictionEngine: PredictionEngine?
    private var iTrackerModel: iTracker_v2?
    private var seeSoTracker: GazeTracker? = nil
    private var isUsingiTrackerModel: Bool = false
    
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()

    private var calibrationInProgress: Bool = false
    private var dotLayers: [CAShapeLayer] = []
    private var currentDotPredictions: [(Double, Double)] = []
    private var rawGazeEst: (Double, Double) = (0,0)
    private var timers: [Timer] = []
    
    private var dotLocationIndex: Int = 0
    private let dotLocations: [CGPoint] = [CGPoint(x: 20, y: 20), CGPoint(x: 814, y: 20), CGPoint(x: 120, y: 350), CGPoint(x: 400, y: 400), CGPoint(x: 680, y: 450), CGPoint(x: 120, y: 700), CGPoint(x: 400, y: 750), CGPoint(x: 680, y: 800), CGPoint(x: 20, y: 1174), CGPoint(x: 814, y: 1174)]
    private let timeDelayBetweenDots: Double = 2.0
    private var xScaling = 3.0// Scaling factor for iTracker
    private var yScaling = 2.0
    private var xTranslation = 1.5// Translations in cm, converted to screen points in utility function
    private var yTranslation = 9.0

    // Data stores
    private var averagedGazePredictions: [CGPoint] = []// Average gaze prediction in screen coords, one for each calibration point shown.
    private var pointDistances: [CGFloat] = []// Distances between the averagedGazePrediction point and each relevant calibration point in CM.
    private var cornerGazePredictions: [String] = []
    private var dotError: Double = 0.0
    private var xRange: Double = 0.0
    private var yRange: Double = 0.0
    private var xRangeGroundTruth: Double = 0.0
    private var yRangeGroundTruth: Double = 0.0
    private var meanXDeviation: Double = 0.0
    private var meanYDeviation: Double = 0.0
    private var allGazePredictions: [(Int, Double, Double, Double)] = []
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.secondCalibrationDescriptionSegue,
                  let destination = segue.destination as? SecondCalibrationDetailViewController {
            destination.configure(with: self.iTrackerModel!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isUsingiTrackerModel {
            setupCamera()
        } else {
            if AVCaptureDevice .authorizationStatus(for: .video) == .authorized {
                GazeTracker.initGazeTracker(license: "dev_43fxidsg5vglj0ufxnt0j94ybvo8sxs59p5yvm1u", delegate: self)
            }else{
                AVCaptureDevice.requestAccess(for: .video, completionHandler: {
                    response in
                    if response {
                        GazeTracker.initGazeTracker(license: "dev_43fxidsg5vglj0ufxnt0j94ybvo8sxs59p5yvm1u", delegate: self)
                    }
                })
            }
        }
        startCalibration()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        for timer in self.timers {
            timer.invalidate()
        }
        if self.isUsingiTrackerModel {
            self.captureSession.stopRunning()
        } else {
            self.seeSoTracker?.stopTracking()
        }
    }
    
    func configure(with iTrackerModel: iTracker_v2, usingiTrackerModel: Bool) {
        self.predictionEngine = PredictionEngine(model: iTrackerModel)
        self.isUsingiTrackerModel = usingiTrackerModel
        self.iTrackerModel = iTrackerModel
    }
    
    func startCalibration() {
        if self.isUsingiTrackerModel {
            self.captureSession.startRunning()
        } else {
            self.seeSoTracker?.startTracking()
        }
        let firstDotTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(testDotLocation), userInfo: nil, repeats: false)
        self.timers.append(firstDotTimer)
        RunLoop.current.add(firstDotTimer, forMode: .common)
    }
    
    func updateDotData() {
        let averagePoint = PredictionUtilities.averageCGPoint(pointList: self.currentDotPredictions)
        let previousRedDot = self.dotLocations[self.dotLocationIndex-1]
        self.averagedGazePredictions.append(averagePoint)
        // Convert the ground truth and gaze prediction points to CM to calculate distance in CM
        self.pointDistances.append(PredictionUtilities.euclideanDistance(from: PredictionUtilities.screenToPredictionCoordsCG(screenPoint: averagePoint, orientation: CGImagePropertyOrientation.up), to: PredictionUtilities.screenToPredictionCoordsCG(screenPoint: previousRedDot, orientation: CGImagePropertyOrientation.up)))
        drawGreenDot(location: averagePoint)
    }
    
    func calculatePredictionResults() {
        let averagedGazePredictionsCM = PredictionUtilities.screenToPredictionCoords(screenPoints: self.averagedGazePredictions, orientation: .up)
        
        self.dotError = PredictionUtilities.avgArray(array: self.pointDistances)
        let highXPrediction = PredictionUtilities.maxXPoint(pointList: averagedGazePredictionsCM)!
        let lowXPrediction = PredictionUtilities.minXPoint(pointList: averagedGazePredictionsCM)!
        let highYPrediction = PredictionUtilities.maxYPoint(pointList: averagedGazePredictionsCM)!
        let lowYPrediction = PredictionUtilities.minYPoint(pointList: averagedGazePredictionsCM)!
        self.xRange = highXPrediction.0 - lowXPrediction.0
        self.yRange = highYPrediction.1 - lowYPrediction.1
        let xRangeGTPoints = PredictionUtilities.maxXPoint(pointList: self.dotLocations)!.0 - PredictionUtilities.minXPoint(pointList: self.dotLocations)!.0
        self.xRangeGroundTruth = PredictionUtilities.pointsToCMX(xValue: xRangeGTPoints)
        let yRangeGTPoints = PredictionUtilities.maxYPoint(pointList: self.dotLocations)!.1 - PredictionUtilities.minYPoint(pointList: self.dotLocations)!.1
        self.yRangeGroundTruth = PredictionUtilities.pointsToCMY(yValue: yRangeGTPoints)
        self.meanXDeviation = highXPrediction.0 - (self.xRange/2)
        // Magic number is mm from camera to halfway down iPad screen (11 inch)
        self.meanYDeviation = (highYPrediction.1 - (self.yRange/2)) + 11.95
        // Save gaze predictions for four corners, from top left clockwise
        // TODO: fix bug when calibration completes without user looking at all dots
        let numCalPoints = self.averagedGazePredictions.count
        self.cornerGazePredictions.append(NSCoder.string(for: self.averagedGazePredictions[0]))
        self.cornerGazePredictions.append(NSCoder.string(for: self.averagedGazePredictions[1]))
        self.cornerGazePredictions.append(NSCoder.string(for: self.averagedGazePredictions[numCalPoints-1]))
        self.cornerGazePredictions.append(NSCoder.string(for: self.averagedGazePredictions[numCalPoints-2]))
        
        printPredictionResults(averagedGazePredictionsCM: averagedGazePredictionsCM)
    }
    
    func printPredictionResults(averagedGazePredictionsCM: [(Double, Double)]) {
        print("Is using iTracker Gaze prediction implementation: \(self.isUsingiTrackerModel)")
        print("Average Gaze Predictions (Screen coordinate space): \(self.averagedGazePredictions)")
        print("Average Gaze Predictions (Prediction coordinate space): \(averagedGazePredictionsCM)")
        print("Average Gaze Predictions for corners: \(self.cornerGazePredictions)")
        print("Dot locations (Screen coordinate space): \(self.dotLocations)")
        print("Point distances: \(self.pointDistances)")
        print("Dot error: \(self.dotError)cm")
        print("xRange: \(self.xRange)cm, ground truth: \(self.xRangeGroundTruth)cm")
        print("yRange: \(self.yRange)cm, ground truth: \(self.yRangeGroundTruth)cm")
        print("meanXDeviation: \(self.meanXDeviation)cm")
        print("meanYDeviation: \(self.meanYDeviation)cm")
    }
    
    func saveUserCalibrations() {
        let userDefaults = UserDefaults.standard
        if self.isUsingiTrackerModel {
            userDefaults.set(self.cornerGazePredictions, forKey: Constants.cornerAnchorsKeyiTracker)
        } else {
            userDefaults.set(self.cornerGazePredictions, forKey: Constants.cornerAnchorsKeySeeSo)
        }
    }
    
    func writeCalibrationsToFile() {
        let calibrationData = CalibrationData(averagedGazepredictions: self.averagedGazePredictions, pointDistances: self.pointDistances, cornerGazePredictions: self.cornerGazePredictions, dotError: self.dotError, xRange: self.xRange, yRange: self.yRange, xRangeGroundTruth: self.xRangeGroundTruth, yRangeGrountTruth: self.yRangeGroundTruth, meanXDeviation: self.meanXDeviation, meanYDeviation: self.meanYDeviation, allGazePredictions: self.allGazePredictions)
//        calibrationData.averagedGazePredictions = self.averagedGazePredictions
//        calibrationData.pointDistances = self.pointDistances
//        calibrationData.cornerGazePredictions = self.cornerGazePredictions
//        calibrationData.dotError = self.dotError
//        calibrationData.xRange = self.xRange
//        calibrationData.yRange = self.yRange
//        calibrationData.xRangeGroundTruth = self.xRangeGroundTruth
//        calibrationData.yRangeGroundTruth = self.yRangeGroundTruth
//        calibrationData.meanXDeviation = self.meanXDeviation
//        calibrationData.meanYDeviation = self.meanYDeviation
//        
//        calibrationData.formatDataStores()
        
        if self.isUsingiTrackerModel {
            calibrationData.writeCalibrationsToFile(toDocumentNamed: "averagedGazePredictions.csv", forGazeImplementation: .iTracker)
        } else {
            calibrationData.writeCalibrationsToFile(toDocumentNamed: "averagedGazePredictions.csv", forGazeImplementation: .SeeSo)
        }
//        let fileIOController = FileIOController()
//        do {
//            var dict4 = [String:[[CGPoint]]]()
//            dict4["averagedGazePredictions"] = [self.averagedGazePredictions]
////            try fileIOController.write(self.averagedGazePredictions, toDocumentNamed: "calibrationData.csv")
//            try fileIOController.write(self.averagedGazePredictions, toDocumentNamed: "averagedGazePredictions.csv")
//            try fileIOController.write(self.cornerGazePredictions, toDocumentNamed: "cornerGazePredictions.csv")
//        } catch let error {
//            print("File writing error: \(error)")
//        }
        
    }
    
    @objc
    func testDotLocation() {
        let nextDotLocation = self.dotLocations[self.dotLocationIndex]
        self.dotLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
        if self.currentDotPredictions.isEmpty { // When drawing first dot
            self.calibrationInProgress = true // This will start gaze predictions being stored
            drawRedDot(location: nextDotLocation)
        } else {
            updateDotData()
            self.currentDotPredictions = []
            drawRedDot(location: nextDotLocation)
        }
        
        self.dotLocationIndex += 1
        if self.dotLocationIndex < self.dotLocations.count {
            let dotTimer = Timer(timeInterval: self.timeDelayBetweenDots, target: self, selector: #selector(testDotLocation), userInfo: nil, repeats: false)
            self.timers.append(dotTimer)
            RunLoop.current.add(dotTimer, forMode: .common)
        } else {
            let finishTestTimer = Timer(timeInterval: self.timeDelayBetweenDots, target: self, selector: #selector(finishTest), userInfo: nil, repeats: false)
            self.timers.append(finishTestTimer)
            RunLoop.current.add(finishTestTimer, forMode: .common)
        }
    }
    
    @objc
    func finishTest() {
        // Remove last red dot
        self.dotLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
        updateDotData()
        calculatePredictionResults()
        saveUserCalibrations()
        writeCalibrationsToFile()
        self.calibrationInProgress = false
        if self.isUsingiTrackerModel {
            self.captureSession.stopRunning()
            // Dismiss all calibration modals
            var vc: UIViewController = self
            while vc.presentingViewController != nil {
                vc = vc.presentingViewController!
            }
            vc.dismiss(animated: true, completion: nil)
        } else {
            self.seeSoTracker?.stopTracking()
            self.performSegue(withIdentifier: Constants.secondCalibrationDescriptionSegue, sender: self)
        }
    }
}

// Setting up front-facing camera for iTracker
extension CalibrationViewController {
    private func setupCamera() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if self.captureSession.canAddInput(deviceInput) {
                    self.captureSession.addInput(deviceInput)
                    setupVideoDataOutput()
                }
            }
        }
    }
    
    private func setupVideoDataOutput() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera queue"))
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.captureSession.addOutput(self.videoDataOutput)
        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
    }
}

extension CalibrationViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.calibrationInProgress {
            self.predictionEngine!.predictGaze(sampleBuffer: sampleBuffer) { [weak self] result in
                switch result {
                case .success(let prediction):
                    self?.rawGazeEst = prediction
                case .failure(let error):
                    print("Error performing gaze detection: \(error)")
                default:
                    return
                }
            }
            let transformedPrediction = transformPrediction(prediction: self.rawGazeEst)
            self.currentDotPredictions.append(transformedPrediction)
            let timestamp = NSDate().timeIntervalSince1970 * 1000
            self.allGazePredictions.append((self.dotLocationIndex, timestamp, transformedPrediction.0, transformedPrediction.1))
        }
    }
    
    // Transform prediction from prediction space to screen space
    func transformPrediction(prediction: (Double, Double)) -> (Double, Double) {
        let (scaledX, scaledY) = PredictionUtilities.scalePrediction(prediction: prediction, xScaling: self.xScaling, yScaling: self.yScaling, xTranslation: self.xTranslation, yTranslation: self.yTranslation)
        return PredictionUtilities.predictionToScreenCoords(xPrediction: scaledX, yPrediction: scaledY, orientation: CGImagePropertyOrientation.up)
    }
    
}

// Drawing dots
extension CalibrationViewController {
    func drawRedDot(location: CGPoint) {
        let outerDot = UIBezierPath(arcCenter: location, radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        var shapeLayer = CAShapeLayer()
        shapeLayer.path = outerDot.cgPath
        shapeLayer.fillColor = UIColor.red.cgColor
        self.dotLayers.append(shapeLayer)
        view.layer.addSublayer(shapeLayer)
        
        let innerDot = UIBezierPath(arcCenter: location, radius: CGFloat(3), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        shapeLayer = CAShapeLayer()
        shapeLayer.path = innerDot.cgPath
        shapeLayer.fillColor = UIColor.black.cgColor
        self.dotLayers.append(shapeLayer)
        view.layer.addSublayer(shapeLayer)
    }
    func drawGreenDot(location: CGPoint) {
        let outerDot = UIBezierPath(arcCenter: location, radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        var shapeLayer = CAShapeLayer()
        shapeLayer.path = outerDot.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.green.cgColor
        shapeLayer.lineWidth = CGFloat(3)
        view.layer.addSublayer(shapeLayer)
        
        let innerDot = UIBezierPath(arcCenter: location, radius: CGFloat(3), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        shapeLayer = CAShapeLayer()
        shapeLayer.path = innerDot.cgPath
        shapeLayer.fillColor = UIColor.green.cgColor
        view.layer.addSublayer(shapeLayer)
    }
}

extension CalibrationViewController : InitializationDelegate {
    func onInitialized(tracker seeSoTracker: GazeTracker?, error: InitializationError) {
        if (seeSoTracker != nil){
            self.seeSoTracker = seeSoTracker
            print("initalized GazeTracker")
            self.seeSoTracker?.statusDelegate = self
            self.seeSoTracker?.gazeDelegate = self
            _ = self.seeSoTracker?.setTrackingFPS(fps: 15)
            self.seeSoTracker?.startTracking()
        }else{
            print("init failed : \(error.description)")
        }
    }
}

extension CalibrationViewController : StatusDelegate {
    func onStarted() {
        print("SeeSoTracker has started tracking.")
    }
    
    func onStopped(error: StatusError) {
        print("SeeSoTracker has stopped, error : \(error.description)")
    }
}

extension CalibrationViewController : GazeDelegate {
    
    func onGaze(gazeInfo : GazeInfo) {
//        print("timestamp : \(gazeInfo.timestamp), (x , y) : (\(gazeInfo.x), \(gazeInfo.y)) , state : \(gazeInfo.trackingState.description)")
        if (gazeInfo.trackingState == SeeSo.TrackingState.SUCCESS && self.calibrationInProgress) {
            let gazePrediction: (Double, Double) = (gazeInfo.x, gazeInfo.y)
            self.currentDotPredictions.append(gazePrediction)
            self.allGazePredictions.append((self.dotLocationIndex, gazeInfo.timestamp, gazeInfo.x, gazeInfo.y))
        }
    }
}
