//
//  ParentAnimatedPDFViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 22/02/2022.
//

import Foundation
import UIKit

class ParentAnimatedPDFViewController: UIViewController {
    
//    private var pageController: UIPageViewController?
    private var pageTurningImplementation: PageTurningImplementation?
    private var gazeTrackingImplementation: GazeDetectionImplementation?
    private var pdf: PDF?
    private var iTrackerModel: iTracker_v2?
    
    func configure(with pdf: PDF, pageTurningImplementation implementation: PageTurningImplementation, gazeTrackingImplementation gazeImplementation: GazeDetectionImplementation, iTrackerModel: iTracker_v2) {
        self.pdf = pdf
        self.pageTurningImplementation = implementation
        self.gazeTrackingImplementation = gazeImplementation
        self.iTrackerModel = iTrackerModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageController()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        pageController?.view.frame = self.view.frame
    }
    
    private func setupPageController() {
        if (self.gazeTrackingImplementation == .SeeSo) {
            let pageController = AnimatedPDFViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
            pageController.configure(with: self.pdf!, pageTurningImplementation: self.pageTurningImplementation ?? .singleAnimation)
            pageController.delegate = self
            self.addChild(pageController)
            self.view.addSubview(pageController.view)
            pageController.didMove(toParent: self)
        } else if (self.gazeTrackingImplementation == .iTracker) {
            let pageController = AnimatedPDFViewControllerITracker(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
            pageController.configure(with: self.pdf!, pageTurningImplementation: self.pageTurningImplementation ?? .singleAnimation, iTrackerModel: self.iTrackerModel!)
            pageController.delegate = self
            self.addChild(pageController)
            self.view.addSubview(pageController.view)
            pageController.didMove(toParent: self)
        }
//        self.pageController?.delegate = self
//        self.addChild(self.pageController!)
//        self.view.addSubview(self.pageController!.view)
//
////        self.pageController?.setViewControllers([UIViewController()], direction: .forward, animated: true, completion: nil)
//
//        self.pageController?.didMove(toParent: self)
    }
    
}

extension ParentAnimatedPDFViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {

        // handle orientation cases if needed
        // assuming you only support landscape:

//        let initialVC = UIViewController()
//        let initialVC2 = UIViewController()
//        self.pageController?.setViewControllers([initialVC, initialVC2], direction: .forward, animated: true, completion: nil)
//        pageController?.isDoubleSided = true
        return .max
    }
}
