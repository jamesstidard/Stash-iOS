//
//  AuthenticationViewController.swift
//  stash
//
//  Created by James Stidard on 24/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import CoreData

class AuthenticationViewController: UIViewController,
    ContextDriven,
    IdentityRepository,
    SqrlLinkRepository
{
    @IBOutlet weak var selectorContainerBottomConstraint: NSLayoutConstraint!
    
    let notificationCenter                      = NSNotificationCenter.defaultCenter()
    let stash                                   = Stash.sharedInstance
    lazy var context :NSManagedObjectContext?   = self.stash.context// give the context as much time as we can to initialise
    lazy var contextContracts :[ContextDriven]? = [ContextDriven]()//If we segue to anything that needs a context while before it's been initilised, we add them to this list and pass them the context once we have it.
    weak var selectorVC: IdentitySelectorViewController?
    
    var sqrlLink: NSURL? = nil
    var identityBundle:(identity: Identity, password: String)? = nil
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If the moc has yet to be initialised, start listening for it
        if stash.context == nil {
            stash.addObserver(self, forKeyPath: StashPropertyContextKey, options: .New, context: nil)
        }
        
        // listen out for the keyboard so we can move the identity selector view up
        notificationCenter.addObserver(
            self,
            selector: "keyboardPositionChanged:",
            name: UIKeyboardWillShowNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: "keyboardPositionChanged:",
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)
    {
        // If this is the context we've been waiting for, tell anyone we have contracts with and set it locally
        if keyPath == StashPropertyContextKey {
            self.context = stash.context
            
            contextContracts?.map { $0.context = self.context } // Pass everyone the belated context
            contextContracts = nil
            
            stash.removeObserver(self, forKeyPath: StashPropertyContextKey) // No longer listen
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Keyboard Response
    func keyboardPositionChanged(notification: NSNotification)
    {
        if let
            kbInfo     = notification.userInfo,
            curveRaw   = kbInfo[UIKeyboardAnimationCurveUserInfoKey]?.integerValue,
            duration   = kbInfo[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue,
            startFrame = kbInfo[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue(),
            endFrame   = kbInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue()
        {
            let showing      = notification.name == UIKeyboardWillShowNotification
            let startYOrigin = startFrame.origin.y
            let endYOrigin   = endFrame.origin.y
            let yDelta       = startYOrigin - endYOrigin
            
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(
                duration,
                delay: 0,
                options: UIViewAnimationOptions(UInt(curveRaw)),
                animations: {
                    self.selectorContainerBottomConstraint.constant += yDelta
                    self.view.layoutIfNeeded()
                },
                completion: nil)
        }
    }
    
    // MARK: - Scanner
    func qrScannerViewController(scannerVC: QRScannerViewController, didFindSqrlLink sqrlLink: NSURL?)
    {
        self.selectorVC?.sqrlLink = sqrlLink
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destinationVC = segue.destinationViewController as! UIViewController
        
        // upwrap navigation controllers
        if let
            navigationController = destinationVC as? UINavigationController,
            rootVC               = navigationController.viewControllers?[0] as? UIViewController
        {
                destinationVC = rootVC
        }
        
        // if requires a context pass it ours
        if let vc = destinationVC as? ContextDriven {
            // Pass VC the context or add them to list to be passed to once we have it
            (self.context != nil) ? vc.context = self.context : contextContracts?.append(vc)
        }
        
        // if is the identity selector view controller, we want to know what's selected.
        if let vc = destinationVC as? QRScannerViewController {
            vc.delegate     = self
        }
        
        // if is the identity selector view controller, we want to know what's selected.
        if let vc = destinationVC as? IdentitySelectorViewController {
            vc.delegate     = self
            self.selectorVC = vc
        }
    }
}
