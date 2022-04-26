//
//  Mask.swift
//  EyeGaze
//
//  Created by Chris Nixon on 11/03/2022.
//

import Foundation
import UIKit

class MaskView: UIView {
    
    let centralView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.centralView)
        self.backgroundColor = UIColor.clear
        self.centralView.backgroundColor = .red
        self.centralView.clipsToBounds = true
        self.centralView.frame = CGRect(x: self.frame.minX, y: self.frame.minY + self.frame.height/2, width: self.frame.width, height: self.frame.height/2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FullMaskView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
