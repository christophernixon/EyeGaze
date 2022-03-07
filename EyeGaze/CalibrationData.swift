//
//  CalibrationData.swift
//  EyeGaze
//
//  Created by Chris Nixon on 05/03/2022.
//

import Foundation
import UIKit
import CodableCSV

class CalibrationData {
    
    // Data stores
    var averagedGazePredictions: [CGPoint] = []// Average gaze prediction in screen coords, one for each calibration point shown.
    var pointDistances: [CGFloat] = []// Distances between the averagedGazePrediction point and each relevant calibration point in CM.
    var cornerGazePredictions: [String] = []
    var dotError: Double = 0.0
    var xRange: Double = 0.0
    var yRange: Double = 0.0
    var xRangeGroundTruth: Double = 0.0
    var yRangeGroundTruth: Double = 0.0
    var meanXDeviation: Double = 0.0
    var meanYDeviation: Double = 0.0
    var allGazePredictions: [(Int, Double, Double, Double)]
    
    // Data stores for writing to file
    var averagedGazePredictionsStrings: [String] = []
    var pointDistancesStrings: [String] = []
    var allGazePredictionsStrings: [String] = []
    
    init(averagedGazepredictions: [CGPoint], pointDistances: [CGFloat], cornerGazePredictions: [String], dotError: Double, xRange: Double, yRange: Double, xRangeGroundTruth: Double, yRangeGrountTruth: Double, meanXDeviation: Double, meanYDeviation: Double, allGazePredictions: [(Int, Double, Double, Double)]) {
        self.averagedGazePredictions = averagedGazepredictions
        self.pointDistances = pointDistances
        self.cornerGazePredictions = cornerGazePredictions
        self.dotError = dotError
        self.xRange = xRange
        self.yRange = yRange
        self.xRangeGroundTruth = xRangeGroundTruth
        self.yRangeGroundTruth = yRangeGrountTruth
        self.meanXDeviation = meanXDeviation
        self.meanYDeviation = meanYDeviation
        self.allGazePredictions = allGazePredictions
        formatDataStores()
    }
    
    func formatDataStores() {
        for prediction in self.averagedGazePredictions {
            self.averagedGazePredictionsStrings.append(NSCoder.string(for: prediction))
        }
        for pd in self.pointDistances {
            self.pointDistancesStrings.append(pd.description)
        }
        self.allGazePredictionsStrings = self.allGazePredictions.map{ "\($0.0),\($0.1),\($0.2),\($0.3)" }
    }
    
    func writeCalibrationsToFile(toDocumentNamed documentName: String, forGazeImplementation gazeImplementation: GazeDetectionImplementation) {
        do {
            let manager = FileManager.default
            let rootFolderURL = try manager.url(
                for: .documentDirectory,
                   in: .userDomainMask,
                   appropriateFor: nil,
                   create: false
            )
            let nestedFolderURL = rootFolderURL.appendingPathComponent("EyeGazeFiles")
            let fileURL = nestedFolderURL.appendingPathComponent(documentName)
            var writer: CSVWriter
            if !manager.fileExists(atPath: nestedFolderURL.relativePath) {
                try manager.createDirectory(
                    at: nestedFolderURL,
                    withIntermediateDirectories: false,
                    attributes: nil
                )
                writer = try CSVWriter(fileURL: fileURL, append: false)
            } else {
                writer = try CSVWriter(fileURL: fileURL, append: true)
            }
            
            
            if gazeImplementation == .iTracker {
                try writeFieldsiTracker(writer: writer)
            } else {
                try writeFieldsSeeSo(writer: writer)
            }
        
//                try data.write(to: fileURL)
//            let fileIOController = FileIOController()
//            var dict4 = [String:[[CGPoint]]]()
//            dict4["averagedGazePredictions"] = [self.averagedGazePredictions]
//            //            try fileIOController.write(self.averagedGazePredictions, toDocumentNamed: "calibrationData.csv")
//            try fileIOController.write(self.averagedGazePredictions, toDocumentNamed: "averagedGazePredictions.csv")
//            try fileIOController.write(self.cornerGazePredictions, toDocumentNamed: "cornerGazePredictions.csv")
        } catch let error {
            print("File writing error: \(error)")
        }
    }
    
    func writeFieldsiTracker(writer: CSVWriter) throws {
        
        try writer.write(field: "allGazePredictionsiTracker")
        try writer.write(row: self.allGazePredictionsStrings)
        
        try writer.write(field: "averagedGazePredictionsiTracker:")
        try writer.write(row: self.averagedGazePredictionsStrings)
        
        try writer.write(field: "pointDistancesiTracker:")
        try writer.write(row: self.pointDistancesStrings)
        
        try writer.write(field: "cornerPredictionsiTracker")
        try writer.write(row: self.cornerGazePredictions)
        
        try writer.write(field: "dotErroriTracker")
        try writer.write(field: self.dotError.description)
        try writer.endRow()
        
        try writer.write(field: "xRangeiTracker")
        try writer.write(field: self.xRange.description)
        try writer.endRow()
        
        try writer.write(field: "yRangeiTracker")
        try writer.write(field: self.yRange.description)
        try writer.endRow()
        
        try writer.write(field: "xRangeGroundTruthiTracker")
        try writer.write(field: self.xRangeGroundTruth.description)
        try writer.endRow()
        
        try writer.write(field: "yRangeGroundTruthiTracker")
        try writer.write(field: self.yRangeGroundTruth.description)
        try writer.endRow()
        
        try writer.write(field: "meanXDeviationiTracker")
        try writer.write(field: self.meanXDeviation.description)
        try writer.endRow()
        
        try writer.write(field: "meanYDeviationiTracker")
        try writer.write(field: self.meanYDeviation.description)
        try writer.endRow()
        
        try writer.endEncoding()
    }
    
    func writeFieldsSeeSo(writer: CSVWriter) throws {
        
        try writer.write(field: "allGazePredictionsSeeSo")
        try writer.write(row: self.allGazePredictionsStrings)
        
        try writer.write(field: "averagedGazePredictionsSeeSo:")
        try writer.write(row: self.averagedGazePredictionsStrings)
        
        try writer.write(field: "pointDistancesSeeSo:")
        try writer.write(row: self.pointDistancesStrings)
        
        try writer.write(field: "cornerPredictionsSeeSo")
        try writer.write(row: self.cornerGazePredictions)
        
        try writer.write(field: "dotErrorSeeSo")
        try writer.write(field: self.dotError.description)
        try writer.endRow()
        
        try writer.write(field: "xRangeSeeSo")
        try writer.write(field: self.xRange.description)
        try writer.endRow()
        
        try writer.write(field: "yRangeSeeSo")
        try writer.write(field: self.yRange.description)
        try writer.endRow()
        
        try writer.write(field: "xRangeGroundTruthSeeSo")
        try writer.write(field: self.xRangeGroundTruth.description)
        try writer.endRow()
        
        try writer.write(field: "yRangeGroundTruthSeeSo")
        try writer.write(field: self.yRangeGroundTruth.description)
        try writer.endRow()
        
        try writer.write(field: "meanXDeviationSeeSo")
        try writer.write(field: self.meanXDeviation.description)
        try writer.endRow()
        
        try writer.write(field: "meanYDeviationSeeSo")
        try writer.write(field: self.meanYDeviation.description)
        try writer.endRow()
        
        try writer.endEncoding()
    }
}
