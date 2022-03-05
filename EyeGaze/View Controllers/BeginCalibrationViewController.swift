//
//  BeginCalibrationViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 03/03/2022.
//

import Foundation
import UIKit
import Vision

class BeginCalibrationViewController: UIViewController {
    
    @IBOutlet weak var beginCalibrationButton: UIButton!
    @IBOutlet weak var calibrationExplanationText: UITextView!
    private var iTrackerModel: iTracker_v2?
    private var hasShownFirstCalibrationView: Bool = false
    
    func configure(with iTrackerModel: iTracker_v2) {
        self.iTrackerModel = iTrackerModel
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        do {
            self.iTrackerModel = try iTracker_v2(configuration: MLModelConfiguration())
        } catch {
            fatalError("Error while initialising iTracker model")
        }
        if segue.identifier == Constants.firstCalibrationSegue,
           let destination = segue.destination as? CalibrationViewController {
                destination.configure(with: self.iTrackerModel!, usingiTrackerModel: false)
        }
    }
    
    @IBAction func beginCalibrationButtonPressed(_ sender: UIButton!) {
        self.performSegue(withIdentifier: Constants.firstCalibrationSegue, sender: self)
    }
}
