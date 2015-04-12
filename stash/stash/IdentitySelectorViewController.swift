//
//  IdentitySelectorViewController.swift
//  stash
//
//  Created by James Stidard on 25/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import CoreData


protocol IdentitySelectorViewControllerDelegate :class {
    
}


class IdentitySelectorViewController: UIViewController,
    NSFetchedResultsControllerDelegate,
    ContextDriven,
    UIPageViewControllerDelegate,
    UIPageViewControllerDataSource
{
    static let SegueID = "IdentitySelectorViewControllerSegue"
    
    private var identitiesFRC: NSFetchedResultsController?
    private var pageVC:        UIPageViewController?
    private var pendingPage:   IdentityViewController?
    private var currentPage:   IdentityViewController?
    
    weak var selectorDelegate: IdentitySelectorViewControllerDelegate?
    var context :NSManagedObjectContext? {
        didSet {
            self.createIdentitiesFetchedResultsController()
            self.identitiesFRC?.performFetch(nil)
            self.controllerDidChangeContent(identitiesFRC!)
        }
    }
    var promptForPassword = false {
        didSet {
            if let vcs = self.pageVC?.viewControllers as? [IdentityViewController] {
                vcs.map { $0.promptForPassword = self.promptForPassword }
            }
        }
    }
    
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - SQRL Link signage
    func responseForSqrlLink(sqrlLink: NSURL?, response: NSURLSessionTask -> Void)
    {
        // only ask for password if there is a sqrl link to respond to
        self.promptForPassword = (sqrlLink == nil) ? false : true
    }

    
    // MARK: - Page View Controller
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
            identityVC.promptForPassword = self.promptForPassword
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
            identityVC.promptForPassword = self.promptForPassword
            return identityVC
        }
        
        return nil
    }
    
    
    // MARK: - FRC
    private func createIdentitiesFetchedResultsController() {
        if let context = self.context {
            self.identitiesFRC = Identity.fetchedResultsController(context, delegate: self)
        }
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
            identityVC.promptForPassword = self.promptForPassword
            pageVC.setViewControllers([identityVC], direction: .Forward, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Navigation
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

