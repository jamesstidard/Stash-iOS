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
    IdentityCollecionViewControllerDelegate,
    SQRLSessionDelegate,
    NSURLSessionTaskDelegate
{
    // MARK: -
    // MARK: Public
    @IBOutlet weak var identityCollectionViewBottom: NSLayoutConstraint!
    @IBOutlet weak var identityCollectionViewHeight: NSLayoutConstraint!
    
    lazy var context: NSManagedObjectContext? = self.stash.context
    
    
    // MARK: Private
    private lazy var stash: Stash = Stash.sharedInstance
    private lazy var contextContracts :[ContextDriven]? = [ContextDriven]()
    // If we segue to anything that needs a context while before it's been initilised,
    // we add them to this list and pass them the context once we have it.
    private lazy var session: NSURLSession = NSURLSession(stashSessionWithdelegate: self)
    private lazy var notificationCenter    = NSNotificationCenter.defaultCenter()
    private let sqrlLinkContext            = UnsafeMutablePointer<()>()
    
    private lazy var progressHud: MBProgressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    private weak var scannerVC: QRScannerViewController?
    private weak var IdentityCollectionVC: IdentityCollectionViewController?
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If the moc has yet to be initialised, start listening for it
        if self.context == nil {
            self.stash.addObserver(self, forKeyPath: StashPropertyContextKey, options: .New, context: nil)
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

    
    // MARK: - Identity Selector Delegate
    func identityCollectionViewController(
        identityCollectionViewController: IdentityCollectionViewController,
        didSelectIdentity identity: Identity,
        withDecryptedMasterKey masterKey: NSData)
    {
        self.progressHud = MBProgressHUD.showHUDAddedTo(self.view, animated: true, labelText: "Creating Query")
        
        if let
            sqrlLink = self.scannerVC?.sqrlLink,
            sqrlTask = self.session.sqrlDataTaskForSqrlLink(sqrlLink, masterKey: masterKey, lockKey: identity.lockKey, delegate: self)
        {
            sqrlTask.resume()
            self.progressHud.labelText = "Quering Server"
            return
        }
        
        self.endSQRLTransaction(success: false, message: "Couldn't Understand SQRL-Link")
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
    
    
    // MARK: - SQRLSession
    func SQRLSession(session: NSURLSession, shouldLoginAccountForServer serverName: String, proceed: Bool -> ()) {
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { _ in
            self.endSQRLTransaction(success: false, message: "Canceled")
            proceed(false)
        }
        let login = UIAlertAction(title: "Login", style: .Default) { _ in
            self.progressHud.labelText = "Requesting Login"
            proceed(true)
        }
        UIAlertController.showAlert(
            title: serverName,
            message: "Would you like to log into your \(serverName) account?",
            viewController: self,
            actions: cancel, login)
    }
    
    func SQRLSession(session: NSURLSession, shouldCreateAccountForServer serverName: String, proceed: Bool -> ()) {
        // Prompt user for to confirm and on confirmation send new request
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { _ in
            self.endSQRLTransaction(success: false, message: "Canceled")
            proceed(false)
        }
        let create = UIAlertAction(title: "Create", style: .Default) { _ in
            self.progressHud.labelText = "Requesting New Account"
            proceed(true)
        }
        UIAlertController.showAlert(
            title: serverName,
            message: "Looks like \(serverName) doesn't recognise you.\n\nDid you want to create an account with \(serverName)?",
            viewController: self,
            actions: cancel, create)
    }
    
    func SQRLSession(session: NSURLSession, succesfullyCompleted success: Bool)
    {
        let labelText = success ? "Complete" : "Failed"
        self.endSQRLTransaction(success: success, message: labelText)
    }
    
    func endSQRLTransaction(#success: Bool, message: String)
    {
        self.progressHud.hide(animated:true, labelText: message, success: success)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.scannerVC?.sqrlLink = nil
        }
    }
    
    
    // MARK: - KVO
    override func observeValueForKeyPath(
        keyPath: String,
        ofObject object: AnyObject,
        change: [NSObject : AnyObject],
        context: UnsafeMutablePointer<Void>)
    {
        // If this is the context we've been waiting for, tell anyone we have contracts with and set it locally
        if keyPath == StashPropertyContextKey {
            self.context = stash.context
            
            contextContracts?.map { $0.context = self.context } // Pass everyone the belated context
            contextContracts = nil
            
            stash.removeObserver(self, forKeyPath: StashPropertyContextKey) // No longer listen
        }
        else if context == sqrlLinkContext {
            self.IdentityCollectionVC?.invalidate() // sqrlLink has changed - let the identity selector know
        }
        else {
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
            let height       = showing ? CGFloat(54) : CGFloat(110)
            
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(
                duration,
                delay: 0,
                options: UIViewAnimationOptions(UInt(curveRaw)),
                animations: {
                    self.identityCollectionViewBottom.constant += yDelta
                    self.identityCollectionViewHeight.constant  = height
                    self.view.layoutIfNeeded()
                },
                completion: nil)
        }
    }
    
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destinationVC = segue.destinationViewController as! UIViewController
        
        // upwrap navigation controllers
        if let
            navController = destinationVC as? UINavigationController,
            rootVC        = navController.viewControllers?[0] as? UIViewController
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
            self.scannerVC = vc
            self.scannerVC?.addObserver(self, forKeyPath: "sqrlLink", options: .New, context: sqrlLinkContext)
            self.IdentityCollectionVC?.dataSource = self.scannerVC
        }
        
        // if is the identity selector view controller, we want to know what's selected.
        if let vc = destinationVC as? IdentityCollectionViewController {
            self.IdentityCollectionVC = vc
            self.IdentityCollectionVC?.dataSource = self.scannerVC
        }
    }
}
