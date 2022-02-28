//
//  ParentAnimatedPDFViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 22/02/2022.
//

import Foundation
import UIKit

class ParentAnimatedPDFViewController: UIViewController {
    
    private var pageController: AnimatedPDFViewController?
    private var pageTurningImplementation: PageTurningImplementation?
    private var pdf: PDF?
    
    func configure(with pdf: PDF, pageTurningImplementation implementation: PageTurningImplementation) {
        self.pdf = pdf
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageController()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pageController?.view.frame = self.view.frame
    }
    
    private func setupPageController() {
        self.pageController = AnimatedPDFViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        self.pageController?.configure(with: self.pdf!, pageTurningImplementation: self.pageTurningImplementation ?? .singleAnimation)
        self.pageController?.delegate = self
        self.addChild(self.pageController!)
        self.view.addSubview(self.pageController!.view)

//        self.pageController?.setViewControllers([UIViewController()], direction: .forward, animated: true, completion: nil)
                
        self.pageController?.didMove(toParent: self)
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
