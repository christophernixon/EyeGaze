//
//  StaticTestViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 27/01/2022.
//

import UIKit
import AVFoundation

class StaticTestViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var predictionEngine: PredictionEngine?
    private var dotLocationIndex: Int = 0
    private var testInProgress = false
    
    private var xScaling = 3.0
    private var yScaling = 2.0
    // Translations in cm, converted to screen points in utility function
    private var xTranslation = 1.5
    private var yTranslation = 9.0
    
//    private var xScaling = 1.0
//    private var yScaling = 1.0
//    // Translations in cm, converted to screen points in utility function
//    private var xTranslation = 0.0
//    private var yTranslation = 0.0
    
    private static let dotLocations: [CGPoint] = [CGPoint(x: 200, y: 200), CGPoint(x: 600, y: 200), CGPoint(x: 120, y: 450), CGPoint(x: 400, y: 450), CGPoint(x: 680, y: 450), CGPoint(x: 200, y: 700), CGPoint(x: 600, y: 700), CGPoint(x: 120, y: 950), CGPoint(x: 400, y: 950), CGPoint(x: 680, y: 950)]
    private static let initialDelay: Double = 0.5
    private let dotDelay: Double = 2.0
    private var dotLayers: [CAShapeLayer] = []
    private var testCurrGazeLocLayers: [CAShapeLayer] = []
    
    // Data stores
    private var rawGazeEst: (Double, Double) = (0,0)
    private var gazePredictions: [(Double,Double)] = []
    private var gazePredictionsCM: [(Double,Double)] = []
    private var averageGazePredictions: [CGPoint] = []
    private var averageGazePredictionsCM: [(Double,Double)] = []
    private var pointDistances: [CGFloat] = []
    private var dotError: Double = 0.0
    private var meanXDeviation: Double = 0.0
    private var meanYDeviation: Double = 0.0
    private var xRange: Double = 0.0
    private var yRange: Double = 0.0
    private var xRangeGroundTruth: Double = 0.0
    private var yRangeGroundTruth: Double = 0.0
    
    func configure(with iTrackerModel: iTracker_v2) {
        self.predictionEngine = PredictionEngine(model: iTrackerModel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        startTest()
    }
    
    private func setupCamera() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
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
    
    func startTest() {
        captureSession.startRunning()
        let firstDotTimer = Timer(timeInterval: Self.initialDelay, target: self, selector: #selector(testDotLocation), userInfo: nil, repeats: false)
        RunLoop.current.add(firstDotTimer, forMode: .common)
    }
    
    @objc
    func testDotLocation() {
//        for gazePrediction in self.gazePredictions {
//            drawBlueDot(location: PredictionUtilities.cgPointFromDoubleTuple(doubleTuple: gazePrediction))
//        }
        let dotLocation = Self.dotLocations[self.dotLocationIndex]
        if self.gazePredictions.isEmpty { // When drawing first dot
            self.testInProgress = true // This will start gaze predictions being stored
            drawRedDot(location: dotLocation)
            self.dotLocationIndex += 1
        } else {
            // Remove all previous dots
            self.dotLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
            // Draw gaze prediction dot and store value
            let averagePoint = PredictionUtilities.averageCGPoint(pointList: self.gazePredictions)
            let averagePointCM = PredictionUtilities.averagePoint(pointList: self.gazePredictionsCM)
            drawGreenDot(location: averagePoint)
            self.averageGazePredictions.append(averagePoint)
            self.averageGazePredictionsCM.append(averagePointCM)
            self.pointDistances.append(PredictionUtilities.euclideanDistance(from: PredictionUtilities.cgPointFromDoubleTuple(doubleTuple: averagePointCM), to:  PredictionUtilities.screenToPredictionCoordsCG(screenPoint: Self.dotLocations[self.dotLocationIndex-1], orientation: CGImagePropertyOrientation.up)))
            // Draw next red dot
            drawRedDot(location: dotLocation)
            self.dotLocationIndex += 1
            // Reset gaze prediction arrays
            self.gazePredictions = []
            self.gazePredictionsCM = []
        }
        if self.dotLocationIndex < Self.dotLocations.count {
            let dotTimer = Timer(timeInterval: self.dotDelay, target: self, selector: #selector(testDotLocation), userInfo: nil, repeats: false)
            RunLoop.current.add(dotTimer, forMode: .common)
        } else {
            let finishTestTimer = Timer(timeInterval: self.dotDelay, target: self, selector: #selector(finishTest), userInfo: nil, repeats: false)
            RunLoop.current.add(finishTestTimer, forMode: .common)
        }
    }
    
    @objc
    func finishTest() {
        // Remove last red dot
        self.dotLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
        // Store and draw dot for last gaze prediction
        let averagePoint = PredictionUtilities.averageCGPoint(pointList: self.gazePredictions)
        let averagePointCM = PredictionUtilities.averagePoint(pointList: self.gazePredictionsCM)
        drawGreenDot(location: averagePoint)
        self.averageGazePredictions.append(averagePoint)
        self.averageGazePredictionsCM.append(averagePointCM)
        // Last dot location
        let dotLocation = Self.dotLocations[self.dotLocationIndex-1]
        self.pointDistances.append(PredictionUtilities.euclideanDistance(from: PredictionUtilities.cgPointFromDoubleTuple(doubleTuple: averagePointCM), to:  PredictionUtilities.screenToPredictionCoordsCG(screenPoint: dotLocation, orientation: CGImagePropertyOrientation.up)))
        
        calculatePredictionResults()
        
        // Draw all red dots again
        for location in Self.dotLocations {
            drawRedDot(location: location)
        }
        // Draw all gaze predictions for last point (testing purposes)
//        for gazePrediction in self.gazePredictions {
//            drawBlueDot(location: PredictionUtilities.cgPointFromDoubleTuple(doubleTuple: gazePrediction))
//        }
        // Stop gaze predictions being collected/stored.
        self.testInProgress = false
    }
    
    func calculatePredictionResults() {
        self.dotError = PredictionUtilities.avgArray(array: self.pointDistances)
        let highXPrediction = PredictionUtilities.maxXPoint(pointList: self.averageGazePredictionsCM)!
        let lowXPrediction = PredictionUtilities.minXPoint(pointList: self.averageGazePredictionsCM)!
        self.xRange = highXPrediction.0 - lowXPrediction.0
        let highYPrediction = PredictionUtilities.maxYPoint(pointList: self.averageGazePredictionsCM)!
        let lowYPrediction = PredictionUtilities.minYPoint(pointList: self.averageGazePredictionsCM)!
        self.yRange = highYPrediction.1 - lowYPrediction.1
        let xRangeGTPoints = PredictionUtilities.maxXPoint(pointList: Self.dotLocations)!.0 - PredictionUtilities.minXPoint(pointList: Self.dotLocations)!.0
        self.xRangeGroundTruth = PredictionUtilities.pointsToCMX(xValue: xRangeGTPoints)
        let yRangeGTPoints = PredictionUtilities.maxYPoint(pointList: Self.dotLocations)!.1 - PredictionUtilities.minYPoint(pointList: Self.dotLocations)!.1
        self.yRangeGroundTruth = PredictionUtilities.pointsToCMY(yValue: yRangeGTPoints)
        self.meanXDeviation = highXPrediction.0 - (self.xRange/2)
        // Magic number is mm from camera to halfway down iPad screen (11 inch)
        self.meanYDeviation = (highYPrediction.1 - (self.yRange/2)) + 11.95
        
        print("Average Gaze Predictions (Screen coordinate space): \(self.averageGazePredictions)")
        print("Average Gaze Predictions (Prediction coordinate space): \(self.averageGazePredictionsCM)")
        print("Point distances: \(self.pointDistances)")
        print("Dot error: \(self.dotError)cm")
        print("xRange: \(self.xRange)cm, ground truth: \(self.xRangeGroundTruth)cm")
        print("yRange: \(self.yRange)cm, ground truth: \(self.yRangeGroundTruth)cm")
        print("meanXDeviation: \(self.meanXDeviation)cm")
        print("meanYDeviation: \(self.meanYDeviation)cm")
    }
    
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
    
    func drawBlueDot(location: CGPoint) {
        self.testCurrGazeLocLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
        let innerDot = UIBezierPath(arcCenter: location, radius: CGFloat(12), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = innerDot.cgPath
        shapeLayer.fillColor = UIColor.blue.cgColor
        self.testCurrGazeLocLayers.append(shapeLayer)
        view.layer.addSublayer(shapeLayer)
    }
}

extension StaticTestViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if testInProgress {
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
            self.gazePredictions.append(transformedPrediction)
            self.gazePredictionsCM.append(PredictionUtilities.scalePrediction(prediction: self.rawGazeEst, xScaling: self.xScaling, yScaling: self.yScaling, xTranslation: self.xTranslation, yTranslation: self.yTranslation))
            DispatchQueue.main.sync {
                self.drawBlueDot(location: PredictionUtilities.cgPointFromDoubleTuple(doubleTuple: transformedPrediction))
            }
        }
//        print(self.gazePredictions)
    }
    
    // Transform prediction from prediction space to screen space
    func transformPrediction(prediction: (Double, Double)) -> (Double, Double) {
        let (scaledX, scaledY) = PredictionUtilities.scalePrediction(prediction: prediction, xScaling: self.xScaling, yScaling: self.yScaling, xTranslation: self.xTranslation, yTranslation: self.yTranslation)
        return PredictionUtilities.predictionToScreenCoords(xPrediction: scaledX, yPrediction: scaledY, orientation: CGImagePropertyOrientation.up)
    }
}
