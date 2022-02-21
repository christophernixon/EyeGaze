//
//  SeeSoViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 07/02/2022.
//

import SeeSo
import UIKit
import AVFoundation

class SeeSoViewController: UIViewController {
    
    var tracker : GazeTracker? = nil
    private var testCurrGazeLocLayers: [CAShapeLayer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if AVCaptureDevice .authorizationStatus(for: .video) == .authorized {
            GazeTracker.initGazeTracker(license: "dev_43fxidsg5vglj0ufxnt0j94ybvo8sxs59p5yvm1u", delegate: self)
        }else{
            AVCaptureDevice.requestAccess(for: .video, completionHandler: {
                response in
                if response {
                    GazeTracker.initGazeTracker(license: "dev_43fxidsg5vglj0ufxnt0j94ybvo8sxs59p5yvm1u", delegate: self)
                }
            })
        }
    }
}
extension SeeSoViewController : InitializationDelegate {
    func onInitialized(tracker: GazeTracker?, error: InitializationError) {
        if (tracker != nil){
            self.tracker = tracker
            print("initalized GazeTracker")
            self.tracker?.statusDelegate = self
            self.tracker?.gazeDelegate = self
            self.tracker?.startTracking()
        }else{
            print("init failed : \(error.description)")
        }
    }
}

extension SeeSoViewController : StatusDelegate {
    func onStarted() {
        print("tracker starts tracking.")
    }
    
    func onStopped(error: StatusError) {
        print("stop error : \(error.description)")
    }
}

extension SeeSoViewController : GazeDelegate {
    
    func onGaze(gazeInfo : GazeInfo) {
        print("timestamp : \(gazeInfo.timestamp), (x , y) : (\(gazeInfo.x), \(gazeInfo.y)) , state : \(gazeInfo.trackingState.description)")
        if (!gazeInfo.x.isNaN) {
            drawGreenDot(location: CGPoint(x: gazeInfo.x, y: gazeInfo.y))
        }
    }
    
    func drawGreenDot(location: CGPoint) {
        self.testCurrGazeLocLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
        let outerDot = UIBezierPath(arcCenter: location, radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        var shapeLayer = CAShapeLayer()
        shapeLayer.path = outerDot.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.green.cgColor
        shapeLayer.lineWidth = CGFloat(3)
        view.layer.addSublayer(shapeLayer)
        self.testCurrGazeLocLayers.append(shapeLayer)
        
        let innerDot = UIBezierPath(arcCenter: location, radius: CGFloat(3), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        shapeLayer = CAShapeLayer()
        shapeLayer.path = innerDot.cgPath
        shapeLayer.fillColor = UIColor.green.cgColor
        view.layer.addSublayer(shapeLayer)
        self.testCurrGazeLocLayers.append(shapeLayer)
    }
}
