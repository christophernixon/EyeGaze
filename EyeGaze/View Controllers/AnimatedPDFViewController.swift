//
//  AnimatedPDFViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 21/02/2022.
//

import Foundation
import UIKit
import PDFKit
import AVFoundation
import SeeSo

class AnimatedPDFViewController: UIPageViewController {
    
    // Gaze tracking
    var tracker : GazeTracker? = nil
    private var pageTurningImplementation: PageTurningImplementation = .scrolling
    private var currGazePrediction: CGPoint = CGPoint(x: 0, y: 0)
    private var canTurnPage: Bool = true
    private var bottomRightCornerThreshold: CGPoint = CGPoint(x: Constants.iPadScreenWidthPoints - Constants.iPadScreenWidthPoints/3, y: Constants.iPadScreenHeightPoints - Constants.iPadScreenHeightPoints/5)
    
    // PDF
    private var pdf: PDF?
    private var pages: [UIViewController] = []
    private var currentPageNumber: Int = 0
    
    func configure(with pdf: PDF, pageTurningImplementation implementation: PageTurningImplementation) {
        self.pdf = pdf
        self.pageTurningImplementation = implementation
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        initGazeTracking()
        self.dataSource = self
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
        
//        let timer = Timer(timeInterval: 1.0, target: self, selector: #selector(changeSlide), userInfo: nil, repeats: true)
//        RunLoop.current.add(timer, forMode: .common)
    }
    
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
}

extension AnimatedPDFViewController: UIPageViewControllerDataSource
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

extension AnimatedPDFViewController: UIPageViewControllerDelegate { }

// Gaze tracking stuff
extension AnimatedPDFViewController {
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.tracker?.stopTracking()
    }
}

// Gaze detection extensions
extension AnimatedPDFViewController : InitializationDelegate {
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

extension AnimatedPDFViewController : StatusDelegate {
    func onStarted() {
        print("tracker starts tracking.")
    }
    
    func onStopped(error: StatusError) {
        print("stop error : \(error.description)")
    }
}

extension AnimatedPDFViewController : GazeDelegate {
    
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
//        print("\(self.bottomRightCornerThreshold.x), \(self.bottomRightCornerThreshold.y)")
//        print("timestamp : \(gazeInfo.timestamp), (x , y) : (\(gazeInfo.x), \(gazeInfo.y)) , (x , y) : (\(predictSpacePointX), \(predictSpacePointY)) state : \(gazeInfo.trackingState.description)")
        self.currGazePrediction = CGPoint(x: gazeInfo.x, y: gazeInfo.y)
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