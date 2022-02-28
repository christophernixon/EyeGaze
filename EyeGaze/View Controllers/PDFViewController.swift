//
//  PDFViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 07/01/2022.
//

import SeeSo
import PDFKit
import UIKit
import AVFoundation

class PDFViewController: UIViewController {
    
    // Views
    let pdfView = PDFView()
    
    // Gaze tracking
    var tracker : GazeTracker? = nil
    private var testCurrGazeLocLayers: [CAShapeLayer] = []
    private var currGazePrediction: CGPoint = CGPoint(x: 0, y: 0)
    
    private var pdf: PDF?
    private var scrollView: UIScrollView?
    
    // Scrolling
    
    private var pageTurningImplementation: PageTurningImplementation = .scrolling
    private var scrollSpeed: CGFloat = 0.1
    private var scrollOffset: CGPoint = CGPoint(x: 0.0, y: 0.0)
    private var currScrollYOffset: CGFloat = 0.0
    private var maxScrollOffset: CGFloat = .zero
    private var displayLink: CADisplayLink?
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
        case transitionSlowToMedium
        case transitionMediumToSlow
        case medium
        case transitionMediumToFast
        case transitionFastToMedium
        case fast
    }
    
    func configure(with pdf: PDF, pageTurningImplementation implementation: PageTurningImplementation) {
        self.pdf = pdf
        self.pageTurningImplementation = implementation
    }
    
    func initGazeTracking() {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initGazeTracking()
        navigationItem.title = NSLocalizedString(pdf?.shortTitle ?? "View PDF", comment: "view PDF nav title")
        view.addSubview(pdfView)
        pdfView.document = pdf?.document
        pdfView.autoScales = true
        
//        pdfView.usePageViewController(true, withViewOptions: nil)
//        let timer = Timer(timeInterval: 0.5, target: self, selector: #selector(printContentOffset), userInfo: nil, repeats: false)
//        RunLoop.current.add(timer, forMode: .common)
        
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
        //        let timer = Timer(timeInterval: 0.5, target: self, selector: #selector(printContentOffset), userInfo: nil, repeats: false)
        //        RunLoop.current.add(timer, forMode: .common)
//        let scrollTimer = Timer(timeInterval: 1.5, target: self, selector: #selector(scrollToEnd), userInfo: nil, repeats: false)
//        RunLoop.current.add(scrollTimer, forMode: .common)
        //        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
        //            self.autoScroll()
        //        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Initialize a new display link inside a displayLink variable, providing 'self'
        //as target object and a selector to be called when the screen is updated.
        if (pageTurningImplementation == .scrolling) {
            self.displayLink = CADisplayLink(target: self, selector: #selector(step(displaylink:)))
            // And add the displayLink variable to the current run loop with default mode.
            self.displayLink?.add(to: .current, forMode: .common)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.tracker?.stopTracking()
        if (pageTurningImplementation == .scrolling) {
            self.displayLink?.invalidate()
        }
    }
    
    @objc func step(displaylink: CADisplayLink) {
        // Check that user-initiated scroll event isn't happening
        if (!canScroll) {
            return
        }
        // Adjust scrolling speed
        if (currGazePrediction.y > bottomQuarterScreenThreshold) {
            if (self.scrollSpeed < 0.7) {
                self.scrollSpeed += self.rateOfSpeedChange
            } else {
                self.scrollSpeed = 0.7
            }
            self.currSpeed = Speed.fast
            self.prevSpeed = Speed.fast
        } else if (currGazePrediction.y > halfScreenThreshold) {
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
        } else if (!currGazePrediction.y.isNaN) {
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
    
    @objc
    func scrollToEnd() {
        let maxOffset = CGPoint(x: .zero, y: self.maxScrollOffset)
        let duration = 60.0
//        self.scrollView!.setValue(5.0, forKeyPath: "contentOffsetAnimationDuration")
//        self.scrollView!.setContentOffset(maxOffset, animated: true)
        //        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
        //            self.scrollView!.setContentOffset(maxOffset, animated: true)
        //        }
//        UIView.animate(withDuration: 50.0, animations: {
//            self.scrollView!.setContentOffset(maxOffset, animated: false)
//        })
        //        animator.startAnimation()
        //        self.scrollAnimator = animator
    }
    
    @objc
    func autoScroll() {
        self.scrollOffset.y += 50
        self.scrollView!.setContentOffset(self.scrollOffset, animated: true)
        //        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
        //            self.autoScroll()
        //        }
    }
    
    @objc
    func printContentOffset() {
        print(self.scrollView!.contentOffset)
        let timer = Timer(timeInterval: 0.5, target: self, selector: #selector(printContentOffset), userInfo: nil, repeats: false)
        RunLoop.current.add(timer, forMode: .common)
    }
}

// Scrolling extensions
extension PDFViewController : UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Halt auto-scrolling to allow user to override and scroll themselves
        self.canScroll = false
    }
    
//    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
//        self.scrollView!.setContentOffset(self.scrollView!.contentOffset, animated: true)
//    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //      if !decelerate {
        //         endOfScroll()
        //      }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Scrolling animation initiated by user has ended, auto-scrolling can continue.
        self.currScrollYOffset = scrollView.contentOffset.y
        self.canScroll = true
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        //        endOfScroll()
    }
    
    func endOfScroll() {
        //        self.scrollOffset.y += 15
        //        self.scrollView!.setContentOffset(self.scrollOffset, animated: true)
    }
}

// Gaze detection extensions
extension PDFViewController : InitializationDelegate {
    func onInitialized(tracker: GazeTracker?, error: InitializationError) {
        if (tracker != nil){
            self.tracker = tracker
            print("initalized GazeTracker")
            self.tracker?.statusDelegate = self
            self.tracker?.gazeDelegate = self
            self.tracker?.startTracking()
        }else{
            print("init failed : \(error.description)")
        }
    }
}

extension PDFViewController : StatusDelegate {
    func onStarted() {
        print("tracker starts tracking.")
    }
    
    func onStopped(error: StatusError) {
        print("stop error : \(error.description)")
    }
}

extension PDFViewController : GazeDelegate {
    
    func onGaze(gazeInfo : GazeInfo) {
        let (predictSpacePointX, predictSpacePointY)  = PredictionUtilities.screenToPredictionCoords(xScreen: gazeInfo.x, yScreen: gazeInfo.y, orientation: .up)
        // Waits for half a second, turns page then allows next page turn after one second
        if (self.canTurnPage && self.pageTurningImplementation == .singleAnimation && gazeInfo.x > self.bottomRightCornerThreshold.x && gazeInfo.y > self.bottomRightCornerThreshold.y) {
            // Prevent page being turning more than once
            self.canTurnPage = false
            let timer = Timer(timeInterval: 0.5, target: self, selector: #selector(turnPage), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .common)
            let unlockTimer = Timer(timeInterval: 1.5, target: self, selector: #selector(resetPageTurningBlock), userInfo: nil, repeats: false)
            RunLoop.current.add(unlockTimer, forMode: .common)
        }
//        print("timestamp : \(gazeInfo.timestamp), (x , y) : (\(gazeInfo.x), \(gazeInfo.y)) , (x , y) : (\(predictSpacePointX), \(predictSpacePointY)) state : \(gazeInfo.trackingState.description), speed : \(self.currSpeed)")
        self.currGazePrediction = CGPoint(x: gazeInfo.x, y: gazeInfo.y)
//        if (!gazeInfo.x.isNaN) {
//            drawGreenDot(location: CGPoint(x: gazeInfo.x, y: gazeInfo.y))
//        }
    }
    
    @objc
    func resetPageTurningBlock() {
        self.canTurnPage = true
    }
    
    @objc
    func turnPage() {
        self.pdfView.goToNextPage(nil)
    }
    
    func drawGreenDot(location: CGPoint) {
        self.testCurrGazeLocLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
        let outerDot = UIBezierPath(arcCenter: location, radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        var shapeLayer = CAShapeLayer()
        shapeLayer.path = outerDot.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.green.cgColor
        shapeLayer.lineWidth = CGFloat(3)
        view.layer.addSublayer(shapeLayer)
        self.testCurrGazeLocLayers.append(shapeLayer)
        
        let innerDot = UIBezierPath(arcCenter: location, radius: CGFloat(3), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        shapeLayer = CAShapeLayer()
        shapeLayer.path = innerDot.cgPath
        shapeLayer.fillColor = UIColor.green.cgColor
        view.layer.addSublayer(shapeLayer)
        self.testCurrGazeLocLayers.append(shapeLayer)
    }
}

