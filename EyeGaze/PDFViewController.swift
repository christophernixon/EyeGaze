//
//  PDFViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 07/01/2022.
//

import PDFKit
import UIKit

class PDFViewController: UIViewController {
    
    // Views
    let pdfView = PDFView()
    
    private var pdf: PDF?
    
    func configure(with pdf: PDF) {
        self.pdf = pdf
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString(pdf?.shortTitle ?? "View PDF", comment: "view PDF nav title")
        view.addSubview(pdfView)
        pdfView.document = pdf?.document
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pdfView.frame = view.bounds
    }
}
