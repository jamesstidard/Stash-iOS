//
//  IdentityManagementTableViewController.swift
//  stash
//
//  Created by James Stidard on 11/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//
import UIKit
import CoreData

class IdentityManagementTableViewController: UITableViewController,
    ContextDriven,
    NSFetchedResultsControllerDelegate
{
    static let SegueID = "IdentityManagementSegue"
    
    private var identitiesFRC: NSFetchedResultsController?
    var context :NSManagedObjectContext? {
        didSet {
            if context != nil {
                self.identitiesFRC = Identity.fetchedResultsController(context!, delegate: self)
                self.identitiesFRC!.performFetch(nil)
                self.controllerDidChangeContent(identitiesFRC!)
            }
        }
    }
    
    
    // MARK: Life Cycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    // MARK: Table View
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
    
    // MARK: Fetched Results Controller
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    {
        switch type
        {
        case .Insert: self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete: self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:      return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type
        {
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
    
    // MARK: Navigation
    @IBAction func closePressed(sender: UIBarButtonItem)
    {
        dismissViewControllerAnimated(true, completion: nil)
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
            vc.context = self.context
        }
    }
}
