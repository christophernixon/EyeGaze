//
//  ModelPDFViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 25/02/2022.
//

import Foundation
import UIKit
import PDFKit

class ModalPDFViewController: UIViewController {
    
    private var transitionTimer = Timer(timeInterval: 2.0, target: self, selector: #selector(changeFirstTwoPages), userInfo: nil, repeats: true)
    
    private var pageTurningImplementation: PageTurningImplementation = .scrolling
    
    private var pdf: PDF?
    private var pages: [UIViewController] = []
    private var currentPageNumber: Int = 0
    
    private var transition = CATransition()
    
    func configure(with pdf: PDF, pageTurningImplementation implementation: PageTurningImplementation) {
        self.pdf = pdf
        self.pageTurningImplementation = implementation
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
//        initGazeTracking()
//        self.dataSource = self
//        self.delegate   = self
//        self.modalTransitionStyle = .partialCurl
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
            vc.modalTransitionStyle = .partialCurl
            vc.modalPresentationStyle = .fullScreen
            pages.append(vc)
        }
//        self.view = pages.first?.view
//        if let firstVC = pages.first
//        {
////            setViewControllers([firstVC], direction: .reverse, animated: true, completion: nil)
//            present(firstVC, animated: false, completion: nil)
//        }
//
        let timer = Timer(timeInterval: 2.0, target: self, selector: #selector(changeFirstTwoPages), userInfo: nil, repeats: true)
        self.transitionTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }
    
//    override func viewDidDisappear(_ animated: Bool) {
//        self.transitionTimer.invalidate()
//    }
    
    @objc
    func animate(_ sender: Any) {
        self.animateCurlPage(start: 0.1, end: 0.5, duration: 0.3, onController: self)
    }
    
    func animateCurlPage(start: Float, end: Float, duration: CFTimeInterval, onController controller: UIViewController) {
        
//        let animation = CATransition()
//        animation.duration = 0.3
//        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
//        animation.fillMode = CAMediaTimingFillMode.forwards
//        animation.isRemovedOnCompletion = false
//        animation.endProgress = 0.2
//        animation.subtype = CATransitionSubtype.fromTop
//        controller.view.layer.add(animation, forKey: "kCATransition")
        
        UIView.animate(withDuration: duration, animations: {
            self.transition.subtype = CATransitionSubtype.fromBottom
            self.transition.duration = duration
            self.transition.startProgress = start
            self.transition.endProgress = end
            self.transition.fillMode = CAMediaTimingFillMode.forwards
            self.transition.isRemovedOnCompletion = false

            self.view.layer.add(self.transition, forKey: "transition1")
        })
    }
    
    @objc
    func changeFirstTwoPages() {
        if (self.currentPageNumber == 0) {//First page
            self.present(self.pages[self.currentPageNumber], animated: true, completion: nil)
            self.currentPageNumber += 1
        } else { //Next page
            self.dismiss(animated: true, completion: nil)
            self.currentPageNumber = 0
        }
    }
    
    @objc
    func changeSlide() {
        self.currentPageNumber += 1
        if self.currentPageNumber < self.pages.count {
            self.animateCurlPage(start: 0.1, end: 0.5, duration: 0.3, onController: self.pages[self.currentPageNumber-1])
//            self.pages[self.currentPageNumber-1].dismiss(animated: true) {
//                self.animateCurlPage(start: 0.1, end: 0.5, duration: 0.3, onController: self.pages[self.currentPageNumber])
////                self.navigationController?.present(self.pages[self.currentPageNumber], animated: false, completion: nil)
//            }
            
            
//            if self.pages[self.currentPageNumber].presentedViewController == nil {
//                self.pages[self.currentPageNumber-1].present(alert, animated: true, completion: nil)
//            } else {
//                self.pages[self.currentPageNumber].present(alert, animated: true, completion: nil)
//            }
            
//            self.setViewControllers([self.pages[self.currentPageNumber]], direction: .reverse, animated: true, completion: nil)
            print("Animating")
        }
        else {
            self.pages[self.currentPageNumber-1].dismiss(animated: true) {
                self.currentPageNumber = 0
                self.animateCurlPage(start: 0.1, end: 0.5, duration: 0.3, onController: self.pages[self.currentPageNumber])
//                self.navigationController?.present(self.pages[self.currentPageNumber], animated: true, completion: nil)
            }
            
            print("Animating first page")
//            animateCurlPage(start: 0.1, end: 0.5, duration: 0.3, onController: self.pages[self.currentPageNumber])
//            self.navigationController?.present(self.pages[self.currentPageNumber], animated: true, completion: nil)
//            self.setViewControllers([self.pages[0]], direction: .reverse, animated: false, completion: nil)

        }
    }
    
}
