//
//  ViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 21/12/2021.
//

import PDFKit
import UIKit

class PDFListViewController: UITableViewController, PDFViewDelegate {

    static let showPDFSegueIdentifier = "ShowPDFSegue"
    
    private var pdfListDataSource: PDFListDataSource?
    
    // Views
    let pdfView = PDFView()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.showPDFSegueIdentifier,
           let destination = segue.destination as? PDFViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let pdf = PDF.testData[indexPath.row]
            destination.configure(with: pdf)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pdfListDataSource = PDFListDataSource()
        tableView.dataSource = pdfListDataSource
        
        
//        view.addSubview(pdfView)
//
//        // Document
//        guard let url = Bundle.main.url(forResource: "Vainement, ma bien-aimée, Le Roi D’y", withExtension: "pdf") else {
//            return
//        }
//
//        guard let document = PDFDocument(url: url) else {
//            return
//        }
//
//        pdfView.delegate = self
//
//        var newDocument = PDFDocument()
//        guard let page = PDFPage(image: UIImage(systemName: "house")!) else {
//            return
//        }
//        newDocument.insert(page, at: 0)
//
//        pdfView.document = document
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        pdfView.frame = view.bounds
    }


}

