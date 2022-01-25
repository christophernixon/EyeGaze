//
//  PredictionUtilities.swift
//  EyeGaze
//
//  Created by Chris Nixon on 12/01/2022.
//

import UIKit
import CoreML

class PredictionUtilities {
    
    static func predictionToScreenCoords(xPrediction: Double, yPrediction: Double, orientation: CGImagePropertyOrientation) -> (screenX: Double, screenY: Double) {
        // Distance from camera to top-left corner of screen
        let deviceCameraToScreenXmm = 80
        let deviceCameraToScreenYmm = 5
        // iPad Pro 11" dimensions according to https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/
        let deviceScreenWidthPoints: Double = 834
        let deviceScreenHeightPoints: Double = 1194
        
        let deviceScreenWidthmm: Double = 160
        let deviceScreenHeightmm: Double = 229
        
        let pointsPerMmX = deviceScreenWidthPoints/deviceScreenWidthmm
        let pointsPerMmY = deviceScreenHeightPoints/deviceScreenHeightmm
        
        // Assuming portrait orientation, convert predictions to mm and then to points
        let xPosRelative = (xPrediction * 10) + Double(deviceCameraToScreenXmm)
        // Invert y axis
        let yPosRelative = (yPrediction * 10 * -1) + Double(deviceCameraToScreenYmm)
        
        let screenX = xPosRelative * pointsPerMmX
        let screenY = yPosRelative * pointsPerMmY
        
        return (screenX, screenY)
    }
    
    static func cropParts(originalImage: CGImage, partRect: CGRect, horizontalSpacing hPadding:CGFloat, verticalSpacing vPadding:CGFloat)->CGImage?{
        let partsWidth =  partRect.width
        let partsHeight = partRect.height
        let gRect = CGRect(x: partRect.origin.x - (partsWidth * hPadding), y: partRect.origin.y - (partsHeight * vPadding), width: partsWidth + (partsWidth * hPadding * 2), height: partsHeight + (partsHeight * vPadding * 2))
       return originalImage.cropping(to: gRect)
    }
    
    static func cropParts(originalImage: CGImage, partsPoints points:[CGPoint],horizontalSpacing hPadding:CGFloat, verticalSpacing vPadding:CGFloat)->CGImage?{
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
           return originalImage.cropping(to: gRect)
        } else {
            return nil
        }
    }
    
    static func cropParts244(originalImage: CGImage, partsPoints points:[CGPoint],horizontalSpacing hPadding:CGFloat, verticalSpacing vPadding:CGFloat)->CGImage?{
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
            let originX = Minx.x
            let originY = Miny.y
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
            let gRect = CGRect(x: originX + xOffset, y: originY + yOffset, width: 223, height: 223)
           return originalImage.cropping(to: gRect)
        } else {
            return nil
        }
    }
    
    // Landmark coord points are definitely normalized to the bounding box they are within.
    static func convertCGPointToImageCoords(point: CGPoint, boundingBox: CGRect) -> CGPoint {
        let xValue = point.x * boundingBox.width + boundingBox.origin.x
        let yValue = (1-point.y) * boundingBox.height + boundingBox.origin.y
        return CGPoint(x: xValue, y: yValue)
    }
    
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
