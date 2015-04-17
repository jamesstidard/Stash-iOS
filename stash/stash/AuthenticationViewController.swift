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
    SqrlLinkRepository,
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
    var identityBundle:(identity: Identity, password: String)? = nil {
        didSet { self.performLogin() }
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
    
    
    // MARK: - SQRL
    func performLogin()
    {
        if let
            identity  = self.identityBundle?.identity,
            password  = self.identityBundle?.password,
            sqrlLink  = self.sqrlLink,
            masterKey = identity.masterKey.decryptCipherTextWithPassword(password),
            request   = NSMutableURLRequest(queryForSqrlLink: sqrlLink, withMasterKey: masterKey)
        {
            let task = self.session.dataTaskWithRequest(request, completionHandler: self.handleServerResponse)
            task.resume()
        }
    }
    
    func handleServerResponse(data: NSData!, response: NSURLResponse!, error: NSError!) -> Void
    {
        if let
            message     = data.sqrlServerResponse(),
            serverName  = message[.ServersFriendlyName],
            tifRaw      = message[.TIF]?.toInt(),
            identity    = self.identityBundle?.identity,
            password    = self.identityBundle?.password,
            masterKey   = identity.masterKey.decryptCipherTextWithPassword(password),
            responseURL = response.URL
        where
            tifRaw > 0
        {
            let tif = TIF(UInt(tifRaw))
            
            // If NO current id or previous id on the server
            if tif & (.CurrentIDMatch | .PreviousIDMatch) == nil {
                self.handleCreateIdentity(
                    serverName,
                    serverURL: responseURL,
                    serverMessage: data,
                    masterKey: masterKey,
                    lockKey: identity.lockKey)
            }
            // if current id
            else if tif & .CurrentIDMatch {
                self.handleLoginIdentity(serverName, serverURL: responseURL, serverMessage: data, masterKey: masterKey)
            }
        }
    }
    
    func handleCreateIdentity(
        serverName: String,
        serverURL: NSURL,
        serverMessage: NSData,
        masterKey: NSData,
        lockKey: NSData)
    {
        if let
            serverValue = NSString(data: serverMessage, encoding: NSASCIIStringEncoding) as? String,
            request     = NSMutableURLRequest(createIdentForServerURL: serverURL, serverValue: serverValue, masterKey: masterKey, identityLockKey: lockKey)
        {
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            let create = UIAlertAction(title: "Create", style: .Default) { _ in
                let task = self.session.dataTaskWithRequest(request, completionHandler: self.handleServerResponse)
                task.resume()
            }
            self.showAlert(
                serverName,
                message: "Looks like \(serverName) doesn't recognise you. Did you want to create an account with \(serverName)?",
                actions: cancel, create)
        }
    }
    
    func handleLoginIdentity(
        serverName: String,
        serverURL: NSURL,
        serverMessage: NSData,
        masterKey: NSData)
    {
        if let
            serverValue = NSString(data: serverMessage, encoding: NSASCIIStringEncoding) as? String,
            request     = NSMutableURLRequest(loginIdentForServerURL: serverURL, serverValue: serverValue, masterKey: masterKey)
        {
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            let login = UIAlertAction(title: "Login", style: .Default) { _ in
                let task = self.session.dataTaskWithRequest(request, completionHandler: self.handleServerResponse)
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
