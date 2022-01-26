//
//  DetectFeatures.swift
//  EyeGaze
//
//  Created by Chris Nixon on 14/01/2022.
//

import UIKit
import Vision
import CoreGraphics

class DetectFeatures {
    
//    static var faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: handleDetectedFaces)
    var image: CGImage?
    
    func predictGaze(model: iTracker, image: CGImage) -> (Double, Double) {
        // Create a request handler.
        let imageRequestHandler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            if let observations = request.results as? [VNFaceObservation] {
                self.handleObservations(observations: observations, image: image)
            }
        })
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
          print(error.localizedDescription)
        }
        return (0.0, 0.0)
    }
    
    func handleObservations(observations: [VNFaceObservation], image: CGImage) {
        
    }
    
    func cropParts(partsPoints points:[CGPoint],horizontalSpacing hPadding:CGFloat, verticalSpacing vPadding:CGFloat)->CGImage?{
        if let Minx = points.min(by: { a,b -> Bool in
            a.x < b.x
        }),
            let Miny = points.min(by: { a,b -> Bool in
                a.y < b.y
            }),
            let Maxx = points.max(by: { a,b -> Bool in
                a.x < b.x
            }),
            let Maxy = points.max(by: { a,b -> Bool in
                a.y < b.y
            }) {
            let partsWidth =  Maxx.x - Minx.x
            let partsHeight = Maxy.y - Miny.y
//            let originX = CGFloat(self.image!.width) - Minx.x
//            let originY = CGFloat(self.image!.height)-Miny.y
            let originX = Minx.x
            let originY = Miny.y
            let gRect = CGRect(x: originX - (partsWidth * hPadding), y: originY - (partsHeight * vPadding), width: partsWidth + (partsWidth * hPadding * 2), height: partsHeight + (partsHeight * vPadding * 2))
            
            // 224 x 224
            var xOffset: CGFloat
            var yOffset: CGFloat
            if partsWidth < 224 {
                xOffset = ((224 - partsWidth)/2) * -1
            } else {
                xOffset = ((partsWidth - 224)/2)
            }
            if partsHeight < 224 {
                yOffset = ((224 - partsHeight)/2) * -1
            } else {
                yOffset = ((partsHeight - 224)/2)
            }
            
            let gRect2 = CGRect(x: originX + xOffset, y: originY + yOffset, width: 223, height: 223)
           return self.image?.cropping(to: gRect2)
        } else {
            return nil
        }
    }
    
    // Landmark coord points are definitely normalized to the bounding box they are within.
    func convertCGPointToImageCoords(point: CGPoint, boundingBox: CGRect) -> CGPoint {
//        let xValue = point.x * CGFloat(self.image!.width)
//        let boundingBoxHeight = boundingBox.height * CGFloat(self.image!.height)
        
//        let testPoint = point.absolutePoint(in: boundingBox)
        let xValue = point.x * boundingBox.width + boundingBox.origin.x
        let yValue = (1-point.y) * boundingBox.height + boundingBox.origin.y
        return CGPoint(x: xValue, y: yValue)
    }
    
    func detectFeatures(model: iTracker, image: CGImage, completion: @escaping (FaceCropResult) -> Void) {
        let start: DispatchTime = .now()
        self.image = image
        
        // Create a request handler.
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: .up,
                                                        options: [:])
        
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let results = request.results as? [VNFaceObservation] else {
                completion(.notFound)
                return
            }
            
            var totalWidth = CGFloat(self.image!.width)
            var totalHeight = CGFloat(self.image!.height)
            
            let firstResult = results[0]
            print("bounding box width: \(firstResult.boundingBox.width),Height: \(firstResult.boundingBox.height)")
            print("Original image width: \(image.width),Height: \(image.height)")
//            print(firstResult.boundingBox)
            let w = firstResult.boundingBox.width * CGFloat(self.image!.width)
            let h = firstResult.boundingBox.height * CGFloat(self.image!.height)
            let x = firstResult.boundingBox.origin.x * CGFloat(self.image!.width)
            let y = (1 - firstResult.boundingBox.origin.y) * CGFloat(self.image!.height) - h
            
            let gRect = CGRect(x: x, y: y, width: w, height: h)
            
            let faceBox = firstResult.boundingBox
            // Vision coordinates are normalized and have lower-left origin.
            // Also, pixel buffer has .leftMirrored orientation.
            let cropRect = CGRect(x: (1 - faceBox.minY - faceBox.height) * totalWidth,
                                  y: (1 - faceBox.minX - faceBox.width) * totalHeight,
                                  width: faceBox.height * totalWidth,
                                  height: faceBox.width * totalHeight)
            
            let gRectAlt = VNImageRectForNormalizedRect(firstResult.boundingBox, self.image!.width, self.image!.height)
            guard let croppedFace = self.image?.cropping(to: gRect) else {
                completion(.notFound)
                return
            }
            
            guard let leftEyeLandmark = firstResult.landmarks?.leftEye else {
                completion(.notFound)
                return
            }
            
            guard let leftPupil = firstResult.landmarks?.leftPupil else {
                completion(.notFound)
                return
            }
            var leftPupilPoints = leftPupil.pointsInImage(imageSize: CGSize(width: self.image!.width, height: self.image!.height))
            var leftPupilPointsRaw = leftPupil.normalizedPoints
            
            guard let rightPupil = firstResult.landmarks?.rightPupil else {
                completion(.notFound)
                return
            }
            var rightPupilPoints = rightPupil.pointsInImage(imageSize: CGSize(width: self.image!.width, height: self.image!.height))
            var rightPupilPointsRaw = rightPupil.normalizedPoints
            
            var points = leftEyeLandmark.normalizedPoints
            let leftEyePoints = leftEyeLandmark.normalizedPoints.map { VNImagePointForFaceLandmarkPoint(vector2(Float($0.x),Float($0.y)), firstResult.boundingBox, self.image!.width, self.image!.height) }
            let leftEyePointsAlt = leftEyeLandmark.normalizedPoints.map { self.convertCGPointToImageCoords(point: $0, boundingBox: gRect) }

            guard let leftEyeImage = self.cropParts(partsPoints: leftEyePointsAlt, horizontalSpacing: CGFloat(0.5), verticalSpacing: CGFloat(1)) else {
                completion(.notFound)
                return
            }
            print("\(leftEyeImage.width), \(leftEyeImage.height)")
            
            guard let rightEyeLandmark = firstResult.landmarks?.rightEye else {
                completion(.notFound)
                return
            }
            var rightPoints = rightEyeLandmark.normalizedPoints
            let rightEyePoints = rightEyeLandmark.normalizedPoints.map { self.convertCGPointToImageCoords(point: $0, boundingBox: gRect) }

            guard let rightEyeImage = self.cropParts(partsPoints: rightEyePoints, horizontalSpacing: 0.5, verticalSpacing: 1) else {
                completion(.notFound)
                return
            }
            
            guard let mouthLandmark = firstResult.landmarks?.outerLips else {
                completion(.notFound)
                return
            }
            let mouthPointsRaw = mouthLandmark.normalizedPoints
            let mouthPoints = mouthLandmark.normalizedPoints
                        .map({ eyePoint in
                            CGPoint(
                                x: eyePoint.y * gRect.height + gRect.origin.x,
                                y: eyePoint.x * gRect.width + gRect.origin.y)
                        })
//            let mouthPoints = mouthLandmark.normalizedPoints.map { VNImagePointForFaceLandmarkPoint(vector2(Float($0.x),Float($0.y)), firstResult.boundingBox, self.image!.width, self.image!.height) }
            let mouthImage = self.cropParts(partsPoints: mouthPoints, horizontalSpacing: CGFloat(1), verticalSpacing: CGFloat(1))
            
            // Test facegrid function
            let faceGridMultiArray = PredictionUtilities.faceGridFromFaceRect(originalImage: UIImage(cgImage: image), detectedFaceRect: gRect, gridW: 25, gridH: 25)
            
            let targetSize = CGSize(width: 224, height: 224)
            let leftEye = PredictionUtilities.buffer(from: UIImage(cgImage: leftEyeImage), isGreyscale: false)
            let rightEye = PredictionUtilities.buffer(from: UIImage(cgImage: rightEyeImage), isGreyscale: false)
            let face = PredictionUtilities.buffer(from: UIImage(cgImage: croppedFace).resized(to: targetSize), isGreyscale: false)
            
            // Predict gaze
            guard let gazePredictionOutput = try? model.prediction(facegrid: faceGridMultiArray, image_face: face!, image_left: leftEye!, image_right: rightEye!) else {
                fatalError("Unexpected runtime error with prediction")
            }
            let result = gazePredictionOutput.fc3
            print("Automated Gaze Prediction: [\(result[0]),\(result[1])]")
            
            let returnImages = [leftEyeImage,rightEyeImage,croppedFace]
            let duration = start.distance(to: .now())
            print(duration)
            completion(.success((Double(truncating: result[0]), Double(truncating: result[1]), returnImages)))
        }
        
        faceDetectionRequest.constellation = .constellation76Points
        // Send the requests to the request handler.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform([faceDetectionRequest])
            } catch let error as NSError {
                completion(.failure(error))
            }
        }
        
    }
}

extension UIImage {
    public func resized(to target: CGSize) -> UIImage {
        let ratio = min(
            target.height / size.height, target.width / size.width
        )
        let new = CGSize(
            width: size.width * ratio, height: size.height * ratio
        )
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

extension TimeInterval {
    init?(dispatchTimeInterval: DispatchTimeInterval) {
        switch dispatchTimeInterval {
        case .seconds(let value):
            self = Double(value)
        case .milliseconds(let value):
            self = Double(value) / 1_000
        case .microseconds(let value):
            self = Double(value) / 1_000_000
        case .nanoseconds(let value):
            self = Double(value) / 1_000_000_000
        case .never:
            return nil
        }
    }
}

extension TimeInterval{

func stringFromTimeInterval() -> String {

    let time = NSInteger(self)

    let seconds = time % 60
    let minutes = (time / 60) % 60
    let hours = (time / 3600)

    var formatString = ""
    if hours == 0 {
        if(minutes < 10) {
            formatString = "%2d:%0.2d"
        }else {
            formatString = "%0.2d:%0.2d"
        }
        return String(format: formatString,minutes,seconds)
    }else {
        formatString = "%2d:%0.2d:%0.2d"
        return String(format: formatString,hours,minutes,seconds)
    }
}
}


//extension CGSize {
//  var cgPoint: CGPoint {
//    return CGPoint(x: width, y: height)
//  }
//}
//
//extension CGPoint {
//  var cgSize: CGSize {
//    return CGSize(width: x, height: y)
//  }
//
//  func absolutePoint(in rect: CGRect) -> CGPoint {
//    return CGPoint(x: x * rect.size.width, y: y * rect.size.height) + rect.origin
//  }
//}
//
//func + (left: CGPoint, right: CGPoint) -> CGPoint {
//  return CGPoint(x: left.x + right.x, y: left.y + right.y)
//}

public enum FaceCropResult {
    case success((Double, Double, [CGImage]))
    case notFound
    case failure(Error)
}
