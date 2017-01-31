//
//  RescueCodeViewController.swift
//  stash
//
//  Created by James Stidard on 24/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit

class RescueCodeViewController: UIViewController, IdentityHolder {
    
    static let SegueID = "rescueCodeViewControllerSegue"
    
    @IBOutlet weak var rescueCodeLabel: UILabel!
    
    var identity: Identity?
    var rescueCode: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.rescueCodeLabel.text = self.rescueCode
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        var error: NSError?
        self.identity?.managedObjectContext?.saveUpParentHierarchyAndWait(&error)
        dismiss(animated: true, completion: nil)
    }
}
