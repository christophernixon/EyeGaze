//
//  PDF.swift
//  EyeGaze
//
//  Created by Chris Nixon on 07/01/2022.
//

import Foundation
import PDFKit

struct PDF {
    var title: String
    var url: URL
    var document: PDFDocument
    
    init(pdfTitle: String) {
        
        guard let url = Bundle.main.url(forResource: pdfTitle, withExtension: "pdf") else {
            fatalError("Couldn't find specified PDF file")
        }
        guard let document = PDFDocument(url: url) else {
            fatalError("Couldn't create PDFDocument object from url.")
        }
        
        self.title = pdfTitle + ".pdf"
        self.url = url
        self.document = document
    }
}

extension PDF {
    static var testData = [
        PDF(pdfTitle: "Vainement,mabien-aimee"),
        PDF(pdfTitle: "EinTraum")
    ]
}
