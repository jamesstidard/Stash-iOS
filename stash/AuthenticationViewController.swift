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
    URLSessionTaskDelegate
{
    // MARK: -
    // MARK: Public
    @IBOutlet weak var identityCollectionViewBottom: NSLayoutConstraint!
    @IBOutlet weak var identityCollectionViewHeight: NSLayoutConstraint!
    
    lazy var context: NSManagedObjectContext? = self.stash.context
    
    
    // MARK: Private
    fileprivate lazy var stash: Stash = Stash.sharedInstance
    fileprivate lazy var contextContracts :[ContextDriven]? = [ContextDriven]()
    // If we segue to anything that needs a context while before it's been initilised,
    // we add them to this list and pass them the context once we have it.
    fileprivate lazy var session: Foundation.URLSession = Foundation.URLSession(stashSessionWithdelegate: self)
    fileprivate lazy var notificationCenter    = NotificationCenter.default
    fileprivate let sqrlLinkContext: UnsafeMutableRawPointer            = nil
    
    fileprivate lazy var progressHud: MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
    fileprivate weak var scannerVC: QRScannerViewController?
    fileprivate weak var identityCollectionVC: IdentityCollectionViewController?
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If the moc has yet to be initialised, start listening for it
        if self.context == nil {
            self.stash.addObserver(self, forKeyPath: StashPropertyContextKey, options: .new, context: nil)
        }
        
        // listen out for the keyboard so we can move the identity selector view up/down
        notificationCenter.addObserver(
            self,
            selector: #selector(AuthenticationViewController.keyboardPositionChanged(_:)),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(AuthenticationViewController.keyboardPositionChanged(_:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil)
    }

    
    // MARK: - Identity Selector Delegate
    func identityCollectionViewController(
        _ identityCollectionViewController: IdentityCollectionViewController,
        didSelectIdentity identity: Identity,
        withDecryptedMasterKey masterKey: Data)
    {
        self.progressHud = MBProgressHUD.showHUDAddedTo(self.view, animated: true, labelText: "Creating Query")

        if let
            sqrlLink = self.scannerVC?.sqrlLink,
            let sqrlTask = self.session.sqrlDataTaskForSqrlLink(sqrlLink, masterKey: masterKey, lockKey: identity.lockKey, delegate: self)
        {
            sqrlTask.resume()
            self.progressHud.labelText = "Quering Server"
            return
        }
        
        self.endSQRLTransaction(success: false, message: "Couldn't Understand SQRL-Link")
    }
    
    
    // MARK: - NSURLSession
    func URLSession(
        _ session: Foundation.URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: (URLRequest!) -> Void)
    {
        // SQRL shouldn't follow to any redirects
        completionHandler(nil)
    }
    
    
    // MARK: - SQRLSession
    func SQRLSession(_ session: Foundation.URLSession, shouldLoginAccountForServer serverName: String, proceed: @escaping (Bool) -> ()) {
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.endSQRLTransaction(success: false, message: "Canceled")
            proceed(false)
        }
        let login = UIAlertAction(title: "Login", style: .default) { _ in
            self.progressHud.labelText = "Requesting Login"
            proceed(true)
        }
        UIAlertController.showAlert(
            title: serverName,
            message: "Would you like to log into your \(serverName) account?",
            viewController: self,
            actions: cancel, login)
    }
    
    func SQRLSession(_ session: Foundation.URLSession, shouldCreateAccountForServer serverName: String, proceed: @escaping (Bool) -> ()) {
        // Prompt user for to confirm and on confirmation send new request
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.endSQRLTransaction(success: false, message: "Canceled")
            proceed(false)
        }
        let create = UIAlertAction(title: "Create", style: .default) { _ in
            self.progressHud.labelText = "Requesting New Account"
            proceed(true)
        }
        UIAlertController.showAlert(
            title: serverName,
            message: "Looks like \(serverName) doesn't recognise you.\n\nDid you want to create an account with \(serverName)?",
            viewController: self,
            actions: cancel, create)
    }
    
    func SQRLSession(_ session: Foundation.URLSession, succesfullyCompleted success: Bool)
    {
        let labelText = success ? "Complete" : "Failed"
        self.endSQRLTransaction(success: success, message: labelText)
    }
    
    func endSQRLTransaction(#success: Bool, _ message: String)
    {
        self.progressHud.hide(animated:true, labelText: message, success: success)
        
        DispatchQueue.main.async {
            self.scannerVC?.sqrlLink = nil
        }
    }
    
    
    // MARK: - KVO
    override func observeValue(
        forKeyPath keyPath: String,
        of object: AnyObject,
        change: [AnyHashable: Any],
        context: UnsafeMutableRawPointer)
    {
        // If this is the context we've been waiting for, tell anyone we have contracts with and set it locally
        if keyPath == StashPropertyContextKey {
            self.context = stash.context
            
            contextContracts?.map { $0.context = self.context } // Pass everyone the belated context
            contextContracts = nil
            
            stash.removeObserver(self, forKeyPath: StashPropertyContextKey) // No longer listen
        }
        else if context == sqrlLinkContext {
            self.identityCollectionVC?.invalidate() // sqrlLink has changed - let the identity selector know
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    
    // MARK: - Keyboard Response
    func keyboardPositionChanged(_ notification: Notification)
    {
        if let
            kbInfo     = notification.userInfo,
            let curveRaw   = (kbInfo[UIKeyboardAnimationCurveUserInfoKey]? as AnyObject).intValue,
            let duration   = (kbInfo[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue,
            let startFrame = (kbInfo[UIKeyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue,
            let endFrame   = (kbInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        {
            let showing      = notification.name == NSNotification.Name.UIKeyboardWillShow
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
    @IBAction func swipeUp(_ sender: UISwipeGestureRecognizer)
    {
        // if there is a sqrl link, treat as a tap
        if
            self.scannerVC?.sqrlLink != nil,
        let
            collectionView = self.identityCollectionVC?.collectionView,
            let indexPath      = collectionView.indexPathsForVisibleItems.first as? IndexPath
        {
            self.identityCollectionVC?.collectionView(collectionView, didSelectItemAtIndexPath: indexPath)
        }
        // else segue to identity management
        else {
            self.performSegue(withIdentifier: IdentityManagementTableViewController.SegueID, sender: nil)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationVC = segue.destination 
        
        // upwrap navigation controllers
        if let
            navController = destinationVC as? UINavigationController,
            let rootVC        = navController.viewControllers[0] as? UIViewController
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
            self.scannerVC?.addObserver(self, forKeyPath: "sqrlLink", options: .new, context: sqrlLinkContext)
            self.identityCollectionVC?.dataSource = self.scannerVC
        }
        
        // if is the identity selector view controller, we want to know what's selected.
        if let vc = destinationVC as? IdentityCollectionViewController {
            self.identityCollectionVC = vc
            self.identityCollectionVC!.delegate   = self
            self.identityCollectionVC!.dataSource = self.scannerVC
        }
    }
}
