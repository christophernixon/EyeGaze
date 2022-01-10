//
//  PDFListDataSource.swift
//  EyeGaze
//
//  Created by Chris Nixon on 07/01/2022.
//

import UIKit

class PDFListDataSource: NSObject {
    
}

extension PDFListDataSource: UITableViewDataSource {
    
    static let PDFCellIdentifer = "PDFListCell"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PDF.testData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.PDFCellIdentifer, for: indexPath) as? PDFListCell else {
            fatalError("Unable to dequeue PDF list cell")
        }
        let pdf = PDF.testData[indexPath.row]
        cell.pdfTitleLabel.text = pdf.title
        return cell
    }
    
    
}
