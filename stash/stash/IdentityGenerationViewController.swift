//
//  IdentityGenerationViewController.swift
//  stash
//
//  Created by James Stidard on 24/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import CoreData

let IdentityCreationSegueId = "IdentityCreationSegue"

class IdentityGenerationViewController: UIViewController, ContextDriven {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var context: NSManagedObjectContext?
    var entropyMachine = EntropyMachine()
    lazy var harvesters: [EntropyHarvester]         = [self.gyroHarvester, self.accelHarvester]
    lazy var gyroHarvester: GyroHarvester           = GyroHarvester(machine: self.entropyMachine)
    lazy var accelHarvester: AccelerometerHarvester = AccelerometerHarvester(machine: self.entropyMachine)
    var identityBundle: (identity: Identity, rescueCode: String)?
    
    private lazy var queue: NSOperationQueue = {
        var newQueue              = NSOperationQueue()
        newQueue.name             = "Identity Creation Queue"
        newQueue.qualityOfService = .Background
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.startHarvesting()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func startHarvesting() {
        self.activityIndicator.startAnimating()
        self.entropyMachine.start()
        self.harvesters.map({$0.start()}) // start harvesters gathering entropy for the machine
    }
    
    private func stopHarvesting() -> NSData? {
        self.activityIndicator.stopAnimating()
        self.harvesters.map({$0.stop()})
        return self.entropyMachine.stop()
    }
    
    @IBAction func continueButtonPressed(sender: UIButton) {
        sender.enabled = false
        
        // Stop the harvester and get the seed
        if var seed = self.stopHarvesting() {
            
            // create a child context as making a identity can take a while
            let backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType, parentContext: self.context)
            
            let name     = nameTextField.text as String
            var password = passwordTextField.text as String
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                if let result = Identity.createIdentity(name, password: &password, seed: &seed, context: backgroundContext)
                {
                    backgroundContext.save(nil)
                    
                    dispatch_sync(dispatch_get_main_queue(), {
                        if let identity = self.context?.objectWithID(result.identity.objectID) as? Identity
                        {
                            self.identityBundle = (identity, result.rescueCode)
                            self.performSegueWithIdentifier(RescueCodeSegueId, sender: nil)
                            
                            sender.enabled = true
                        }
                    })
                }
            })
            
        }
    }
    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        if let identity = identityBundle?.identity {
            context?.deleteObject(identity)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let
            destinationVC = segue.destinationViewController as? RescueCodeViewController,
            identity      = self.identityBundle?.identity,
            rescueCode    = self.identityBundle?.rescueCode
        {
            destinationVC.identity   = identity
            destinationVC.rescueCode = rescueCode
        }
    }
    

}
