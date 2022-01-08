//
//  PDFListCell.swift
//  EyeGaze
//
//  Created by Chris Nixon on 07/01/2022.
//

import UIKit

class PDFListCell: UITableViewCell {
    
    typealias PDFTitleButtonAction = () -> Void
    
    @IBOutlet var pdfTitleButton: UIButton!
    
    var pdfTitleButtonAction: PDFTitleButtonAction?
    
    @IBAction func pdfTitleButtonTriggered(_ sender: UIButton) {
        pdfTitleButtonAction?()
    }
}
