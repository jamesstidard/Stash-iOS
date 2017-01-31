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
    URLSessionDelegate
{
    @IBOutlet weak var imageView: UIImageView!
    
    lazy var session: Foundation.URLSession = Foundation.URLSession(stashSessionWithdelegate: self)
    
    let stash = Stash()
    var context: NSManagedObjectContext? = nil {
        didSet {
            self.createIdentitiesFetchedResultsController()
            self.identitiesFRC?.performFetch(nil)
            self.controllerDidChangeContent(identitiesFRC!)
        }
    }
    
    fileprivate var identitiesFRC: NSFetchedResultsController<NSFetchRequestResult>?
    
    var sqrlLink: URL?
    
    lazy var progressHud: MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)

    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Start trying to find that sqrlLink
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            ActionViewController.findSqrlLinkFromExtensionContext(self.extensionContext) { sqrlLink in
                DispatchQueue.main.async {
                    self.sqrlLink = sqrlLink
                }
            }
        }
        
        // If the moc has yet to be initialised, start listening for it
        if stash.context == nil {
            stash.addObserver(self, forKeyPath: StashPropertyContextKey, options: .new, context: nil)
        }
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }

    class func findSqrlLinkFromExtensionContext(_ context: NSExtensionContext?, completion: @escaping ((URL?) -> ()))
    {
        // Bend over backwards to get a sqrl url
        for item: NSExtensionItem in context?.inputItems as! Array {
            for provider: NSItemProvider in item.attachments as! Array {
                
                if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                    provider.loadItemForTypeIdentifier(kUTTypePropertyList as String, options: nil) { (results: NSSecureCoding!, error: NSError!) in
                        
                        if let results = results as? NSDictionary, results.count > 0 {
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
    
    override func observeValue(forKeyPath keyPath: String, of object: AnyObject, change: [AnyHashable: Any], context: UnsafeMutableRawPointer)
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
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.identitiesFRC?.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Identity Cell", for: indexPath) as? UITableViewCell
        {
            self.configureCell(cell, atIndexPath: indexPath)
            return cell
        }
        return UITableViewCell()
    }
    
    fileprivate func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
    {
        if let
            identity = self.identitiesFRC?.fetchedObjects?[indexPath.row] as? Identity, cell.textLabel != nil
        {
            cell.textLabel!.text = identity.name
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let
            sqrlLink = self.sqrlLink,
            let identity = self.identitiesFRC?.object(at: indexPath) as? Identity
        {
            let prompt = "Authorise access to \(identity.name)"
            
            if let
                masterKey = identity.masterKey.decryptCipherTextWithKeychain(prompt: prompt),
                let request   = NSMutableURLRequest(queryForSqrlLink: sqrlLink, masterKey: masterKey)
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
                let alert = UIAlertController(title: "Authorise", message: nil, preferredStyle: .alert)
                
                // Create cancel and OK buttons. Ok, on completion, takes the given password and creates a sqrl request
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let ok     = UIAlertAction(title: "OK", style: .default) { _ in
                    if let
                        passwordField = alert.textFields?[0] as? UITextField,
                        let masterKey = identity.masterKey.decryptCipherTextWithPassword(passwordField.text),
                        let request = NSMutableURLRequest(queryForSqrlLink: sqrlLink, masterKey: masterKey)
                    {
                        self.startSqrlExchange(
                            session: self.session,
                            sqrlLink: sqrlLink,
                            masterKey: masterKey,
                            lockKey: identity.lockKey,
                            delegate: self)
                    }
                }
                ok.isEnabled = false // disable the ok button initially
                
                // Add password field and disable/enable OK button depending on text entered
                alert.addTextField { textField in
                    textField.isSecureTextEntry = true
                    textField.placeholder = "Password"
                    
                    NotificationCenter.default.addObserver(
                        forName: NSNotification.Name.UITextFieldTextDidChange,
                        object: textField,
                        queue: OperationQueue.main) { _ in
                            ok.isEnabled = textField.text != ""
                    }
                }
                alert.addAction(ok)
                alert.addAction(cancel)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func startSqrlExchange(
        #session: NSURLSession,
        _ sqrlLink: URL,
        masterKey: Data,
        lockKey: Data,
        delegate: SQRLSessionDelegate) -> Bool
    {
        self.progressHud = MBProgressHUD.showHUDAddedTo(self.view, animated: true, labelText: "Creating Query")
        
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
    func SQRLSession(_ session: Foundation.URLSession, shouldLoginAccountForServer serverName: String, proceed: @escaping (Bool) -> ()) {
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.progressHud.hide(animated: true, labelText: "Canceled", success: false)
            proceed(false)
        }
        let login = UIAlertAction(title: "Login", style: .default) { _ in
            self.progressHud.labelText = "Requesting Login"
            proceed(true)
        }
        self.showAlert(
            serverName,
            message: "Would you like to log into your \(serverName) account?",
            actions: cancel, login)
    }
    
    func SQRLSession(_ session: Foundation.URLSession, shouldCreateAccountForServer serverName: String, proceed: @escaping (Bool) -> ()) {
        // Prompt user for to confirm and on confirmation send new request
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.progressHud.hide(animated: true, labelText: "Canceled", success: false)
            proceed(false)
        }
        let create = UIAlertAction(title: "Create", style: .default) { _ in
            self.progressHud.labelText = "Requesting New Account"
            proceed(true)
        }
        self.showAlert(
            serverName,
            message: "Looks like \(serverName) doesn't recognise you.\n\nDid you want to create an account with \(serverName)?",
            actions: cancel, create)
    }
    
    func SQRLSession(_ session: Foundation.URLSession, succesfullyCompleted success: Bool)
    {
        DispatchQueue.main.async
        {
            let labelText = success ? "Complete" : "Failed"
            self.progressHud.hide(animated:true, labelText: labelText, success: success)
            if success {
                self.done()
            }
        }
    }
    
    func showAlert(_ title: String, message: String, actions: UIAlertAction...)
    {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        
        actions.map { alert.addAction($0) }
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
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
    
    // MARK: - Fetched Results Controller
    fileprivate func createIdentitiesFetchedResultsController() {
        if let context = self.context {
            self.identitiesFRC = Identity.fetchedResultsController(context, delegate: self)
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        switch type {
        case .insert: self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete: self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:      return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type {
        case .insert: self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete: self.tableView.deleteRows(at: [indexPath!],    with: .fade)
        case .update: self.configureCell(self.tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            self.tableView.deleteRows(at: [indexPath!],    with: .fade)
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.tableView.endUpdates()
    }
}
