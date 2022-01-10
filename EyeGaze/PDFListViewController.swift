//
//  ViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 21/12/2021.
//

import PDFKit
import UIKit
import Vision

class PDFListViewController: UITableViewController {

    static let showPDFSegueIdentifier = "ShowPDFSegue"
    
    private var pdfListDataSource: PDFListDataSource?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.showPDFSegueIdentifier,
           let destination = segue.destination as? PDFViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let pdf = PDF.testData[indexPath.row]
            destination.configure(with: pdf)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pdfListDataSource = PDFListDataSource()
        tableView.dataSource = pdfListDataSource
        navigationItem.title = NSLocalizedString("Sheet Music Library", comment: "PDFList nav title")
//        guard let model = try? VNCoreMLModel(for: BVLCObjectClassifier().model) else {
//            fatalError("Failed to create a model instance.")
//        }
        let model = BVLCObjectClassifier()
        let faceGridInput = UIImage(named: "sample_data_face_grid")
        let leftEyeInput = UIImage(named: "sample_data_left_eye_2")
        let rightEyeInput = UIImage(named: "sample_data_right_eye_2")
        let faceInput = UIImage(named: "sample_data_face")
        let faceGrid = buffer(from: faceGridInput!, isGreyscale: true)
        let face = buffer(from: faceInput!, isGreyscale: false)
        let leftEye = buffer(from: leftEyeInput!, isGreyscale: false)
        let rightEye = buffer(from: rightEyeInput!, isGreyscale: false)
        guard let gazePredictionOutput = try? model.prediction(facegrid: faceGrid!, image_face: face!, image_left: leftEye!, image_right: rightEye!) else {
            fatalError("Unexpected runtime error with prediction")
        }
        let result = gazePredictionOutput.fc3
        print(result)
        if let b = try? UnsafeBufferPointer<Double>(result) {
          let c = Array(b)
          print(c)
        }
        let resultArray = convertToArray(from: result)
        print(resultArray)
    }
    
    func myResultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation]
            else { fatalError("huh") }
        for classification in results {
            print(classification.identifier, // the scene label
                  classification.confidence)
        }

    }
    
    func convertToArray(from mlMultiArray: MLMultiArray) -> [Double] {
        
        // Init our output array
        var array: [Double] = []
        
        // Get length
        let length = mlMultiArray.count
        
        // Set content of multi array to our out put array
        for i in 0...length - 1 {
            array.append(Double(truncating: mlMultiArray[[0,NSNumber(value: i)]]))
        }
        
        return array
    }
    
    func buffer(from image: UIImage, isGreyscale: Bool) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = isGreyscale ? CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_OneComponent8, attrs, &pixelBuffer) : CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
        return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let colorSpace = isGreyscale ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB()
        let context = isGreyscale ? CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: colorSpace, bitmapInfo: 0) : CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }

}

