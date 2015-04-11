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
    UIPageViewControllerIndexTranslatorDelegate
{
    static let SegueID = "IdentitySelectorViewControllerSegue"

    var context :NSManagedObjectContext? {
        didSet {
            createIdentitiesFetchedResultsController()
            identitiesFRC?.performFetch(nil)
            self.controllerDidChangeContent(identitiesFRC!)
        }
    }
    var identitiesFRC:         NSFetchedResultsController?
    var pageVC:                UIPageViewController?
    var pageVCTranslator:      UIPageViewControllerIndexTranslator?
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
            let fetchRequest             = NSFetchRequest(entityName: IdentityClassNameKey)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: IdentityPropertyNameKey, ascending: true)]
            
            identitiesFRC = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil)
            identitiesFRC?.delegate = self
            identitiesFRC?.fetchRequest.fetchLimit = 5
        }
    }
    
    func numberOfPagesInPageViewController(pageViewController: UIPageViewController) -> Int
    {
        return self.identitiesFRC?.fetchedObjects?.count ?? 0
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAtIndex index: Int) -> UIViewController?
    {
        if let
            identity   = self.identitiesFRC?.fetchedObjects?[index] as? Identity,
            identityVC = self.storyboard?.instantiateViewControllerWithIdentifier(IdentityViewController.StoryboardID) as? IdentityViewController
        
        {
            identityVC.identity = identity
            return identityVC
        }
        return nil
    }
    
    
    
    var previousIdentity: Identity?
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        // If the controller is going to change, we dont want to change the currently prespented identity
        let currentPage       = self.pageVCTranslator?.currentPage as? IdentityViewController
        self.previousIdentity = currentPage?.identity
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        // if the previous identity is avalible in the updated array then focus that
        if let
            pageVC      = self.pageVC,
            identities  = self.identitiesFRC?.fetchedObjects as? [Identity],
            previous    = self.previousIdentity,
            index       = find(identities, previous),
            vcToDisplay = self.pageViewController(pageVC, viewControllerAtIndex: index)
        {
            pageVC.setViewControllers([vcToDisplay], direction: .Forward, animated: false, completion: nil)
        }
        // else focus the first identity
        else if let
            pageVC      = self.pageVC,
            vcToDisplay = self.pageViewController(pageVC, viewControllerAtIndex: 0)
        {
            pageVC.setViewControllers([vcToDisplay], direction: .Forward, animated: true, completion: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        var destinationVC = segue.destinationViewController as! UIViewController
        
        if let vc = destinationVC as? UIPageViewController {
            // set up out translator so we can use the pageVC more like a tableview
            self.pageVC = vc
            self.pageVCTranslator = UIPageViewControllerIndexTranslator(pageViewController: vc, delegate: self)
        }
    }
}


protocol IdentitySelectorViewControllerDelegate :class {
    
}
