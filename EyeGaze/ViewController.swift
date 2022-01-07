//
//  ViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 21/12/2021.
//

import PDFKit
import UIKit

class ViewController: UIViewController, PDFViewDelegate {

    // Views
    let pdfView = PDFView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pdfView)
        
        // Document
        guard let url = Bundle.main.url(forResource: "Vainement, ma bien-aimée, Le Roi D’y", withExtension: "pdf") else {
            return
        }
        
        guard let document = PDFDocument(url: url) else {
            return
        }

        pdfView.delegate = self
        
        var newDocument = PDFDocument()
        guard let page = PDFPage(image: UIImage(systemName: "house")!) else {
            return
        }
        newDocument.insert(page, at: 0)
        
        pdfView.document = document
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pdfView.frame = view.bounds
    }


}

