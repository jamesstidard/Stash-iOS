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
    
    fileprivate var identitiesFRC: NSFetchedResultsController<NSFetchRequestResult>?
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
    
    override func tableView(
        _ tableView: UITableView,
        canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCellEditingStyle,
        forRowAt indexPath: IndexPath)
    {
        if  editingStyle == .delete,
        let identity = self.identitiesFRC?.object(at: indexPath) as? Identity
        {
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
                identity.masterKey.removeFromKeychain() // TODO: Find a better place for this
                identity.managedObjectContext?.delete(identity)
                identity.managedObjectContext?.save(nil)
            }
            UIAlertController.showAlert(
                title: "Delete \(identity.name)?",
                message: "Make sure you have backed up this identity and it's rescue code, " +
                         "if you don't want to loose access to the accounts created under this identity.",
                viewController: self,
                actions: cancel, delete)
            
        }
    }
    
    fileprivate func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
    {
        if let
            identity = self.identitiesFRC?.fetchedObjects?[indexPath.row] as? Identity, cell.textLabel != nil
        {
            cell.textLabel!.text = identity.name
        }
    }
    
    // MARK: Fetched Results Controller
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
    
    // MARK: Navigation
    @IBAction func closePressed(_ sender: UIBarButtonItem)
    {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationVC = segue.destination 
        
        // upwrap navigation controllers
        if let
            navigationController = destinationVC as? UINavigationController,
            let rootVC               = navigationController.viewControllers[0] as? UIViewController
        {
            destinationVC = rootVC
        }
        
        // if requires a context pass it ours
        if let vc = destinationVC as? ContextDriven {
            vc.context = self.context
        }
    }
}
