//
//  PredictionUtilities.swift
//  EyeGaze
//
//  Created by Chris Nixon on 12/01/2022.
//

import UIKit
import CoreML
import CodableCSV

class PredictionUtilities {
    
    // If prediction is outside screen, but within 2cm of screen, prediction is clamped to screen bounds
    static func boundPredictionToScreen(prediction: (x: Double, y: Double)) -> (Double, Double) {
        let pointsPerMmX: Double = Double(Constants.iPadScreenWidthPoints)/Double(Constants.iPadScreenWidthMm)
        let pointsPerMmY: Double = Double(Constants.iPadScreenHeightPoints)/Double(Constants.iPadScreenHeightMm)
        // Amount of points in 2cm
        let xBufferPoints = pointsPerMmX * 20
        let yBufferPoints = pointsPerMmY * 20
        
        let bufferRectOriginX = 0 - xBufferPoints
        let bufferRectOriginY = 0 - yBufferPoints
        let bufferRectWidth = (Double(Constants.iPadScreenWidthPoints) + xBufferPoints) - bufferRectOriginX
        let bufferRectHeight = (Double(Constants.iPadScreenHeightPoints) + yBufferPoints) - bufferRectOriginY
        
        // A rect surrounding the screen, 2cm larger
        let bufferRect = CGRect(x: bufferRectOriginX, y: bufferRectOriginY, width: bufferRectWidth, height: bufferRectHeight)
        let screenRect = CGRect(x: 0, y: 0, width: Constants.iPadScreenWidthPoints, height: Constants.iPadScreenHeightPoints)
        
        let predPoint = CGPoint(x: prediction.x, y: prediction.y)
        var returnPoint = predPoint
        if (!screenRect.contains(predPoint) && bufferRect.contains(predPoint)) {
            if predPoint.x < 0 {
                returnPoint.x = 0
            } else if predPoint.x > Double(Constants.iPadScreenWidthPoints) {
                returnPoint.x = Double(Constants.iPadScreenWidthPoints)
            }
            if predPoint.y < 0 {
                returnPoint.y = 0
            } else if predPoint.y > Double(Constants.iPadScreenHeightPoints){
                returnPoint.y = Double(Constants.iPadScreenHeightPoints)
            }
        }
        return (returnPoint.x, returnPoint.y)
    }
    
    static func pointsToCMX(xValue: Double) -> Double {
        // iPad Pro 11" dimensions according to https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/
        let deviceScreenWidthPoints: Double = 834
        let deviceScreenWidthmm: Double = 160
        let pointsPerMmX: Double = deviceScreenWidthPoints/deviceScreenWidthmm
        return (xValue / pointsPerMmX) / 10
    }
    
    static func pointsToCMY(yValue: Double) -> Double {
        // iPad Pro 11" dimensions according to https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/
        let deviceScreenHeightPoints: Double = 1194
        let deviceScreenHeightmm: Double = 229
        let pointsPerMmY: Double = deviceScreenHeightPoints/deviceScreenHeightmm
        return (yValue / pointsPerMmY) / 10
    }
    
    static func avgArray(array: [CGFloat]) -> CGFloat {
        let sumArray: CGFloat = array.reduce(0, +)
        return sumArray / CGFloat(array.count)
    }
    
    static func euclideanDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        var distance = sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2))
        return distance
    }
    
    static func cgPointFromDoubleTuple(doubleTuple: (xValue: Double, yValue: Double)) -> CGPoint {
        return CGPoint(x: doubleTuple.xValue, y: doubleTuple.yValue)
    }
    
    static func averagePoint(pointList: [(Double, Double)]) -> (Double, Double) {
        var sumX: Double = 0
        var sumY: Double = 0
        for (x, y) in pointList {
            sumX += x
            sumY += y
        }
        let averageX = sumX/Double(pointList.count)
        let averageY = sumY/Double(pointList.count)
        return (averageX, averageY)
    }
    
    static func averageCGPoint(pointList: [(Double, Double)]) -> CGPoint {
        let (xValue, yValue) = Self.averagePoint(pointList: pointList)
        return CGPoint(x: xValue, y: yValue)
    }
    
    // Returns points from point list with maximum X value
    static func maxXPoint(pointList: [(xValue: Double, yValue: Double)]) -> (Double, Double)? {
        if pointList.isEmpty {
            return nil
        }
        var maxPoint: (xValue: Double, yValue: Double) = pointList[0]
        for point in pointList {
            if point.xValue > maxPoint.xValue {
                maxPoint = point
            }
        }
        return maxPoint
    }
    
    static func maxXPoint(pointList: [CGPoint]) -> (Double, Double)? {
        if pointList.isEmpty {
            return nil
        }
        var maxPoint: CGPoint = pointList[0]
        for point in pointList {
            if point.x > maxPoint.x {
                maxPoint = point
            }
        }
        return (Double(maxPoint.x), Double(maxPoint.y))
    }
    
    // Returns points from point list with maximum Y value
    static func maxYPoint(pointList: [(xValue: Double, yValue: Double)]) -> (Double, Double)? {
        if pointList.isEmpty {
            return nil
        }
        var maxPoint: (xValue: Double, yValue: Double) = pointList[0]
        for point in pointList {
            if point.yValue > maxPoint.yValue {
                maxPoint = point
            }
        }
        return maxPoint
    }
    
    static func maxYPoint(pointList: [CGPoint]) -> (Double, Double)? {
        if pointList.isEmpty {
            return nil
        }
        var maxPoint: CGPoint = pointList[0]
        for point in pointList {
            if point.y > maxPoint.y {
                maxPoint = point
            }
        }
        return (Double(maxPoint.x), Double(maxPoint.y))
    }
    
    // Returns points from point list with minimum X value
    static func minXPoint(pointList: [(xValue: Double, yValue: Double)]) -> (Double, Double)? {
        if pointList.isEmpty {
            return nil
        }
        var maxPoint: (xValue: Double, yValue: Double) = pointList[0]
        for point in pointList {
            if point.xValue < maxPoint.xValue {
                maxPoint = point
            }
        }
        return maxPoint
    }
    
    static func minXPoint(pointList: [CGPoint]) -> (Double, Double)? {
        if pointList.isEmpty {
            return nil
        }
        var minPoint: CGPoint = pointList[0]
        for point in pointList {
            if point.x < minPoint.x {
                minPoint = point
            }
        }
        return (Double(minPoint.x), Double(minPoint.y))
    }
    
    // Returns points from point list with minimum Y value
    static func minYPoint(pointList: [(xValue: Double, yValue: Double)]) -> (Double, Double)? {
        if pointList.isEmpty {
            return nil
        }
        var maxPoint: (xValue: Double, yValue: Double) = pointList[0]
        for point in pointList {
            if point.yValue < maxPoint.yValue {
                maxPoint = point
            }
        }
        return maxPoint
    }
    
    static func minYPoint(pointList: [CGPoint]) -> (Double, Double)? {
        if pointList.isEmpty {
            return nil
        }
        var minPoint: CGPoint = pointList[0]
        for point in pointList {
            if point.y < minPoint.y {
                minPoint = point
            }
        }
        return (Double(minPoint.x), Double(minPoint.y))
    }
    
    static func screenToPredictionCoordsCG(screenPoint: CGPoint, orientation: CGImagePropertyOrientation) -> CGPoint {
        let (x,y) = screenToPredictionCoords(screenPoint: screenPoint, orientation: orientation)
        return CGPoint(x: x, y: y)
    }
    
    static func screenToPredictionCoords(screenPoint: CGPoint, orientation: CGImagePropertyOrientation) -> (xPrediction: Double, yPrediction: Double) {
        return screenToPredictionCoords(xScreen: screenPoint.x, yScreen: screenPoint.y, orientation: orientation)
    }
    
    static func screenToPredictionCoords(screenPoints: [CGPoint], orientation: CGImagePropertyOrientation) -> [(Double, Double)] {
        var predictionCoords = [(Double, Double)] (repeating: (0.0,0.0), count: screenPoints.count)
        for i in 0..<screenPoints.count {
            predictionCoords[i] = screenToPredictionCoords(xScreen: screenPoints[i].x, yScreen: screenPoints[i].y, orientation: orientation)
        }
        return predictionCoords
    }
    
    static func screenToPredictionCoords(xScreen: Double, yScreen: Double, orientation: CGImagePropertyOrientation) -> (xPrediction: Double, yPrediction: Double) {
        // Distance from camera to top-left corner of screen
        let deviceCameraToScreenXmm: Double = 80
        let deviceCameraToScreenYmm: Double = 5
        // iPad Pro 11" dimensions according to https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/
        let deviceScreenWidthPoints: Double = 834
        let deviceScreenHeightPoints: Double = 1194
        
        let deviceScreenWidthmm: Double = 160
        let deviceScreenHeightmm: Double = 229
        
        let pointsPerMmX: Double = deviceScreenWidthPoints/deviceScreenWidthmm
        let pointsPerMmY: Double = deviceScreenHeightPoints/deviceScreenHeightmm
        
        // Calculate x and y relative to upper left of screen in mm
        let xPosRelative: Double = xScreen / pointsPerMmX
        let yPosRelative: Double = yScreen / pointsPerMmY
        
        // Convert x and y so they are relative to camera position and in cm
        let xPrediction: Double = (xPosRelative - deviceCameraToScreenXmm) / 10
        // invert y axis
        let yPrediction: Double = ((yPosRelative * -1) - deviceCameraToScreenYmm) / 10
        
        return (xPrediction, yPrediction)
    }
    
    static func scalePrediction(prediction: (x: Double, y: Double), xScaling: Double, yScaling: Double, xTranslation: Double, yTranslation: Double) -> (xScreen: Double, yScreen: Double) {
        let deviceScreenWidthPoints: Double = 834
        let deviceScreenHeightPoints: Double = 1194
        
        let deviceScreenWidthmm: Double = 160
        let deviceScreenHeightmm: Double = 229
        
        let pointsPerMmX: Double = deviceScreenWidthPoints/deviceScreenWidthmm
        let pointsPerMmY: Double = deviceScreenHeightPoints/deviceScreenHeightmm
        
        let xTransPoints = xTranslation
        let yTransPoints = yTranslation
        return (prediction.x*xScaling + xTransPoints, prediction.y*yScaling + yTransPoints)
    }
    
    static func predictionToScreenCoords(xPrediction: Double, yPrediction: Double, orientation: CGImagePropertyOrientation, xScaling: Double, yScaling: Double) -> (xScreen: Double, yScreen: Double) {
        let (x,y) = predictionToScreenCoords(xPrediction: xPrediction, yPrediction: yPrediction, orientation: orientation)
        return (x*xScaling, y*yScaling)
    }
    
    static func predictionToScreenCoords(xPrediction: Double, yPrediction: Double, orientation: CGImagePropertyOrientation) -> (xScreen: Double, yScreen: Double) {
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
        
        let xScreen = xPosRelative * pointsPerMmX
        let yScreen = yPosRelative * pointsPerMmY
        
        return (xScreen, yScreen)
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
            var heightPadding = vPadding
            //            if partsHeight < 18 {
            ////                heightPadding += 2.5
            ////                print("height padding increased")
            //            }
            let originX = Minx.x
            let originY = Miny.y
            let gRect = CGRect(x: originX - (partsWidth * hPadding), y: originY - (partsHeight * heightPadding), width: partsWidth + (partsWidth * hPadding * 2), height: partsHeight + (partsHeight * heightPadding * 2))
            
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
        
        //        print("Original width: \(detectedFaceRect.width), Original height: \(detectedFaceRect.height)")
        //        print("xLow: \(xLow), yLow: \(yLow), xHigh: \(xHigh), yHigh: \(yHigh)")
        
        for x in xLow...xHigh {
            for y in yLow...yHigh {
                facegrid[y][gridW-1-x] = 1
            }
        }
        
        //        Self.printFaceGrid(facegrid: facegrid, gridW: gridW, gridH: gridH)
        
        //        let facegridTransposed = facegrid.transposed()
        //        let facegridFlattened2 = facegridTransposed.reduce([], +)
        //        let facegridFlattened2 = facegrid.flatMap{ $0 }
        
        let facegridFlattened = facegrid.reduce([], +)
        //        print("FaceGrid flattened")
        //        print(facegridFlattened)
        //        print("FaceGrid flattened2")
        //        print(facegridFlattened2)
        
        let shape = [625, 1, 1] as [NSNumber]
        guard let doubleMultiarray = try? MLMultiArray(shape: shape, dataType: .double) else {
            fatalError("Couldn't initialise mlmultiarry from facegrid")
        }
        for (i, element) in facegridFlattened.enumerated() {
            let key = [i, 0, 0] as [NSNumber]
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
    
    static func printFaceGrid(facegrid: [[Double]], gridW: Int, gridH: Int) {
        for x in 0...gridW-1 {
            for y in 0...gridH-1 {
                if facegrid[x][y] == 0.0 {
                    print(" 0", terminator: "")
                } else {
                    print(" 1", terminator: "")
                }
            }
            print("")
        }
        print("")
    }
}

struct FileIOController {
    var manager = FileManager.default
    
    func write<T: Encodable>(
        _ object: T,
        toDocumentNamed documentName: String,
        encodedUsing encoder: CSVEncoder = .init()
    ) throws {
        let rootFolderURL = try manager.url(
            for: .documentDirectory,
               in: .userDomainMask,
               appropriateFor: nil,
               create: false
        )
        
        let nestedFolderURL = rootFolderURL.appendingPathComponent("EyeGazeFiles")
        let fileURL = nestedFolderURL.appendingPathComponent(documentName)
        let data = try encoder.encode(object)
        
        if !manager.fileExists(atPath: nestedFolderURL.relativePath) {
            try manager.createDirectory(
                at: nestedFolderURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
            try data.write(to: fileURL)
        } else {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
        
    }
}
