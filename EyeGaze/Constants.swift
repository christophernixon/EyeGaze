//
//  Constants.swift
//  EyeGaze
//
//  Created by Chris Nixon on 18/02/2022.
//

import Foundation
import UIKit

class Constants {
    public static let iPadScreenHeightPoints = 1194
    public static let iPadScreenWidthPoints = 834
    public static let iPadScreenHeightMm = 229
    public static let iPadScreenWidthMm = 160
    
    public static let pointsPerMmX: Double = Double(iPadScreenWidthPoints)/Double(iPadScreenWidthMm)
    public static let pointsPerMmY: Double = Double(Constants.iPadScreenHeightPoints)/Double(Constants.iPadScreenHeightMm)
    public static let iPadBottomRightCornerWithBuffer: CGPoint = CGPoint(x: Double(iPadScreenWidthPoints) + (pointsPerMmX * 10), y: Double(iPadScreenHeightPoints) + (pointsPerMmY * 10))
    
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
    public static let rollingAverageWindowSize: Int = 20
    
    public static let gazeCalibrationFrameCount: Int = 30
    
    public static let fastScrollingSpeed: CGFloat = 0.7
    public static let mediumScrollingSpeed: CGFloat = 0.35
    public static let slowScrollingSpeed: CGFloat = 0.15
    public static let defaultScrollingSpeed: CGFloat = 0.0
    public static let changeOfSpeedRate: CGFloat = 0.001
}
