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
    public static let debugViewSegue = "showDebugViewSegue"
    
    // Window size for rolling average of gaze estimations
    public static let rollingAverageWindowSize: Int = 7
}
