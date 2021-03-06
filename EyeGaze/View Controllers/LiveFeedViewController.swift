//
//  LiveFeedViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 17/01/2022.
//

import AVFoundation
import Vision
import VideoToolbox
import UIKit

class LiveFeedViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var faceLayers: [CAShapeLayer] = []
    private var iTrackerModel: iTracker_v2?
    
    func configure(with iTrackerModel: iTracker_v2) {
        self.iTrackerModel = iTrackerModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
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
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
        
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]

        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        
        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
    }
}

extension LiveFeedViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
          return
        }
        
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(imageBuffer, options: nil, imageOut: &cgImage)

        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                self.faceLayers.forEach({ drawing in drawing.removeFromSuperlayer() })

                if let observations = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionObservations(observations: observations, image: cgImage!)
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
    
    private func handleFaceDetectionObservations(observations: [VNFaceObservation], image: CGImage) {
        for observation in observations {
            let firstResult = observation
            let w = firstResult.boundingBox.width * CGFloat(image.width)
            let h = firstResult.boundingBox.height * CGFloat(image.height)
            let x = firstResult.boundingBox.origin.x * CGFloat(image.width)
            let y = (1 - firstResult.boundingBox.origin.y) * CGFloat(image.height) - h
            
            let gRect = CGRect(x: x, y: y, width: w, height: h)
        
            guard let croppedFace = image.cropping(to: gRect) else { return }
            
            guard let leftEyeLandmark = firstResult.landmarks?.leftEye else { return }
            let leftEyePoints = leftEyeLandmark.normalizedPoints.map { PredictionUtilities.convertCGPointToImageCoords(point: $0, boundingBox: gRect) }
            guard let leftEyeImage = PredictionUtilities.cropParts(originalImage: image, partsPoints: leftEyePoints, horizontalSpacing: CGFloat(0.5), verticalSpacing: CGFloat(1)) else { return }
            
            guard let rightEyeLandmark = firstResult.landmarks?.rightEye else { return }
            let rightEyePoints = rightEyeLandmark.normalizedPoints.map { PredictionUtilities.convertCGPointToImageCoords(point: $0, boundingBox: gRect) }
            guard let rightEyeImage = PredictionUtilities.cropParts(originalImage: image, partsPoints: rightEyePoints, horizontalSpacing: 0.5, verticalSpacing: 1) else { return }
            
            let faceGridMultiArray = PredictionUtilities.faceGridFromFaceRect(originalImage: UIImage(cgImage: image), detectedFaceRect: gRect, gridW: 25, gridH: 25)
            
            let targetSize = CGSize(width: 224, height: 224)
            let leftEye = PredictionUtilities.buffer(from: UIImage(cgImage: leftEyeImage), isGreyscale: false)
            let rightEye = PredictionUtilities.buffer(from: UIImage(cgImage: rightEyeImage), isGreyscale: false)
            let face = PredictionUtilities.buffer(from: UIImage(cgImage: croppedFace).resized(to: targetSize), isGreyscale: false)
            
            // Predict gaze
            guard let gazePredictionOutput = try? self.iTrackerModel!.prediction(facegrid: faceGridMultiArray, image_face: face!, image_left: leftEye!, image_right: rightEye!) else {
                print("SOMETHING WENT WRONG!!!!")
                return
            }
            let result = gazePredictionOutput.fc3
            print("Automated Gaze Prediction: [\(result[0]),\(result[1])]")
            let (screenX, screenY) = PredictionUtilities.predictionToScreenCoords(xPrediction: Double(result[0]), yPrediction: Double(result[1]), orientation: CGImagePropertyOrientation.up)
            let shapeLayer = CAShapeLayer()
            let circulPath = UIBezierPath(arcCenter: CGPoint(x: screenX, y: screenY), radius: 12, startAngle: 0, endAngle: 2.0 * CGFloat.pi, clockwise: true)

            shapeLayer.path = circulPath.cgPath
            shapeLayer.fillColor = UIColor.green.cgColor
            self.faceLayers.append(shapeLayer)
            self.view.layer.addSublayer(shapeLayer)
            
        }
        
        // Normal stuff
        for observation in observations {
            let faceRectConverted = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
            let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
            
            let faceLayer = CAShapeLayer()
            faceLayer.path = faceRectanglePath
            faceLayer.fillColor = UIColor.clear.cgColor
            faceLayer.strokeColor = UIColor.yellow.cgColor
            
            self.faceLayers.append(faceLayer)
            self.view.layer.addSublayer(faceLayer)
            
            //FACE LANDMARKS
            if let landmarks = observation.landmarks {
                if let leftEye = landmarks.leftEye {
                    self.handleLandmark(leftEye, faceBoundingBox: faceRectConverted)
                }
                if let leftEyebrow = landmarks.leftEyebrow {
                    self.handleLandmark(leftEyebrow, faceBoundingBox: faceRectConverted)
                }
                if let rightEye = landmarks.rightEye {
                    self.handleLandmark(rightEye, faceBoundingBox: faceRectConverted)
                }
                if let rightEyebrow = landmarks.rightEyebrow {
                    self.handleLandmark(rightEyebrow, faceBoundingBox: faceRectConverted)
                }

                if let nose = landmarks.nose {
                    self.handleLandmark(nose, faceBoundingBox: faceRectConverted)
                }

                if let outerLips = landmarks.outerLips {
                    self.handleLandmark(outerLips, faceBoundingBox: faceRectConverted)
                }
                if let innerLips = landmarks.innerLips {
                    self.handleLandmark(innerLips, faceBoundingBox: faceRectConverted)
                }
            }
        }
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
