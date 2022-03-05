//
//  Constants.swift
//  EyeGaze
//
//  Created by Chris Nixon on 18/02/2022.
//

import Foundation

class Constants {
    public static let iPadScreenHeightPoints = 1194
    public static let iPadScreenWidthPoints = 834
    
    // Segues
    public static let showPDFSegue = "showPDFSegue"
    public static let showPDFiTrackerSegue = "showPDFiTrackerSegue"
    public static let showAnimatedPDFSegue = "showAnimatedPDFSegue"
    public static let showAnimatedPDFiTrackerSegue = "showAnimatedPDFiTrackerSegue"
    public static let showDoubleAnimatedPDFSegue = "showDoubleAnimatedPDFSegue"
    public static let liveFeedViewSegue = "showLiveFeedSegue"
    public static let staticViewSegue = "showStaticViewSegue"
    public static let staticTestViewSegue = "showStaticTestViewSegue"
    public static let debugViewSegue = "showDebugViewSegue"
    public static let calibrationViewSegue = "showCalibrationViewSegue"
    public static let firstCalibrationSegue = "showFirstCalibrationSegue"
    public static let secondCalibrationSegue = "showSecondCalibrationSegue"
    public static let secondCalibrationDescriptionSegue = "showSecondCalibrationDescriptionSegue"
    public static let calibrationDescriptionModalSegue = "showCalibrationDescriptionModalSegue"
    public static let finishCalibrationSegue = "finishCalibrationSegue"
    
    // User default keys
    public static let cornerAnchorsKeyiTracker = "cornerAnchorsitracker"
    public static let cornerAnchorsKeySeeSo = "cornerAnchorsSeeSo"
    
    // Window size for rolling average of gaze estimations
    public static let rollingAverageWindowSize: Int = 15
}
