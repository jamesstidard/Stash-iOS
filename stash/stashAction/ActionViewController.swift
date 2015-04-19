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

class ActionViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
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
        self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
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
                                        if url.hasPrefix("sqrl:") || url.hasPrefix("qrl:"),
                                            let url = NSURL(string: url)
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
        // If this is the context we've been waiting for, tell anyone we have contracts with and set it locally
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
