//
//  IdentitySelectorViewController.swift
//  stash
//
//  Created by James Stidard on 25/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import CoreData

let IdentitySelectorVCSegueId = "IdentitySelectorViewControllerSegue"

class IdentitySelectorViewController: UIPageViewController, NSFetchedResultsControllerDelegate, ContextDriven {

    var context :NSManagedObjectContext? {
        didSet {
            createIdentitiesFetchedResultsController()
            identitiesFRC?.performFetch(nil)
        }
    }
    var identitiesFRC: NSFetchedResultsController?
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
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        return
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}


protocol IdentitySelectorViewControllerDelegate :class {
    
}
