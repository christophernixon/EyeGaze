//
//  SecondCalibrationDetailViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 03/03/2022.
//

import Foundation
import UIKit

class SecondCalibrationDetailViewController: UIViewController {
    
    @IBOutlet weak var continueCalibrationButton: UIButton!
    @IBOutlet weak var calibrationDescriptionText: UITextView!
    
    private var iTrackerModel: iTracker_v2?
    
    func configure(with iTrackerModel: iTracker_v2) {
        self.iTrackerModel = iTrackerModel
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.secondCalibrationSegue,
                  let destination = segue.destination as? CalibrationViewController {
            destination.configure(with: self.iTrackerModel!, usingiTrackerModel: true)
        }
    }
    
    @IBAction func continueCalibrationButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: Constants.secondCalibrationSegue, sender: self)
    }
    
}
