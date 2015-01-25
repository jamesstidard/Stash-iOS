//
//  AuthenticationViewController.swift
//  stash
//
//  Created by James Stidard on 24/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import CoreData

class AuthenticationViewController: UIViewController {
    
    let stash = Stash.sharedInstance
    var identitiesSelector: IdentitySelectorViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func observeValueForKeyPath(keyPath: String,
        ofObject object: AnyObject,
        change: [NSObject : AnyObject],
        context: UnsafeMutablePointer<Void>)
    {
        if keyPath == StashPropertyContextKey {
            identitiesSelector?.context = stash.context
            stash.removeObserver(self, forKeyPath: StashPropertyContextKey)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let vc = segue.destinationViewController as? IdentitySelectorViewController {
            identitiesSelector = vc
            
            if stash.context == nil {
                // Context has yet to be initialised after app start up. watch it.
                stash.addObserver(self, forKeyPath: StashPropertyContextKey, options: .New, context: nil)
            } else {
                identitiesSelector?.context = stash.context
            }
        }
    }
    
    
}
