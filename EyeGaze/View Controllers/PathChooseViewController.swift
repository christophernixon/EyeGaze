//
//  PathChooseViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 27/01/2022.
//

import Vision
import UIKit
import CoreData

class PathChooseViewController: UIViewController {
    private var iTrackerModel: iTracker_v2?
    var container: NSPersistentContainer!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.debugViewSegue,
           let destination = segue.destination as? DebugViewController {
            destination.configure(with: self.iTrackerModel!)
        } else if segue.identifier == Constants.staticTestViewSegue,
                  let destination = segue.destination as? StaticTestViewController {
            destination.configure(with: self.iTrackerModel!)
        } else if segue.identifier == Constants.calibrationViewSegue,
                  let destination = segue.destination as? BeginCalibrationViewController {
            destination.configure(with: self.iTrackerModel!)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        guard container != nil else {
//            fatalError("This view needs a persistent container.")
//        }
        do {
            self.iTrackerModel = try iTracker_v2(configuration: MLModelConfiguration())
        } catch {
            fatalError("Error while initialising iTracker model")
        }
    }
    
}
