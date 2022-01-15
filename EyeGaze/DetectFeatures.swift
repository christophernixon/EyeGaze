//
//  DetectFeatures.swift
//  EyeGaze
//
//  Created by Chris Nixon on 14/01/2022.
//

import UIKit
import Vision

class DetectFeatures {
    
//    static var faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: handleDetectedFaces)
    var image: CGImage?
    
    func detectFeatures(image: CGImage, completion: @escaping (FaceCropResult) -> Void) {
        
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
            
            let firstResult = results[0]
            print(firstResult.boundingBox)
            let w = firstResult.boundingBox.width * CGFloat(self.image!.width)
            let h = firstResult.boundingBox.height * CGFloat(self.image!.height)
            let x = firstResult.boundingBox.origin.x * CGFloat(self.image!.width)
            let y = (1 - firstResult.boundingBox.origin.y) * CGFloat(self.image!.height) - h
            
            let gRect = CGRect(x: x, y: y, width: w, height: h)
            let croppedFace = self.image?.cropping(to: gRect)
            
            guard let returnImage = croppedFace else {
                completion(.notFound)
                return
            }
            completion(.success(returnImage))
        }
        
        // Send the requests to the request handler.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform([faceDetectionRequest])
            } catch let error as NSError {
                completion(.failure(error))
            }
        }
//        guard let faceObservations = faceDetectionRequest.results as? [VNFaceObservation] else {
//            return
//        }
//        lazy var faceLandmarkRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleDetectedFaceLandmarks)
        
    }
    
//    fileprivate func handleDetectedFaces(request: VNRequest?, error: Error?) {
//        if let error = error {
////            completion(.failure(error))
//            return
//        }
//        guard let results = request?.results as? [VNFaceObservation] else {
//            return
//        }
//        let firstResult = results[0]
//        print(firstResult.boundingBox)
//        let w = firstResult.boundingBox.width * CGFloat(self.image!.width)
//        let h = firstResult.boundingBox.height * CGFloat(self.image!.height)
//        let x = firstResult.boundingBox.origin.x * CGFloat(self.image!.width)
//        let y = (1 - firstResult.boundingBox.origin.y) * CGFloat(self.image!.height) - h
//
//
//    }
}

public extension CGImage {
    @available(iOS 11.0, *)
    func faceCrop(margin: CGFloat = 200, completion: @escaping (FaceCropResult) -> Void) {
        let req = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let results = request.results, !results.isEmpty else {
                completion(.notFound)
                return
            }
            
            var faces: [VNFaceObservation] = []
            for result in results {
                guard let face = result as? VNFaceObservation else { continue }
                faces.append(face)
            }
            
            let croppingRect = self.getCroppingRect(for: faces, margin: margin)
            let faceImage = self.cropping(to: croppingRect)
            
            guard let result = faceImage else {
                completion(.notFound)
                return
            }
            completion(.success(result))
        }
        
        do {
            try VNImageRequestHandler(cgImage: self, options: [:]).perform([req])
        } catch let error {
            completion(.failure(error))
        }
    }
    
    @available(iOS 11.0, *)
    private func getCroppingRect(for faces: [VNFaceObservation], margin: CGFloat) -> CGRect {
        var totalX = CGFloat(0)
        var totalY = CGFloat(0)
        var totalW = CGFloat(0)
        var totalH = CGFloat(0)
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        let numFaces = CGFloat(faces.count)
        
        for face in faces {
            let w = face.boundingBox.width * CGFloat(width)
            let h = face.boundingBox.height * CGFloat(height)
            let x = face.boundingBox.origin.x * CGFloat(width)
            let y = (1 - face.boundingBox.origin.y) * CGFloat(height) - h
            totalX += x
            totalY += y
            totalW += w
            totalH += h
            minX = .minimum(minX, x)
            minY = .minimum(minY, y)
        }
        
        let avgX = totalX / numFaces
        let avgY = totalY / numFaces
        let avgW = totalW / numFaces
        let avgH = totalH / numFaces
        
        let offset = margin + avgX - minX
        
        return CGRect(x: avgX - offset, y: avgY - offset, width: avgW + (offset * 2), height: avgH + (offset * 2))
    }
}

public enum FaceCropResult {
    case success(CGImage)
    case notFound
    case failure(Error)
}
