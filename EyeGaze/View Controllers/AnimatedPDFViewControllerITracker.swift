//
//  AnimatedPDFViewControllerITracker.swift
//  EyeGaze
//
//  Created by Chris Nixon on 28/02/2022.
//

import SeeSo
import PDFKit
import UIKit
import AVFoundation

class AnimatedPDFViewControllerITracker: UIPageViewController {
    
    // Views
    let pdfView = PDFView()
    
    // Gaze Tracking
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
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
    private var isFaceDetected: Bool = false
    
    private var pdf: PDF?
    
    // Page Turning
    private var pageTurningImplementation: PageTurningImplementation = .scrolling
    private var canTurnPage: Bool = true
    private var pages: [UIViewController] = []
    private var currentPageNumber: Int = 0
    
    // Thresholds
    private var halfScreenThreshold: CGFloat = CGFloat(Constants.iPadScreenHeightPoints/2)
    private var bottomQuarterScreenThreshold: CGFloat = CGFloat(Constants.iPadScreenHeightPoints - Constants.iPadScreenHeightPoints/4)
    private var bottomRightCornerThreshold: CGPoint = CGPoint(x: Constants.iPadScreenWidthPoints - Constants.iPadScreenWidthPoints/3, y: Constants.iPadScreenHeightPoints - Constants.iPadScreenHeightPoints/5)
    
    func configure(with pdf: PDF, pageTurningImplementation implementation: PageTurningImplementation, iTrackerModel: iTracker_v2) {
        self.pdf = pdf
        self.pageTurningImplementation = implementation
        self.predictionEngine = PredictionEngine(model: iTrackerModel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false
        self.dataSource = self
        self.delegate = self
        let pageCount = (self.pdf?.document.pageCount ?? 1) - 1
        for index in 0...pageCount {
            let page: PDFPage = (self.pdf?.document.page(at: index)!)!
            let pdfView: PDFView = PDFView(frame: self.view.frame)
            pdfView.document = self.pdf?.document
            pdfView.displayMode = .singlePage
            pdfView.go(to: page)
            pdfView.autoScales = true
            let vc = UIViewController()
            vc.view = pdfView
            pages.append(vc)
        }
        
        if let firstVC = pages.first
        {
            setViewControllers([firstVC], direction: .reverse, animated: true, completion: nil)
        }
        setupCamera()
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.captureSession.stopRunning()
    }
}

// Page turning functions
extension AnimatedPDFViewControllerITracker {
    @objc
    func changeSlide() {
        self.currentPageNumber += 1
        if self.currentPageNumber < self.pages.count {
            self.setViewControllers([self.pages[self.currentPageNumber]], direction: .reverse, animated: true, completion: nil)
        }
        else {
            self.currentPageNumber = 0
            self.setViewControllers([self.pages[0]], direction: .reverse, animated: false, completion: nil)
        }
    }
    
    @objc
    func resetPageTurningBlock() {
        self.canTurnPage = true
    }
    
    @objc
    func turnPage() {
        self.changeSlide()
    }
}

extension AnimatedPDFViewControllerITracker: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        return .max
    }
}

// Allowing user to flick between pages
extension AnimatedPDFViewControllerITracker: UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else { return nil }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0          else { return pages.last }
        guard pages.count > previousIndex else { return nil        }
        self.currentPageNumber = previousIndex
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else { return nil }
        let nextIndex = viewControllerIndex + 1
        guard nextIndex < pages.count else { return pages.first }
        guard pages.count > nextIndex else { return nil         }
        self.currentPageNumber = nextIndex
        return pages[nextIndex]
    }
}

// iTracker functions for setting up front-facing camera
extension AnimatedPDFViewControllerITracker {
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

extension AnimatedPDFViewControllerITracker: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
        
        if (self.isFaceDetected) { //Update rolling estimates
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
        
//        print("Current gaze estimate: \(self.currAvgGazeEst), (\(self.bottomRightCornerThreshold.x), \(self.bottomRightCornerThreshold.y)), \(self.pageTurningImplementation)")
        
        if (self.canTurnPage && self.pageTurningImplementation == .singleAnimation && self.currAvgGazeEst.x > self.bottomRightCornerThreshold.x && self.currAvgGazeEst.y > self.bottomRightCornerThreshold.y) {
            // Prevent page being turning more than once
            self.canTurnPage = false
            let timer = Timer(timeInterval: 0.5, target: self, selector: #selector(turnPage), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            let unlockTimer = Timer(timeInterval: 1.5, target: self, selector: #selector(resetPageTurningBlock), userInfo: nil, repeats: false)
            RunLoop.main.add(unlockTimer, forMode: .common)
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
    
    // Transform prediction from prediction space to screen space
    func transformPrediction(prediction: (Double, Double)) -> (Double, Double) {
        let (scaledX, scaledY) = PredictionUtilities.scalePrediction(prediction: prediction, xScaling: self.xScaling, yScaling: self.yScaling, xTranslation: self.xTranslation, yTranslation: self.yTranslation)
        return PredictionUtilities.predictionToScreenCoords(xPrediction: scaledX, yPrediction: scaledY, orientation: CGImagePropertyOrientation.up)
    }
}
