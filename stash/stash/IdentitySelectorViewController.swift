//
//  IdentitySelectorViewController.swift
//  stash
//
//  Created by James Stidard on 25/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import CoreData

class IdentitySelectorViewController: UIViewController,
    NSFetchedResultsControllerDelegate,
    ContextDriven,
    UIPageViewControllerDelegate,
    UIPageViewControllerDataSource
{
    static let SegueID = "IdentitySelectorViewControllerSegue"
    
    private var pendingPage: IdentityViewController?
    private var currentPage: IdentityViewController?

    var context :NSManagedObjectContext? {
        didSet {
            createIdentitiesFetchedResultsController()
            identitiesFRC?.performFetch(nil)
            self.controllerDidChangeContent(identitiesFRC!)
        }
    }
    var identitiesFRC:         NSFetchedResultsController?
    var pageVC:                UIPageViewController?
    weak var selectorDelegate: IdentitySelectorViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func createIdentitiesFetchedResultsController() {
        if let context = self.context {
            let request             = NSFetchRequest(entityName: IdentityClassNameKey)
            request.sortDescriptors = [NSSortDescriptor(key: IdentityPropertyNameKey, ascending: true, selector: "localizedCaseInsensitiveCompare:")]
            
            identitiesFRC = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil)
            identitiesFRC?.delegate = self
            identitiesFRC?.fetchRequest.fetchLimit = 5
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
        self.pendingPage = pendingViewControllers.first as? IdentityViewController
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool)
    {
        if completed {
            self.currentPage = self.pendingPage
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
        if let
            viewController  = viewController as? IdentityViewController,
            currentIdentity = viewController.identity,
            allIdentities   = self.identitiesFRC?.fetchedObjects as? [Identity],
            previousIndex   = find(allIdentities, currentIdentity) -? 1,
            identityVC      = self.storyboard?.instantiateViewControllerWithIdentifier(IdentityViewController.StoryboardID) as? IdentityViewController
        {
            identityVC.identity = (previousIndex >= 0) ? allIdentities[previousIndex] : allIdentities.last
            return identityVC
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
    {
        if let
            viewController  = viewController as? IdentityViewController,
            currentIdentity = viewController.identity,
            allIdentities   = self.identitiesFRC?.fetchedObjects as? [Identity],
            nextIndex       = find(allIdentities, currentIdentity) +? 1,
            identityVC      = self.storyboard?.instantiateViewControllerWithIdentifier(IdentityViewController.StoryboardID) as? IdentityViewController
        {
            identityVC.identity = (nextIndex < allIdentities.count) ? allIdentities[nextIndex] : allIdentities.first
            return identityVC
        }
        
        return nil
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        // if the previous identity is avalible in the updated array then focus that
        if let
            pageVC      = self.pageVC,
            identities  = self.identitiesFRC?.fetchedObjects as? [Identity],
            previous    = self.currentPage?.identity,
            index       = find(identities, previous)
        {
            pageVC.setViewControllers([self.currentPage!], direction: .Forward, animated: false, completion: nil)
        }
        // else focus the first identity
        else if let
            pageVC     = self.pageVC,
            identity   = self.identitiesFRC?.fetchedObjects?.first as? Identity,
            identityVC = self.storyboard?.instantiateViewControllerWithIdentifier(IdentityViewController.StoryboardID) as? IdentityViewController
        {
            identityVC.identity = identity
            pageVC.setViewControllers([identityVC], direction: .Forward, animated: true, completion: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        var destinationVC = segue.destinationViewController as! UIViewController
        
        if let vc = destinationVC as? UIPageViewController {
            // set up out translator so we can use the pageVC more like a tableview
            self.pageVC = vc
            self.pageVC?.dataSource = self
            self.pageVC?.delegate   = self
        }
    }
}


protocol IdentitySelectorViewControllerDelegate :class {
    
}
