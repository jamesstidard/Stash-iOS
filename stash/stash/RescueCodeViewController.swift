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
    }
    

    @IBAction func doneButtonPressed(sender: AnyObject) {
        var error: NSError?
        self.identity?.managedObjectContext?.saveUpParentHierarchyAndWait(&error)
        dismissViewControllerAnimated(true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
