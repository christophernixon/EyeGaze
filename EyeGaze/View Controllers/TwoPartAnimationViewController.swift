//
//  TwoPartAnimationViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 11/03/2022.
//

import Foundation
import UIKit
import PDFKit
import SeeSo
import Vision
import AVFoundation

class TwoPartAnimationViewController: UIViewController {
    
    @IBOutlet var faceVisibilityWarningLabel: UILabel!
    
    private var pdf: PDF?
    // All subviews, each a page of the PDF. first element is final page
    private var pages: [UIView] = []
    private var currentPageNumber: Int = 1
    
    private var pageTurningImplementation: PageTurningImplementation = .doubleAnimation
    private var gazeDetectionMethod: GazeDetectionImplementation = .iTracker
    private var predictionEngine: PredictionEngine?
    private var seeSoTracker: GazeTracker? = nil
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var rawGazeEst: (Double, Double) = (0,0)
    private var isFaceVisible: Bool = false
    private var gazeEstimations: [(Double, Double)] = [(Double, Double)] (repeating: (0.0,0.0), count: Constants.rollingAverageWindowSize)
    private var currAvgGazeEst: CGPoint = CGPoint(x: 0, y: 0)
    // Parameters
    private var xScaling = 3.0
    private var yScaling = 2.0
    // translations in cm
    private var xTranslation = 1.5
    private var yTranslation = 9.0
    private var pageIsHalfTurned: Bool = false
    // Thresholds
    private var bottomRightCornerThreshold: CGPoint = CGPoint(x: Constants.iPadScreenWidthPoints/3, y: Constants.iPadScreenHeightPoints - Constants.iPadScreenHeightPoints/5)
    private var topLeftCornerThreshold: CGPoint = CGPoint(x: Constants.iPadScreenWidthPoints, y: Constants.iPadScreenHeightPoints/3)
    private var canHalfTurnPage: Bool = true
    private var canFullyTurnPage: Bool = false
    
    func maskPath(cornerRadius: CGFloat) -> UIBezierPath {
        let fullRect = UIBezierPath(rect: CGRect(x: self.view.frame.minX, y: self.view.frame.minY + self.view.frame.height/2, width: self.view.frame.width, height: self.view.frame.height/2))
        return fullRect
    }
    
    func configure(with pdf: PDF, pageTurningImplementation implementation: PageTurningImplementation, gazeDetectionMethod: GazeDetectionImplementation) {
        self.pdf = pdf
        self.pageTurningImplementation = implementation
        self.gazeDetectionMethod = gazeDetectionMethod
        if gazeDetectionMethod == .iTracker {
            do {
                print("Initialising iTracker model")
                self.predictionEngine = PredictionEngine(model: try iTracker_v2(configuration: MLModelConfiguration()))
            } catch {
                // Fall back to SeeSo
                print("Error while initialising iTracker model")
                self.gazeDetectionMethod = .SeeSo
            }
        }
    }
    
    func loadUserDefaults() {
        let userDefaults = UserDefaults.standard
        var cornerAnchorsStrings: [String] = [String]()
        if self.gazeDetectionMethod == .iTracker {
            cornerAnchorsStrings = userDefaults.object(forKey: Constants.cornerAnchorsKeyiTracker) as? [String] ?? [String]()
        } else {
            cornerAnchorsStrings = userDefaults.object(forKey: Constants.cornerAnchorsKeySeeSo) as? [String] ?? [String]()
        }
        if cornerAnchorsStrings.count != 4 {
            print("No user calibration recieved, using default values for thresholds.")
        } else {
            var cornerAnchors: [CGPoint] = []
            for point in cornerAnchorsStrings {
                cornerAnchors.append(NSCoder.cgPoint(for: point))
            }
            let bottomScreenWidth = cornerAnchors[2].x - cornerAnchors[3].x
            let bottomRightThresholdX = cornerAnchors[2].x - bottomScreenWidth/2
            let rightScreenHeight = cornerAnchors[2].y - cornerAnchors[1].y
            let bottomRightThresholdY = cornerAnchors[2].y - rightScreenHeight/6
            print("Updated bottom right threshold using calibration, previous: \(self.bottomRightCornerThreshold), updated: (\(bottomRightThresholdX),\(bottomRightThresholdY))")
            self.bottomRightCornerThreshold = CGPoint(x: bottomRightThresholdX, y: bottomRightThresholdY)
            let leftScreenHeight = cornerAnchors[3].y - cornerAnchors[0].y
            let topLeftThresholdY = cornerAnchors[0].y + leftScreenHeight/3
            print("Updated top left threshold using calibration, previous: \(self.topLeftCornerThreshold), updated: (\(self.topLeftCornerThreshold.x),\(topLeftThresholdY))")
            self.topLeftCornerThreshold = CGPoint(x: self.topLeftCornerThreshold.x, y: topLeftThresholdY)
        }
    }
    
    func startTracking() {
        if self.gazeDetectionMethod == .iTracker {
            self.captureSession.startRunning()
        } else {
            self.seeSoTracker?.startTracking()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
        if self.gazeDetectionMethod == .iTracker {
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
        startTracking()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        let pageCount = (self.pdf?.document.pageCount ?? 1) - 1
        for index in stride(from: pageCount, through: 0, by: -1) {
            //        for index in 0...pageCount {
            let page: PDFPage = (self.pdf?.document.page(at: index)!)!
            let pdfView: PDFView = PDFView(frame: self.view.frame)
            pdfView.document = self.pdf?.document
            pdfView.displayMode = .singlePage
            pdfView.go(to: page)
            pdfView.autoScales = true
            //            let vc = UIViewController()
            //            vc.view = pdfView
            //            self.pages.append(vc)
            self.pages.append(pdfView)
            self.view.addSubview(pdfView)
        }
        //        self.pages.last?.mask = MaskView(frame: self.view.frame)
        
        //        let timer = Timer(timeInterval: 2.0, target: self, selector: #selector(halfTurnPage), userInfo: nil, repeats: true)
        //        RunLoop.current.add(timer, forMode: .common)
        //
        //        let secondTimer = Timer(timeInterval: 3.0, target: self, selector: #selector(fullyTurnPage), userInfo: nil, repeats: true)
        //        RunLoop.current.add(secondTimer, forMode: .common)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.gazeDetectionMethod == .iTracker {
            self.captureSession.stopRunning()
        } else {
            self.seeSoTracker?.stopTracking()
        }
    }
}

// Gaze detection functions rlevant to iTracker and SeeSo
extension TwoPartAnimationViewController {
    
    func checkIfPageShouldTurn() {
        if (self.isFaceVisible && !self.pageIsHalfTurned && self.canHalfTurnPage && self.currAvgGazeEst.x > self.bottomRightCornerThreshold.x && self.currAvgGazeEst.y > self.bottomRightCornerThreshold.y) {
            // Prevent page being turning more than once
            self.canHalfTurnPage = false
            self.canFullyTurnPage = true
            let timer = Timer(timeInterval: 0.1, target: self, selector: #selector(halfTurnPage), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            let unlockTimer = Timer(timeInterval: 1.5, target: self, selector: #selector(resetHalfPageTurningBlock), userInfo: nil, repeats: false)
            RunLoop.main.add(unlockTimer, forMode: .common)
        } else if (self.isFaceVisible && self.pageIsHalfTurned && self.canFullyTurnPage && self.currAvgGazeEst.x < self.topLeftCornerThreshold.x && self.currAvgGazeEst.y < self.topLeftCornerThreshold.y) {
            self.canFullyTurnPage = false
            let timer = Timer(timeInterval: 0.1, target: self, selector: #selector(fullyTurnPage), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            let unlockTimer = Timer(timeInterval: 1.5, target: self, selector: #selector(resetFullPageTurningBlock), userInfo: nil, repeats: false)
            RunLoop.main.add(unlockTimer, forMode: .common)
        }
    }
    
    func updateRollingAverage(gazePrediction: (Double, Double)) {
        // Calculate rolling average
        var sumX = 0.0
        var sumY = 0.0
        for i in 0 ..< self.gazeEstimations.count {
            sumX += self.gazeEstimations[i].0
            sumY += self.gazeEstimations[i].1
        }
        let averageX = sumX/Double(Constants.rollingAverageWindowSize)
        let averageY = sumY/Double(Constants.rollingAverageWindowSize)
        
        // Update predictionQueue
        var returnQueue: [(Double,Double)] = [(Double, Double)] (repeating: (0.0,0.0), count: Constants.rollingAverageWindowSize)
        for i in 0..<Constants.rollingAverageWindowSize-1 {
            returnQueue[i] = (self.gazeEstimations[i+1])
        }
        returnQueue[Constants.rollingAverageWindowSize-1] = gazePrediction
        self.gazeEstimations = returnQueue
        self.currAvgGazeEst = CGPoint(x: averageX, y: averageY)
    }
}

// Page turning functions
extension TwoPartAnimationViewController {
    
    @objc
    func halfTurnPage() {
        let currPageIndex = self.pages.count - self.currentPageNumber
        self.pageIsHalfTurned = true
        if currPageIndex > 0 { // Don't turn past last page
            let currPage = self.pages[currPageIndex]
            //            currPage.mask = MaskView(frame: self.view.frame)
            
            let maskLayer = CAShapeLayer()
//            maskLayer.fillRule = .evenOdd
            maskLayer.fillColor = UIColor.white.withAlphaComponent(1.0).cgColor
            maskLayer.strokeColor = UIColor.clear.cgColor
//            maskLayer.contents = UIImage(named: "AppStoreIconImage")?.cgImage
            let currPDFView = self.pages[currPageIndex] as? PDFView
            maskLayer.contents = currPDFView?.currentPage?.thumbnail(of: CGSize(width: self.view.frame.width, height: self.view.frame.height), for: .mediaBox).cgImage
            maskLayer.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width, height: self.view.frame.height)
//            maskLayer.path = maskPath(cornerRadius: 20).cgPath
//            maskLayer.opacity = 1.0
            currPage.layer.mask = maskLayer
            
            let oldBounds = maskLayer.bounds
            let oldFrame = maskLayer.frame
            let newBounds = CGRect(x: 0, y: 0, width: self.view.frame.width/2, height: self.view.frame.height)
            let newFrame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width, height: self.view.frame.height/2)
            // Animation
            print(maskLayer.position.debugDescription)
            let animation = CABasicAnimation(keyPath: "position")
//            animation.fromValue = NSValue(cgRect: oldBounds)
//            animation.toValue = NSValue(cgRect: newBounds)
            animation.fromValue = maskLayer.position
            animation.toValue = [maskLayer.position.x, maskLayer.position.y+self.view.frame.height/2]
            animation.duration = 3.0
//            animation.isRemovedOnCompletion = false
//            animation.fillMode = .forwards
//            maskLayer.bounds = newBounds
//            maskLayer.frame = newFrame
            maskLayer.position = CGPoint(x: maskLayer.position.x, y: maskLayer.position.y+self.view.frame.height/2)
            
            maskLayer.add(animation, forKey: nil)
            
            
//            CATransaction.begin()
//            CATransaction.setDisableActions(true)
//            currPage.layer.mask?.opacity = 1.0
//            CATransaction.commit()
            //            currPage.mask?.alpha = 1
            //            UIView.animate(withDuration: 1.0) {
            //                currPage.mask?.alpha = 0
            //            }
        }
    }
    
    @objc
    func fullyTurnPage() {
        let currPageIndex = self.pages.count - self.currentPageNumber
        self.pageIsHalfTurned = false
        if currPageIndex > 0 { // Don't turn past last page
            let currPage = self.pages[currPageIndex]
            let animation = CABasicAnimation(keyPath: "position")
            animation.fromValue = currPage.layer.mask?.position
            animation.toValue = [currPage.layer.mask?.position.x, (currPage.layer.mask?.position.y)! + self.view.frame.height/2]
            animation.duration = 3.0
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            currPage.layer.mask?.add(animation, forKey: nil)
            
//            currPage.mask = FullMaskView(frame: self.view.frame)
            self.currentPageNumber += 1
        }
    }
    
    @objc
    func resetHalfPageTurningBlock() {
        self.canHalfTurnPage = true
    }
    
    @objc
    func resetFullPageTurningBlock() {
        self.canFullyTurnPage = true
    }
}

// Setting up front-facing camera for iTracker
extension TwoPartAnimationViewController {
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

extension TwoPartAnimationViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.predictionEngine!.predictGaze(sampleBuffer: sampleBuffer) { [weak self] result in
            switch result {
            case .success(let prediction):
                self?.rawGazeEst = prediction
                self?.isFaceVisible = true
            case .failure(let error):
                self?.isFaceVisible = false
                print("Error performing gaze detection: \(error)")
            default:
                self?.isFaceVisible = false
                return
            }
        }
        
        if (self.isFaceVisible) { //Update rolling estimates
            var transformedPrediction = transformPrediction(prediction: self.rawGazeEst)
            transformedPrediction = PredictionUtilities.boundPredictionToScreen(prediction: transformedPrediction)
            self.updateRollingAverage(gazePrediction: transformedPrediction)
            // When to half-turn page
            self.checkIfPageShouldTurn()
        }
    }
    
    // Transform prediction from prediction space to screen space
    func transformPrediction(prediction: (Double, Double)) -> (Double, Double) {
        let (scaledX, scaledY) = PredictionUtilities.scalePrediction(prediction: prediction, xScaling: self.xScaling, yScaling: self.yScaling, xTranslation: self.xTranslation, yTranslation: self.yTranslation)
        return PredictionUtilities.predictionToScreenCoords(xPrediction: scaledX, yPrediction: scaledY, orientation: CGImagePropertyOrientation.up)
    }
    
}

extension TwoPartAnimationViewController : InitializationDelegate {
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

extension TwoPartAnimationViewController : StatusDelegate {
    func onStarted() {
        print("SeeSoTracker has started tracking.")
    }
    
    func onStopped(error: StatusError) {
        print("SeeSoTracker has stopped, error : \(error.description)")
    }
}

extension TwoPartAnimationViewController : GazeDelegate {
    func onGaze(gazeInfo : GazeInfo) {
        if (gazeInfo.trackingState == SeeSo.TrackingState.SUCCESS) {
            self.isFaceVisible = true
            let (predX, predY) = PredictionUtilities.boundPredictionToScreen(prediction: (gazeInfo.x, gazeInfo.y))
            self.currAvgGazeEst = CGPoint(x: predX, y: predY)
            self.checkIfPageShouldTurn()
        } else {
            self.isFaceVisible = false
        }
    }
}

