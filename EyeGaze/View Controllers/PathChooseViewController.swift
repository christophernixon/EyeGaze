//
//  PathChooseViewController.swift
//  EyeGaze
//
//  Created by Chris Nixon on 27/01/2022.
//

import Vision
import UIKit

class PathChooseViewController: UIViewController {
    static let debugViewSegue = "showDebugViewSegue"
    static let staticTestViewSegue = "showStaticTestViewSegue"
    private var iTrackerModel: iTracker_v2?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.debugViewSegue,
           let destination = segue.destination as? DebugViewController {
            destination.configure(with: self.iTrackerModel!)
        } else if segue.identifier == Self.staticTestViewSegue,
                  let destination = segue.destination as? StaticTestViewController {
            destination.configure(with: self.iTrackerModel!)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            self.iTrackerModel = try iTracker_v2(configuration: MLModelConfiguration())
        } catch {
            fatalError("Error while initialising iTracker model")
        }
    }
    
}
