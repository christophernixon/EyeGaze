//
//  StaticViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 17/01/2022.
//

import UIKit
import Vision

class StaticViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    private var faceLayers: [CAShapeLayer] = []
    var scaledImageRect: CGRect?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let image = UIImage(named: "sample6_data") {
            imageView.image = image
            
            guard let cgImage = image.cgImage else {
                return
            }
    
            calculateScaledImageRect()
            performVisionRequest(image: cgImage)
        }
    }
    
    private func calculateScaledImageRect() {
        guard let image = imageView.image else {
            return
        }

        guard let cgImage = image.cgImage else {
            return
        }

        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)

        let imageFrame = imageView.frame
        let widthRatio = originalWidth / imageFrame.width
        let heightRatio = originalHeight / imageFrame.height

        // ScaleAspectFit
        let scaleRatio = max(widthRatio, heightRatio)

        let scaledImageWidth = originalWidth / scaleRatio
        let scaledImageHeight = originalHeight / scaleRatio

        let scaledImageX = (imageFrame.width - scaledImageWidth) / 2
        let scaledImageY = (imageFrame.height - scaledImageHeight) / 2
        
        self.scaledImageRect = CGRect(x: scaledImageX, y: scaledImageY, width: scaledImageWidth, height: scaledImageHeight)
    }
    
    private func performVisionRequest(image: CGImage) {
         
         let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceDetectionRequest)

         let requests = [faceDetectionRequest]
         let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                         orientation: .up,
                                                         options: [:])
         
         DispatchQueue.global(qos: .userInitiated).async {
             do {
                 try imageRequestHandler.perform(requests)
             } catch let error as NSError {
                 print(error)
                 return
             }
         }
     }
    
    private func handleFaceDetectionRequest(request: VNRequest?, error: Error?) {
        if let requestError = error as NSError? {
            print(requestError)
            return
        }
        
        guard let imageRect = self.scaledImageRect else {
            return
        }
            
        let imageWidth = imageRect.size.width
        let imageHeight = imageRect.size.height
        
        DispatchQueue.main.async {
            
            self.imageView.layer.sublayers = nil
            if let results = request?.results as? [VNFaceObservation] {
                
                for observation in results {
                    
                    var scaledObservationRect = observation.boundingBox
                    scaledObservationRect.origin.x = imageRect.origin.x + (observation.boundingBox.origin.x * imageWidth)
                    scaledObservationRect.origin.y = imageRect.origin.y + (1 - observation.boundingBox.origin.y - observation.boundingBox.height) * imageHeight
                    scaledObservationRect.size.width *= imageWidth
                    scaledObservationRect.size.height *= imageHeight
                    print("\(scaledObservationRect.origin.x), \(scaledObservationRect.origin.y)\n\(scaledObservationRect.size.width), \(scaledObservationRect.size.height)")
                    
                    let faceRectanglePath = CGPath(rect: scaledObservationRect, transform: nil)
                    
                    let faceLayer = CAShapeLayer()
                    faceLayer.path = faceRectanglePath
                    faceLayer.fillColor = UIColor.clear.cgColor
                    faceLayer.strokeColor = UIColor.yellow.cgColor
                    self.faceLayers.append(faceLayer)
                    self.imageView.layer.addSublayer(faceLayer)
                    
                    //FACE LANDMARKS
                    if let landmarks = observation.landmarks {
                        if let leftEye = landmarks.leftEye {
                            self.handleLandmark(leftEye, faceBoundingBox: scaledObservationRect)
                        }
                        if let leftEyebrow = landmarks.leftEyebrow {
                            self.handleLandmark(leftEyebrow, faceBoundingBox: scaledObservationRect)
                        }
                        if let rightEye = landmarks.rightEye {
                            self.handleLandmark(rightEye, faceBoundingBox: scaledObservationRect)
                        }
                        if let rightEyebrow = landmarks.rightEyebrow {
                            self.handleLandmark(rightEyebrow, faceBoundingBox: scaledObservationRect)
                        }

                        if let nose = landmarks.nose {
                            self.handleLandmark(nose, faceBoundingBox: scaledObservationRect)
                        }

                        if let outerLips = landmarks.outerLips {
                            self.handleLandmark(outerLips, faceBoundingBox: scaledObservationRect)
                        }
                        if let innerLips = landmarks.innerLips {
                            self.handleLandmark(innerLips, faceBoundingBox: scaledObservationRect)
                        }
                    }
                }
            }
        }
    }
    
    private func handleLandmark(_ eye: VNFaceLandmarkRegion2D, faceBoundingBox: CGRect) {
        let landmarkPath = CGMutablePath()
        let landmarkPathPoints = eye.normalizedPoints
            .map({ eyePoint in
                CGPoint(
                    x: eyePoint.x * faceBoundingBox.width + faceBoundingBox.origin.x,
                    y: (1-eyePoint.y) * faceBoundingBox.height + faceBoundingBox.origin.y)
            })
//        let landmarkPathPoints = eye.normalizedPoints.map { VNImagePointForFaceLandmarkPoint(vector2(Float($0.x),Float($0.y)), faceBoundingBox, Int(self.scaledImageRect!.size.width), Int(self.scaledImageRect!.size.height)) }
        landmarkPath.addLines(between: landmarkPathPoints)
        landmarkPath.closeSubpath()
        let landmarkLayer = CAShapeLayer()
        landmarkLayer.path = landmarkPath
        landmarkLayer.fillColor = UIColor.clear.cgColor
        landmarkLayer.strokeColor = UIColor.green.cgColor

        self.faceLayers.append(landmarkLayer)
        self.view.layer.addSublayer(landmarkLayer)
    }
}
