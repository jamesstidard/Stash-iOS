//
//  AuthenticationViewController.swift
//  stash
//
//  Created by James Stidard on 24/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import CoreData

class AuthenticationViewController: UIViewController, ContextDriven, IdentitySelectorViewControllerDelegate {
    
    let stash = Stash.sharedInstance
    lazy var context :NSManagedObjectContext? = self.stash.context // give the context as much time as we can to initialise
    lazy var contextContracts :[ContextDriven]? = [ContextDriven]()//If we spawn anything that needs a context while before it's been initilised, we add them to this list and pass that context once it is ready.
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If the moc has yet to be initialised, start listening for it
        if stash.context == nil {
            stash.addObserver(self, forKeyPath: StashPropertyContextKey, options: .New, context: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)
    {
        if keyPath == StashPropertyContextKey {
            self.context = stash.context
            
            contextContracts?.map { $0.context = self.context } // Pass everyone the belated context
            contextContracts = nil
            
            stash.removeObserver(self, forKeyPath: StashPropertyContextKey) // No longer listen
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destinationVC = segue.destinationViewController as! UIViewController
        
        // upwrap navigation controllers
        if let navigationController = destinationVC as? UINavigationController {
            if let rootVC = navigationController.viewControllers?[0] as? UIViewController {
                destinationVC = rootVC
            }
        }
        
        // if requires a context pass it ours
        if let vc = destinationVC as? ContextDriven {
            // Pass VC the context or add them to list to be passed to once we have it
            (self.context != nil) ? vc.context = self.context : contextContracts?.append(vc)
        }
        
        if let vc = destinationVC as? IdentitySelectorViewController {
            vc.selectorDelegate = self
        }
    }
}
