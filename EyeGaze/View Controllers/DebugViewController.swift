//
//  DebugViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 23/01/2022.
//

import AVFoundation
import Vision
import VideoToolbox
import UIKit

class DebugViewController: UIViewController {
    private let captureSession = AVCaptureSession()
//    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    @IBOutlet var faceImageView: UIImageView!
    @IBOutlet var leftEyeImageView: UIImageView!
    @IBOutlet var rightEyeImageView: UIImageView!
    
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var faceLayers: [CAShapeLayer] = []
    private var iTrackerModel: iTracker_v2?
    private var predictionQueue: [(Double, Double)]?
    
    func configure(with iTrackerModel: iTracker_v2) {
        self.iTrackerModel = iTrackerModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.predictionQueue = [(Double, Double)] (repeating: (0.0,0.0), count: 5)
        setupCamera()
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        self.previewLayer.frame = self.view.frame
    }
    
    private func setupCamera() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                    
                    setupPreview()
                }
            }
        }
    }
    
    private func setupPreview() {
//        self.previewLayer.videoGravity = .resizeAspectFill
//        self.view.layer.addSublayer(self.previewLayer)
//        self.previewLayer.frame = self.view.frame

        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]

        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera queue"))
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.captureSession.addOutput(self.videoDataOutput)

        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
    }
}

extension DebugViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let start: DispatchTime = .now()
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
          return
        }
        
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(imageBuffer, options: nil, imageOut: &cgImage)

        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.sync {
                self.faceLayers.forEach({ drawing in drawing.removeFromSuperlayer() })

                if let observations = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionObservations(observations: observations, image: cgImage!, time: start, predictionQueue: self.predictionQueue!)
                }
            }
        })

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: [:])

        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
          print(error.localizedDescription)
        }
    }
    
    private func handleFaceDetectionObservations(observations: [VNFaceObservation], image: CGImage, time: DispatchTime, predictionQueue: [(Double,Double)]) {
        for observation in observations {
            let firstResult = observation
            let w = firstResult.boundingBox.width * CGFloat(image.width)
            let h = firstResult.boundingBox.height * CGFloat(image.height)
            let x = firstResult.boundingBox.origin.x * CGFloat(image.width)
            let y = (1 - firstResult.boundingBox.origin.y) * CGFloat(image.height) - h
            
            let gRect = CGRect(x: x, y: y, width: w, height: h)
        
//            guard let croppedFace = image.cropping(to: gRect) else { return }
            guard let croppedFace = PredictionUtilities.cropParts(originalImage: image, partRect: gRect, horizontalSpacing: 0, verticalSpacing: 0) else { return }
            
            guard let leftEyeLandmark = firstResult.landmarks?.leftEye else { return }
            let leftEyePoints = leftEyeLandmark.normalizedPoints.map { PredictionUtilities.convertCGPointToImageCoords(point: $0, boundingBox: gRect) }
            guard let leftEyeImage = PredictionUtilities.cropParts(originalImage: image, partsPoints: leftEyePoints, horizontalSpacing: 0.5, verticalSpacing: 3.0) else { return }
            
            guard let rightEyeLandmark = firstResult.landmarks?.rightEye else { return }
            let rightEyePoints = rightEyeLandmark.normalizedPoints.map { PredictionUtilities.convertCGPointToImageCoords(point: $0, boundingBox: gRect) }
            guard let rightEyeImage = PredictionUtilities.cropParts(originalImage: image, partsPoints: rightEyePoints, horizontalSpacing: 0.5, verticalSpacing: 3.0) else { return }
            
            let faceGridMultiArray = PredictionUtilities.faceGridFromFaceRect(originalImage: UIImage(cgImage: image), detectedFaceRect: gRect, gridW: 25, gridH: 25)
            
            let targetSize = CGSize(width: 224, height: 224)
            let leftEye = PredictionUtilities.buffer(from: UIImage(cgImage: leftEyeImage).resized(to: targetSize), isGreyscale: false)
            let rightEye = PredictionUtilities.buffer(from: UIImage(cgImage: rightEyeImage).resized(to: targetSize), isGreyscale: false)
            let face = PredictionUtilities.buffer(from: UIImage(cgImage: croppedFace).resized(to: targetSize), isGreyscale: false)
            
//            print("Boundingbox width: \(firstResult.boundingBox.width),Height: \(firstResult.boundingBox.height)")
//            print("original image width: \(image.width),Height: \(image.height)")
//            print("Face width: \(croppedFace.width),Height: \(croppedFace.height)")
//            print("LeftEye width: \(leftEyeImage.width),Height: \(leftEyeImage.height)")
//            print("RightEye width: \(rightEyeImage.width),Height: \(rightEyeImage.height)")
            
            self.faceImageView.image = UIImage(cgImage: croppedFace)
            self.leftEyeImageView.image = UIImage(cgImage: leftEyeImage).resized(to: targetSize)
            self.rightEyeImageView.image = UIImage(cgImage: rightEyeImage).resized(to: targetSize)
            
            // Predict gaze
            guard let gazePredictionOutput = try? self.iTrackerModel!.prediction(facegrid: faceGridMultiArray, image_face: face!, image_left: rightEye!, image_right: leftEye!) else {
                print("SOMETHING WENT WRONG!!!!")
                return
            }
            let result = gazePredictionOutput.fc3
//            print("Automated Gaze Prediction: [\(result[0]),\(result[1])]")
            let (screenX, screenY) = PredictionUtilities.predictionToScreenCoords(xPrediction: Double(truncating: result[0]), yPrediction: Double(truncating: result[1]), orientation: CGImagePropertyOrientation.up)
            let shapeLayer = CAShapeLayer()
//            let center = view.center
            let circulPath = UIBezierPath(arcCenter: CGPoint(x: screenX, y: screenY), radius: 12, startAngle: 0, endAngle: 2.0 * CGFloat.pi, clockwise: true)

            shapeLayer.path = circulPath.cgPath
            shapeLayer.fillColor = UIColor.green.cgColor
            self.faceLayers.append(shapeLayer)
            self.view.layer.addSublayer(shapeLayer)
            
            // Calculate rolling average
            var lastThreeAverageX = 0.0
            var lastThreeAverageY = 0.0
//            DispatchQueue.main.sync {
            var lastThreeSumX = 0.0
            var lastThreeSumY = 0.0
            for i in 0..<predictionQueue.count {
                lastThreeSumX += predictionQueue[i].0
                lastThreeSumY += predictionQueue[i].1
            }
            lastThreeAverageX = lastThreeSumX/5
            lastThreeAverageY = lastThreeSumY/5

            // Update predictionQueue
            var returnQueue: [(Double,Double)] = [(Double, Double)] (repeating: (0.0,0.0), count: 5)
            returnQueue[0] = (predictionQueue[1])
            returnQueue[1] = (predictionQueue[2])
            returnQueue[2] = (predictionQueue[3])
            returnQueue[3] = (predictionQueue[4])
            returnQueue[4] = (screenX, screenY)
            self.predictionQueue = returnQueue
//            }

            // Draw average dot
            let shapeLayer2 = CAShapeLayer()
//            let center = view.center
            let circulPath2 = UIBezierPath(arcCenter: CGPoint(x: lastThreeAverageX, y: lastThreeAverageY), radius: 12, startAngle: 0, endAngle: 2.0 * CGFloat.pi, clockwise: true)

            shapeLayer2.path = circulPath2.cgPath
            shapeLayer2.fillColor = UIColor.red.cgColor
            self.faceLayers.append(shapeLayer2)
            self.view.layer.addSublayer(shapeLayer2)
            
            let duration = time.distance(to: .now())
//            print(duration)
        }
        
        // Normal stuff
//        for observation in observations {
//            let faceRectConverted = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
//            let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
//
//            let faceLayer = CAShapeLayer()
//            faceLayer.path = faceRectanglePath
//            faceLayer.fillColor = UIColor.clear.cgColor
//            faceLayer.strokeColor = UIColor.yellow.cgColor
//
//            self.faceLayers.append(faceLayer)
//            self.view.layer.addSublayer(faceLayer)
//
//            //FACE LANDMARKS
//            if let landmarks = observation.landmarks {
//                if let leftEye = landmarks.leftEye {
//                    self.handleLandmark(leftEye, faceBoundingBox: faceRectConverted)
//                }
//                if let leftEyebrow = landmarks.leftEyebrow {
//                    self.handleLandmark(leftEyebrow, faceBoundingBox: faceRectConverted)
//                }
//                if let rightEye = landmarks.rightEye {
//                    self.handleLandmark(rightEye, faceBoundingBox: faceRectConverted)
//                }
//                if let rightEyebrow = landmarks.rightEyebrow {
//                    self.handleLandmark(rightEyebrow, faceBoundingBox: faceRectConverted)
//                }
//
//                if let nose = landmarks.nose {
//                    self.handleLandmark(nose, faceBoundingBox: faceRectConverted)
//                }
//
//                if let outerLips = landmarks.outerLips {
//                    self.handleLandmark(outerLips, faceBoundingBox: faceRectConverted)
//                }
//                if let innerLips = landmarks.innerLips {
//                    self.handleLandmark(innerLips, faceBoundingBox: faceRectConverted)
//                }
//            }
//        }
    }
    
    private func handleLandmark(_ eye: VNFaceLandmarkRegion2D, faceBoundingBox: CGRect) {
        let landmarkPath = CGMutablePath()
        let landmarkPathPoints = eye.normalizedPoints
            .map({ eyePoint in
                CGPoint(
                    x: eyePoint.y * faceBoundingBox.height + faceBoundingBox.origin.x,
                    y: eyePoint.x * faceBoundingBox.width + faceBoundingBox.origin.y)
            })
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
