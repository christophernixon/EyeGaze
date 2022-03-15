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
        //        self.centralView.center = self.center
        //        self.centralView.bounds.size = CGSize(width: 100, height: 100)
        self.centralView.frame = CGRect(x: self.frame.minX, y: self.frame.minY + self.frame.height/2, width: self.frame.width, height: self.frame.height/2)
        //        self.centralView.layer.cornerRadius = 50
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FullMaskView: UIView {
    //    let centralView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //        self.addSubview(self.centralView)
        self.backgroundColor = .clear
        //        self.centralView.backgroundColor = .red
        //        self.centralView.clipsToBounds = true
        //        self.centralView.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: self.frame.width, height: self.frame.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
