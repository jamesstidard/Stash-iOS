//
//  ActionViewController.swift
//  stashAction
//
//  Created by James Stidard on 19/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData

class ActionViewController: UITableViewController,
    NSFetchedResultsControllerDelegate,
    SQRLSessionDelegate,
    NSURLSessionDelegate
{
    @IBOutlet weak var imageView: UIImageView!
    
    lazy var session: NSURLSession = NSURLSession(stashSessionWithdelegate: self)
    
    let stash = Stash()
    var context: NSManagedObjectContext? = nil {
        didSet {
            self.createIdentitiesFetchedResultsController()
            self.identitiesFRC?.performFetch(nil)
            self.controllerDidChangeContent(identitiesFRC!)
        }
    }
    
    private var identitiesFRC: NSFetchedResultsController?
    
    var sqrlLink: NSURL?
    
    lazy var progressHud: MBProgressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)

    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Start trying to find that sqrlLink
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            ActionViewController.findSqrlLinkFromExtensionContext(self.extensionContext) { sqrlLink in
                dispatch_async(dispatch_get_main_queue()) {
                    self.sqrlLink = sqrlLink
                }
            }
        }
        
        // If the moc has yet to be initialised, start listening for it
        if stash.context == nil {
            stash.addObserver(self, forKeyPath: StashPropertyContextKey, options: .New, context: nil)
        }
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequestReturningItems(nil, completionHandler: nil)
    }

    class func findSqrlLinkFromExtensionContext(context: NSExtensionContext?, completion: (NSURL? -> ()))
    {
        // Bend over backwards to get a sqrl url
        for item: NSExtensionItem in context?.inputItems as! Array {
            for provider: NSItemProvider in item.attachments as! Array {
                
                if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                    provider.loadItemForTypeIdentifier(kUTTypePropertyList as String, options: nil) { (results: NSSecureCoding!, error: NSError!) in
                        
                        if let results = results as? NSDictionary where results.count > 0 {
                            if let urls = results.valueForKey(NSExtensionJavaScriptPreprocessingResultsKey as String) as? NSDictionary {
                                for url in urls.allValues as! [String] {
                                    NSOperationQueue.mainQueue().addOperationWithBlock {
                                        if
                                            url.hasPrefix("sqrl:") || url.hasPrefix("qrl:"),
                                        let
                                            url = NSURL(string: url)
                                        {
                                            return completion(url)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return completion(nil)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)
    {
        // If this is the context we've been waiting for
        if keyPath == StashPropertyContextKey {
            self.context = stash.context
            stash.removeObserver(self, forKeyPath: StashPropertyContextKey) // No longer listen
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    
    // MARK: - Table View 
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.identitiesFRC?.fetchedObjects?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCellWithIdentifier("Identity Cell", forIndexPath: indexPath) as? UITableViewCell
        {
            self.configureCell(cell, atIndexPath: indexPath)
            return cell
        }
        return UITableViewCell()
    }
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath)
    {
        if let
            identity = self.identitiesFRC?.fetchedObjects?[indexPath.row] as? Identity
            where cell.textLabel != nil
        {
            cell.textLabel!.text = identity.name
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        self.progressHud = MBProgressHUD.showHUDAddedTo(self.view, animated: true, labelText: "Creating Query")
        
        if let
            sqrlLink = self.sqrlLink,
            identity = self.identitiesFRC?.objectAtIndexPath(indexPath) as? Identity
        {
            let prompt = "Authorise access to \(identity.name)"
            
            if let
                masterKey = identity.masterKey.decryptCipherTextWithKeychain(authenticationPrompt: prompt),
                request   = NSMutableURLRequest(queryForSqrlLink: sqrlLink, masterKey: masterKey)
            {
                self.startSqrlExchange(
                    session: self.session,
                    sqrlLink: sqrlLink,
                    masterKey: masterKey,
                    lockKey: identity.lockKey,
                    delegate: self)
            }
            else
            {
                // Create alert view
                let alert = UIAlertController(title: "Authorise", message: nil, preferredStyle: .Alert)
                
                // Create cancel and OK buttons. Ok, on completion, takes the given password and creates a sqrl request
                let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                let ok     = UIAlertAction(title: "OK", style: .Default) { _ in
                    if let
                        passwordField = alert.textFields?[0] as? UITextField,
                        masterKey = identity.masterKey.decryptCipherTextWithPassword(passwordField.text),
                        request = NSMutableURLRequest(queryForSqrlLink: sqrlLink, masterKey: masterKey)
                    {
                        self.startSqrlExchange(
                            session: self.session,
                            sqrlLink: sqrlLink,
                            masterKey: masterKey,
                            lockKey: identity.lockKey,
                            delegate: self)
                    }
                }
                ok.enabled = false // disable the ok button initially
                
                // Add password field and disable/enable OK button depending on text entered
                alert.addTextFieldWithConfigurationHandler { textField in
                    textField.secureTextEntry = true
                    textField.placeholder = "Password"
                    
                    NSNotificationCenter.defaultCenter().addObserverForName(
                        UITextFieldTextDidChangeNotification,
                        object: textField,
                        queue: NSOperationQueue.mainQueue()) { _ in
                            ok.enabled = textField.text != ""
                    }
                }
                alert.addAction(ok)
                alert.addAction(cancel)
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func startSqrlExchange(
        #session: NSURLSession,
        sqrlLink: NSURL,
        masterKey: NSData,
        lockKey: NSData,
        delegate: SQRLSessionDelegate) -> Bool
    {
        if let sqrlTask = self.session.sqrlDataTaskForSqrlLink(sqrlLink, masterKey: masterKey, lockKey: lockKey, delegate: delegate)
        {
            sqrlTask.resume()
            self.progressHud.labelText = "Quering Server"
            return true
        }
        
        self.progressHud.hide(animated: true, labelText: "Couldn't Understand SQRL-Link", success: false)
        return false
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
        dispatch_async(dispatch_get_main_queue())
        {
            let labelText = success ? "Complete" : "Failed"
            self.progressHud.hide(animated:true, labelText: labelText, success: success)
            if success {
                self.done()
            }
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
    
    // MARK: - Fetched Results Controller
    private func createIdentitiesFetchedResultsController() {
        if let context = self.context {
            self.identitiesFRC = Identity.fetchedResultsController(context, delegate: self)
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    {
        switch type {
        case .Insert: self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete: self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:      return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type {
        case .Insert: self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete: self.tableView.deleteRowsAtIndexPaths([indexPath!],    withRowAnimation: .Fade)
        case .Update: self.configureCell(self.tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
        case .Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!],    withRowAnimation: .Fade)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        self.tableView.endUpdates()
    }
}
