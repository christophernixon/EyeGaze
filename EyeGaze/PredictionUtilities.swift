//
//  PredictionUtilities.swift
//  EyeGaze
//
//  Created by Chris Nixon on 12/01/2022.
//

import UIKit
import CoreML

class PredictionUtilities {
    
    static func faceGridFromFaceRect(originalImage: UIImage, detectedFaceRect: CGRect, gridW: Int, gridH: Int) -> MLMultiArray {
        let frameW = originalImage.size.width
        let frameH = originalImage.size.height
        let scaleX = CGFloat(gridW) / frameW
        let scaleY = CGFloat(gridH) / frameH
        var facegrid = [[Double]] (repeating: [Double] (repeating: 0, count: gridH), count: gridW)
        var xLow = Float(detectedFaceRect.origin.x * CGFloat(scaleX)).toIntTruncated()
        var yLow = Float(detectedFaceRect.origin.y * CGFloat(scaleY)).toIntTruncated()
        let width = Float(detectedFaceRect.width * CGFloat(scaleX)).toIntTruncated()
        let height = Float(detectedFaceRect.height * CGFloat(scaleY)).toIntTruncated()
        var xHigh = xLow + width
        var yHigh = yLow + height
        
        // Make sure all values are within correct indexing range
        xLow = min(gridW-1, max(0, xLow))
        yLow = min(gridH-1, max(0, yLow))
        xHigh = min(gridW-1, max(0, xHigh))
        yHigh = min(gridH-1, max(0, yHigh))
        
        for x in xLow...xHigh {
            for y in yLow...yHigh {
                facegrid[y][x] = 1
            }
        }
        
//        for ( _, element) in facegrid.enumerated() {
//            print(element)
//        }
        
        let facegridFlattened = facegrid.reduce([], +)
        
        let shape = [1, 625, 1] as [NSNumber]
        guard let doubleMultiarray = try? MLMultiArray(shape: shape, dataType: .float) else {
            fatalError("Couldn't initialise mlmultiarry from facegrid")
        }
        for (i, element) in facegridFlattened.enumerated() {
            let key = [0, i, 0] as [NSNumber]
            doubleMultiarray[key] = element as NSNumber
        }
        return doubleMultiarray
    }
    
    static func pixelValuesFromImage(imageRef: CGImage?) -> (pixelValues: [UInt8]?, width: Int, height: Int)
    {
        var width = 0
        var height = 0
        var pixelValues: [UInt8]?
        if let imageRef = imageRef {
            let totalBytes = imageRef.width * imageRef.height
            let colorSpace = CGColorSpaceCreateDeviceGray()
            
            pixelValues = [UInt8](repeating: 0, count: totalBytes)
            pixelValues?.withUnsafeMutableBytes({
                width = imageRef.width
                height = imageRef.height
                let contextRef = CGContext(data: $0.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: 0)
                let drawRect = CGRect(x: 0.0, y:0.0, width: CGFloat(width), height: CGFloat(height))
                contextRef?.draw(imageRef, in: drawRect)
            })
        }

        return (pixelValues, width, height)
    }

    static func buffer(from image: UIImage, isGreyscale: Bool) -> CVPixelBuffer? {
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
    
    static func convertToArray(from mlMultiArray: MLMultiArray) -> [Double] {
        
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
}

extension Float {
    func toIntTruncated() -> Int {
        let maxTruncated  = min(self, Float(Int.max).nextDown)
        let bothTruncated = max(maxTruncated, Float(Int.min))
        return Int(bothTruncated)
    }
}
