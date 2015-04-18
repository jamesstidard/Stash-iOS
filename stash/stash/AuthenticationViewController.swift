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
    NSURLSessionTaskDelegate
{
    @IBOutlet weak var selectorContainerBottomConstraint: NSLayoutConstraint!
    
    var sessionConfig: NSURLSessionConfiguration = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPAdditionalHeaders = ["User-Agent" : "Stash/1"]
        return config
    }()
    lazy var session: NSURLSession = NSURLSession(configuration: self.sessionConfig, delegate: self, delegateQueue: nil)
    lazy var notificationCenter    = NSNotificationCenter.defaultCenter()
    
    lazy var stash: Stash                       = Stash.sharedInstance
    lazy var context: NSManagedObjectContext?   = self.stash.context
    lazy var contextContracts :[ContextDriven]? = [ContextDriven]()
    // If we segue to anything that needs a context while before it's been initilised,
    // we add them to this list and pass them the context once we have it.
    
    weak var selectorVC: IdentitySelectorViewController?
    
    var sqrlLink: NSURL? = nil {
        didSet { self.selectorVC?.sqrlLink = sqrlLink }
    }
    
    
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
        if let
            sqrlLink  = self.sqrlLink,
            request   = NSMutableURLRequest(queryForSqrlLink: sqrlLink, masterKey: masterKey)
        {
            let task = self.session.dataTaskWithRequest(request) {
                self.handleServerResponse(data: $0, response: $1, error: $2, lastCommand: .Query, masterKey: masterKey, lockKey: identity.lockKey)
            }
            task.resume()
        }
    }
    
    
     // MARK: - SQRL
    func handleServerResponse(
        #data: NSData?,
        response: NSURLResponse?,
        error: NSError?,
        lastCommand: SQRLCommand,
        masterKey: NSData,
        lockKey: NSData? = nil) -> Void
    {
        if let
            serverMessage = ServerMessage(data: data, response: response),
            tifRaw        = serverMessage.dictionary[.TIF]?.toInt(),
            serverName    = serverMessage.dictionary[.ServersFriendlyName]
        where
            tifRaw > 0
        {
            let tif = TIF(UInt(tifRaw))
            
            // If NO current id or previous id on the server AND we didn't just create
            if tif & (.CurrentIDMatch | .PreviousIDMatch) == nil && lastCommand != .Ident && lockKey != nil  {
                self.createIdentity(serverMessage: serverMessage, masterKey: masterKey, lockKey: lockKey!)
            }
                
                
            // if current id exists and we havn't just performed a login
            else if tif & .CurrentIDMatch && lastCommand != .Ident {
                self.loginIdentity(serverMessage: serverMessage, masterKey: masterKey)
            }
        }
    }
    
    func createIdentity(#serverMessage: ServerMessage, masterKey: NSData, lockKey: NSData)
    {
        if let
            serverName = serverMessage.dictionary[.ServersFriendlyName],
            request    = NSMutableURLRequest(createRequestForServerMessage: serverMessage, masterKey: masterKey, lockKey: lockKey)
        {
            // Prompt user for to confirm and on confirmation send new request
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            let create = UIAlertAction(title: "Create", style: .Default) { _ in
                let task = self.session.dataTaskWithRequest(request) {
                    self.handleServerResponse(data: $0, response: $1, error: $2, lastCommand: .Ident, masterKey: masterKey)
                }
                task.resume()
            }
            self.showAlert(
                serverName,
                message: "Looks like \(serverName) doesn't recognise you. Did you want to create an account with \(serverName)?",
                actions: cancel, create)
        }
    }
    
    func loginIdentity(#serverMessage: ServerMessage, masterKey: NSData)
    {
        if let
            serverName = serverMessage.dictionary[.ServersFriendlyName],
            request    = NSMutableURLRequest(loginRequestForServerMessage: serverMessage, masterKey: masterKey)
        {
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            let login = UIAlertAction(title: "Login", style: .Default) { _ in
                let task = self.session.dataTaskWithRequest(request) {
                    self.handleServerResponse(data: $0, response: $1, error: $2, lastCommand: .Ident, masterKey: masterKey)
                }
                task.resume()
            }
            self.showAlert(
                serverName,
                message: "Would you like to log into your \(serverName) account?",
                actions: cancel, login)
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
            vc.delegate     = self
        }
        
        // if is the identity selector view controller, we want to know what's selected.
        if let vc = destinationVC as? IdentitySelectorViewController {
            vc.delegate     = self
            self.selectorVC = vc
        }
    }
}
