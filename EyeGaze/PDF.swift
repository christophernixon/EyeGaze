//
//  PDF.swift
//  EyeGaze
//
//  Created by Chris Nixon on 07/01/2022.
//

import Foundation
import PDFKit

struct PDF {
    var shortTitle: String
    var title: String
    var url: URL
    var document: PDFDocument
    
    init(pdfTitle: String) {
        
        guard let url = Bundle.main.url(forResource: pdfTitle, withExtension: "pdf") else {
            fatalError("Couldn't find specified PDF file: \(pdfTitle)")
        }
        guard let document = PDFDocument(url: url) else {
            fatalError("Couldn't create PDFDocument object from url.")
        }
        
        self.shortTitle = pdfTitle
        self.title = pdfTitle + ".pdf"
        self.url = url
        self.document = document
    }
}

extension PDF {
    static var testData = [
        PDF(pdfTitle: "Vainement,mabien-aimee"),
        PDF(pdfTitle: "EinTraum"),
        PDF(pdfTitle: "Adelaide"),
        PDF(pdfTitle: "Ganymed"),
        PDF(pdfTitle: "GoLovelyRose"),
        PDF(pdfTitle: "IllsailupontheDogStar"),
        PDF(pdfTitle: "IchatmeteinenlindenDuft"),
        PDF(pdfTitle: "Isshenotpassingfair"),
        PDF(pdfTitle: "Komm,JesuKomm"),
        PDF(pdfTitle: "Prigionierahol_almainpena"),
        PDF(pdfTitle: "SilentNoon"),
        PDF(pdfTitle: "total_eclipse_spare_page"),
        PDF(pdfTitle: "total_eclipse"),
        PDF(pdfTitle: "ViensMonBienAime"),
        PDF(pdfTitle: "sicut_cervus"),
        PDF(pdfTitle: "Clair_De_Lune"),
        PDF(pdfTitle: "cul-ta")
    ]
}
