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
    SqrlLinkRepository,
    IdentitySelectorViewControllerDelegate,
    SQRLSessionDelegate,
    NSURLSessionTaskDelegate
{
    @IBOutlet weak var selectorContainerBottomConstraint: NSLayoutConstraint!
    
    lazy var session: NSURLSession = NSURLSession(stashSessionWithdelegate: self)
    lazy var notificationCenter    = NSNotificationCenter.defaultCenter()
    
    lazy var stash: Stash                       = Stash.sharedInstance
    lazy var context: NSManagedObjectContext?   = self.stash.context
    lazy var contextContracts :[ContextDriven]? = [ContextDriven]()
    // If we segue to anything that needs a context while before it's been initilised,
    // we add them to this list and pass them the context once we have it.
    
    weak var scannerVC: QRScannerViewController?
    weak var selectorVC: IdentitySelectorViewController?
    
    var sqrlLink: NSURL? = nil {
        didSet { self.selectorVC?.sqrlLink = sqrlLink }
    }
    
    lazy var progressHud: MBProgressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If the moc has yet to be initialised, start listening for it
        if stash.context == nil {
            stash.addObserver(self, forKeyPath: StashPropertyContextKey, options: .New, context: nil)
        }
        
        // listen out for the keyboard so we can move the identity selector view up/down
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

    
    // MARK: - Identity Selector Delegate
    func identitySelectorViewController(
        identitySelectorViewController: IdentitySelectorViewController,
        didSelectIdentity identity: Identity,
        withDecryptedMasterKey masterKey: NSData)
    {
        self.progressHud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        if let
            sqrlLink  = self.sqrlLink,
            request   = NSMutableURLRequest(queryForSqrlLink: sqrlLink, masterKey: masterKey)
        {
            let task = self.session.sqrlDataTaskWithRequest(
                request,
                masterKey: masterKey,
                lockKey: identity.lockKey,
                delegate: self)
            task.resume()
            self.progressHud.labelText = "Quering Server"
        }
        else {
            self.progressHud.hide(animated: true, labelText: "Couldn't Understand SQRL-Link", success: false)
        }
    }
    
    
    // MARK: - SQRL Exchange
    func SQRLSession(session: NSURLSession, shouldLoginAccountForServer serverName: String, proceed: Bool -> ()) {
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { _ in
            self.progressHud.hide(animated: true, labelText: "Canceled", success: false)
            proceed(false)
        }
        let login = UIAlertAction(title: "Login", style: .Default) { _ in
            self.progressHud.labelText = "Requesting Login"
            proceed(true)
        }
        self.showAlert(
            serverName,
            message: "Would you like to log into your \(serverName) account?",
            actions: cancel, login)
    }
    
    func SQRLSession(session: NSURLSession, shouldCreateAccountForServer serverName: String, proceed: Bool -> ()) {
        // Prompt user for to confirm and on confirmation send new request
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { _ in
            self.progressHud.hide(animated: true, labelText: "Canceled", success: false)
            proceed(false)
        }
        let create = UIAlertAction(title: "Create", style: .Default) { _ in
            self.progressHud.labelText = "Requesting New Account"
            proceed(true)
        }
        self.showAlert(
            serverName,
            message: "Looks like \(serverName) doesn't recognise you.\n\nDid you want to create an account with \(serverName)?",
            actions: cancel, create)
    }
    
    func SQRLSession(session: NSURLSession, succesfullyCompleted success: Bool)
    {
        let labelText = success ? "Complete" : "Failed"
        self.progressHud.hide(animated:true, labelText: labelText, success: success)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.scannerVC?.sqrlLink = nil
        }
    }
    
    func showAlert(title: String, message: String, actions: UIAlertAction...)
    {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .Alert)
        
        actions.map { alert.addAction($0) }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - NSURLSession
    func URLSession(
        session: NSURLSession,
        task: NSURLSessionTask,
        willPerformHTTPRedirection response: NSHTTPURLResponse,
        newRequest request: NSURLRequest,
        completionHandler: (NSURLRequest!) -> Void)
    {
        // SQRL shouldn't follow to any redirects
        completionHandler(nil)
    }
    
    
    // MARK: - Context Watching
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
    func qrScannerViewController(scannerVC: QRScannerViewController, didFindSqrlLink sqrlLink: NSURL?) {
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
            vc.delegate    = self
            self.scannerVC = vc
        }
        
        // if is the identity selector view controller, we want to know what's selected.
        if let vc = destinationVC as? IdentitySelectorViewController {
            vc.delegate     = self
            self.selectorVC = vc
        }
    }
}
