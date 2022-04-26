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
        navigationItem.title = NSLocalizedString("Single Animation Mode", comment: "view PDF nav title")
        setupPageController()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func setupPageController() {
        if (self.gazeTrackingImplementation == .SeeSo) {
            let pageController = AnimatedPDFViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
            pageController.configure(with: self.pdf!, pageTurningImplementation: self.pageTurningImplementation ?? .singleAnimation)
            let childNavController = UINavigationController(rootViewController: pageController)
            childNavController.view.frame = (self.navigationController?.view.frame)!
            self.addChild(childNavController)
            self.view.addSubview(childNavController.view)
            childNavController.didMove(toParent: self)
            
        } else if (self.gazeTrackingImplementation == .iTracker) {
            let pageController = AnimatedPDFViewControllerITracker(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
            pageController.configure(with: self.pdf!, pageTurningImplementation: self.pageTurningImplementation ?? .singleAnimation, iTrackerModel: self.iTrackerModel!)
            let childNavController = UINavigationController(rootViewController: pageController)
            childNavController.view.frame = (self.navigationController?.view.frame)!
            self.addChild(childNavController)
            self.view.addSubview(childNavController.view)
            childNavController.didMove(toParent: self)
        }
    }
    
}
