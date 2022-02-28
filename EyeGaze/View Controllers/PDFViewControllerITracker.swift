//
//  PDFViewControllerITracker.swift
//  EyeGaze
//
//  Created by Chris Nixon on 28/02/2022.
//

import SeeSo
import PDFKit
import UIKit
import AVFoundation

class PDFViewControllerITracker: UIViewController {
    
    // Views
    let pdfView = PDFView()

    // Gaze Tracking
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var displayLink: CADisplayLink?
    private var predictionEngine: PredictionEngine?
    // Parameters
    private var xScaling = 3.0
    private var yScaling = 2.0
    // translations in cm
    private var xTranslation = 1.5
    private var yTranslation = 9.0
    // Gaze estimates
    private var rawGazeEst: (Double, Double) = (0,0)
    private var currAvgGazeEst: CGPoint = CGPoint(x: 0, y: 0)
    private var gazeEstimations: [(Double, Double)] = [(Double, Double)] (repeating: (0.0,0.0), count: Constants.rollingAverageWindowSize)
    // Misc gaze values
    private let allowGazeTracking: Bool = true
    private var isFaceDetected: Bool = false
    
    private var pdf: PDF?
    private var scrollView: UIScrollView?
    
    // Scrolling
    private var pageTurningImplementation: PageTurningImplementation = .scrolling
    private var scrollSpeed: CGFloat = 0.1
    private var scrollOffset: CGPoint = CGPoint(x: 0.0, y: 0.0)
    private var currScrollYOffset: CGFloat = 0.0
    private var maxScrollOffset: CGFloat = .zero
    private var currSpeed: Speed = Speed.slow
    private var prevSpeed: Speed = Speed.slow
    private var rateOfSpeedChange = 0.001
    private var canScroll: Bool = true
    
    // Page turning
    
    private var canTurnPage: Bool = true
    
    // Thresholds
    private var halfScreenThreshold: CGFloat = CGFloat(Constants.iPadScreenHeightPoints/2)
    private var bottomQuarterScreenThreshold: CGFloat = CGFloat(Constants.iPadScreenHeightPoints - Constants.iPadScreenHeightPoints/4)
    private var bottomRightCornerThreshold: CGPoint = CGPoint(x: Constants.iPadScreenWidthPoints - Constants.iPadScreenWidthPoints/3, y: Constants.iPadScreenHeightPoints - Constants.iPadScreenHeightPoints/5)
    
    enum Speed {
        case slow
        case medium
        case fast
    }
    
    func configure(with pdf: PDF, pageTurningImplementation implementation: PageTurningImplementation, iTrackerModel: iTracker_v2) {
        self.pdf = pdf
        self.pageTurningImplementation = implementation
        self.predictionEngine = PredictionEngine(model: iTrackerModel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString(pdf?.shortTitle ?? "View PDF", comment: "view PDF nav title")
        view.addSubview(pdfView)
        pdfView.document = pdf?.document
        pdfView.autoScales = true
        setupCamera()
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pdfView.frame = view.bounds
        guard let scrollView = pdfView.scrollView else {
            print("Couldn't find scrollView")
            return
        }
        pdfView.scrollView!.delegate = self
        self.scrollView = scrollView
        self.maxScrollOffset = self.scrollView!.contentSize.height - self.scrollView!.bounds.size.height
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Initialize a new display link inside a displayLink variable, providing 'self'
        //as target object and a selector to be called when the screen is updated.
        if (pageTurningImplementation == .scrolling) {
            self.displayLink = CADisplayLink(target: self, selector: #selector(autoScroll(displaylink:)))
            // And add the displayLink variable to the current run loop with default mode.
            self.displayLink?.add(to: .current, forMode: .common)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    @objc func autoScroll(displaylink: CADisplayLink) {
        // Check that user-initiated scroll event isn't happening
        if (!canScroll) {
            return
        }
        // Adjust scrolling speed
        if (currAvgGazeEst.y > bottomQuarterScreenThreshold) {
            if (self.scrollSpeed < 0.7) {
                self.scrollSpeed += self.rateOfSpeedChange
            } else {
                self.scrollSpeed = 0.7
            }
            self.currSpeed = Speed.fast
            self.prevSpeed = Speed.fast
        } else if (currAvgGazeEst.y > halfScreenThreshold) {
            if (self.prevSpeed == Speed.slow) {
                if (self.scrollSpeed < 0.4) {
                    self.scrollSpeed += self.rateOfSpeedChange
                } else {
                    self.scrollSpeed = 0.4
                    self.prevSpeed = Speed.medium
                }
            } else if (self.prevSpeed == Speed.fast) {
                if (self.scrollSpeed > 0.3) {
                    self.scrollSpeed -= self.rateOfSpeedChange
                } else {
                    self.scrollSpeed = 0.3
                    self.prevSpeed = Speed.medium
                }
            }
            self.currSpeed = Speed.medium
        } else if (!currAvgGazeEst.y.isNaN) {
            if (self.scrollSpeed > 0.1) {
                self.scrollSpeed -= self.rateOfSpeedChange
            } else {
                self.scrollSpeed = 0.1
            }
            self.currSpeed = Speed.slow
            self.prevSpeed = Speed.slow
        }
        
        
        let seconds = displaylink.targetTimestamp - displaylink.timestamp
        let yOffset = self.scrollSpeed * CGFloat(seconds) * 100
        self.currScrollYOffset += yOffset
        self.scrollView!.setContentOffset(CGPoint(x: 0, y: self.currScrollYOffset), animated: false)
//        print("Seconds: \(seconds), yOffset: \(yOffset), contentOffset: \(self.scrollView!.contentOffset.y), currScrollYOffset: \(self.currScrollYOffset)")
    }
}

// iTracker functions
extension PDFViewControllerITracker {
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
}

// Scrolling extensions
extension PDFViewControllerITracker : UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Halt auto-scrolling to allow user to override and scroll themselves
        self.canScroll = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Scrolling animation initiated by user has ended, auto-scrolling can continue.
        self.currScrollYOffset = scrollView.contentOffset.y
        self.canScroll = true
    }
}

extension PDFViewControllerITracker: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if allowGazeTracking {
            self.predictionEngine!.predictGaze(sampleBuffer: sampleBuffer) { [weak self] result in
                switch result {
                case .success(let prediction):
                    self?.rawGazeEst = prediction
                    self?.isFaceDetected = true
                case .notFound:
                    self?.isFaceDetected = false
                case .failure(let error):
                    self?.isFaceDetected = false
                    print("Error performing gaze detection: \(error)")
                }
            }
            if (self.isFaceDetected) {
                let transformedPrediction = transformPrediction(prediction: self.rawGazeEst)
                
                // Calculate rolling average
                var sumX = 0.0
                var sumY = 0.0
                for i in 0 ..< gazeEstimations.count {
                    sumX += gazeEstimations[i].0
                    sumY += gazeEstimations[i].1
                }
                let averageX = sumX/5
                let averageY = sumY/5

                // Update predictionQueue
                var returnQueue: [(Double,Double)] = [(Double, Double)] (repeating: (0.0,0.0), count: Constants.rollingAverageWindowSize)
                for i in 0..<Constants.rollingAverageWindowSize-1 {
                    returnQueue[i] = (gazeEstimations[i+1])
                }
                returnQueue[Constants.rollingAverageWindowSize-1] = transformedPrediction
                self.gazeEstimations = returnQueue
                self.currAvgGazeEst = CGPoint(x: averageX, y: averageY)
            }
            DispatchQueue.main.sync {
                if (!self.isFaceDetected) {
                    self.navigationItem.title = NSLocalizedString("No face detected", comment: "view PDF nav title")
                    self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.red]
                } else {
                    self.navigationItem.title = nil
                }
            }
        }
    }
    
    // Transform prediction from prediction space to screen space
    func transformPrediction(prediction: (Double, Double)) -> (Double, Double) {
        let (scaledX, scaledY) = PredictionUtilities.scalePrediction(prediction: prediction, xScaling: self.xScaling, yScaling: self.yScaling, xTranslation: self.xTranslation, yTranslation: self.yTranslation)
        return PredictionUtilities.predictionToScreenCoords(xPrediction: scaledX, yPrediction: scaledY, orientation: CGImagePropertyOrientation.up)
    }
    
}
