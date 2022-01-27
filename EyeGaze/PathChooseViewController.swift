//
//  PathChooseViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 27/01/2022.
//

import Vision
import UIKit

class PathChooseViewController: UIViewController {
    static let debugViewSegue = "showDebugViewSegue2"
    private var iTrackerModel: iTracker?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.debugViewSegue,
           let destination = segue.destination as? DebugViewController {
            destination.configure(with: self.iTrackerModel!)
          }
      }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            self.iTrackerModel = try iTracker(configuration: MLModelConfiguration())
        } catch {
            fatalError("Error while initialising iTracker model")
        }
    }
    
}
