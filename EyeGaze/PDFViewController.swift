//
//  PDFViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 07/01/2022.
//

import PDFKit
import UIKit

class PDFViewController: UIViewController, PDFViewDelegate {
    
    // Views
    let pdfView = PDFView()
    
    private var pdf: PDF?
    
    func configure(with pdf: PDF) {
        self.pdf = pdf
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pdfView)
        pdfView.delegate = self
        pdfView.document = pdf?.document
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pdfView.frame = view.bounds
    }
}
