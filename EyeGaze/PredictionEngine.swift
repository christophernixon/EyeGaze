//
//  PredictionEngine.swift
//  EyeGaze
//
//  Created by Chris Nixon on 26/01/2022.
//

import UIKit
import Vision
import VideoToolbox
import CoreGraphics

class PredictionEngine {
    
    private(set) var currentGazePrediction: (Double, Double) = (0,0)
    private(set) var currentGazePredictionCM: (Double, Double) = (0,0)
    private(set) var currentGazePredictionRaw: (Double, Double) = (0,0)
    private var iTrackerModel: iTracker_v2
    
    private(set) var faceCGImage: CGImage?
    private(set) var leftEyeCGImage: CGImage?
    private(set) var rightEyeCGImage: CGImage?
    
    init(model: iTracker_v2) {
        self.iTrackerModel = model
    }
    
    func predictGaze(sampleBuffer: CMSampleBuffer, completion: @escaping (GazeDetectionResult) -> Void) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            completion(.notFound)
            return
        }
        var cgImagePointer: CGImage?
        VTCreateCGImageFromCVPixelBuffer(imageBuffer, options: nil, imageOut: &cgImagePointer)
        guard let cgImage = cgImagePointer else {
            completion(.notFound)
            return
        }
        return predictGaze(image: cgImage, completion: completion)
    }
    
    func predictGaze(image: CGImage, completion: @escaping (GazeDetectionResult) -> Void) {
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let observations = request.results as? [VNFaceObservation] {
                if (observations.count == 0) {
                    completion(.notFound)
                    return
                }
                self.handleObservations(observations: observations, image: image, completion: completion)
            } else {
                completion(.notFound)
                return
            }
        })
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
          print(error.localizedDescription)
        }
    }
    
    func handleObservations(observations: [VNFaceObservation], image: CGImage, completion: @escaping (GazeDetectionResult) -> Void) {
        if observations.isEmpty {
            return
        } else { // Only use first face observed.
            let observation = observations[0]
            
            let w = observation.boundingBox.width * CGFloat(image.width)
            let h = observation.boundingBox.height * CGFloat(image.height)
            let x = observation.boundingBox.origin.x * CGFloat(image.width)
            let y = (1 - observation.boundingBox.origin.y) * CGFloat(image.height) - h
            let faceRectangle = CGRect(x: x, y: y, width: w, height: h)
            guard let faceImage = PredictionUtilities.cropParts(originalImage: image, partRect: faceRectangle, horizontalSpacing: 0.1, verticalSpacing: 0.1) else { return }
            
            guard let leftEyeLandmark = observation.landmarks?.leftEye else { return }
            let leftEyePoints = leftEyeLandmark.normalizedPoints.map { PredictionUtilities.convertCGPointToImageCoords(point: $0, boundingBox: faceRectangle) }
            guard let leftEyeImage = PredictionUtilities.cropParts(originalImage: image, partsPoints: leftEyePoints, horizontalSpacing: 0.5, verticalSpacing: 3.0) else { return }
            
            guard let rightEyeLandmark = observation.landmarks?.rightEye else { return }
            let rightEyePoints = rightEyeLandmark.normalizedPoints.map { PredictionUtilities.convertCGPointToImageCoords(point: $0, boundingBox: faceRectangle) }
            guard let rightEyeImage = PredictionUtilities.cropParts(originalImage: image, partsPoints: rightEyePoints, horizontalSpacing: 0.5, verticalSpacing: 3.0) else { return }
            
            let faceGridMultiArray = PredictionUtilities.faceGridFromFaceRect(originalImage: UIImage(cgImage: image), detectedFaceRect: faceRectangle, gridW: 25, gridH: 25)
            
            // Save cropped face and eye images
            self.faceCGImage = faceImage
            self.leftEyeCGImage = leftEyeImage
            self.rightEyeCGImage = rightEyeImage
            
            let targetSize = CGSize(width: 224, height: 224)
            guard let leftEyeBuffer = PredictionUtilities.buffer(from: UIImage(cgImage: leftEyeImage).resized(to: targetSize), isGreyscale: false) else { return }
            guard let rightEyeBuffer = PredictionUtilities.buffer(from: UIImage(cgImage: rightEyeImage).resized(to: targetSize), isGreyscale: false) else { return }
            guard let faceBuffer = PredictionUtilities.buffer(from: UIImage(cgImage: faceImage).resized(to: targetSize), isGreyscale: false) else { return }
            
            // Predict gaze
            guard let gazePredictionOutput = try? self.iTrackerModel.prediction(facegrid: faceGridMultiArray, image_face: faceBuffer, image_left: rightEyeBuffer, image_right: leftEyeBuffer) else { return }
            let predictedX = Double(truncating: gazePredictionOutput.fc3[0])
            let predictedY = Double(truncating: gazePredictionOutput.fc3[1])
            let (screenX, screenY) = PredictionUtilities.predictionToScreenCoords(xPrediction: predictedX, yPrediction: predictedY, orientation: CGImagePropertyOrientation.up)
            
            self.currentGazePredictionCM = (predictedX, predictedY)
            self.currentGazePrediction = (screenX, screenY)
            self.currentGazePredictionRaw = (predictedX, predictedY)
            completion(.success(self.currentGazePredictionRaw))
        }
    }
}
