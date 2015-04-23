//
//  IdentityCollectionViewController.swift
//  stash
//
//  Created by James Stidard on 23/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import CoreData

// MARK: - Delegate Protocol
protocol IdentityCollecionViewControllerDelegate: class
{
    func identityCollectionViewController(
        identityCollectionViewController: IdentityCollectionViewController,
        didSelectIdentity identity: Identity,
        withDecryptedMasterKey masterKey: NSData)
}

// MARK: -
class IdentityCollectionViewController: UICollectionViewController,
    UICollectionViewDelegateFlowLayout,
    NSFetchedResultsControllerDelegate,
    IdentityCellDelegate,
    ContextDriven
{
    // MARK: Public Properties
    static let SegueID = "IdentityCollectionViewController"
    
    weak var delegate:   IdentityCollecionViewControllerDelegate?
    weak var dataSource: SqrlLinkDataSource?
    
    var context :NSManagedObjectContext? {
        didSet {
            self.createIdentitiesFetchedResultsController()
            self.identitiesFRC?.performFetch(nil)
            self.collectionView?.reloadData()
        }
    }
    
    // MARK: Private Properties
    private var identitiesFRC:    NSFetchedResultsController?
    private let DefaultCellInset: CGFloat = 20.0
    private lazy var cellInset:   CGFloat = self.DefaultCellInset
    
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func invalidate()
    {
        // TODO:
        self.collectionView?.reloadData()
    }
    
    @IBAction func downSwipe(sender: UISwipeGestureRecognizer)
    {
        if let indexPaths = self.collectionView?.indexPathsForVisibleItems() as? [NSIndexPath]
        {
            for indexPath in indexPaths {
                self.collectionView(self.collectionView!, didDeselectItemAtIndexPath: indexPath)
            }
        }
    }
    
    // MARK: - Fetched Results Controller
    private func createIdentitiesFetchedResultsController() {
        if let context = self.context {
            self.identitiesFRC = Identity.fetchedResultsController(context, delegate: self)
        }
    }
    

    // MARK: - CollectionView Layout
    func collectionView(
        collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake(cellInset, cellInset, cellInset, cellInset)
    }
    
    func collectionView(
        collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return cellInset * 2
    }
    
    func collectionView(
        collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return cellInset * 2
    }
    
    func collectionView(
        collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let size            = collectionView.bounds.size
        let (width, height) = (size.width - (cellInset * 2), size.height - (cellInset * 2))
        
        return CGSize(width: width, height: height)
    }
    
    
    // MARK: CollectionView DataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1
    }

    override func collectionView(
        collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int
    {
        return self.identitiesFRC?.fetchedObjects?.count ?? 0
    }

    override func collectionView(
        collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(IdentityCell.ReuseID, forIndexPath: indexPath) as! IdentityCell
        let identity = self.identitiesFRC?.objectAtIndexPath(indexPath) as? Identity
        
        cell.nameLabel.text = identity?.name
        cell.delegate       = self
        
        return cell
    }

    // MARK: CollectionView Delegate
    override func collectionView(
        collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let
            cell      = collectionView.cellForItemAtIndexPath(indexPath) as? IdentityCell,
            sqrlLink  = self.dataSource?.sqrlLink,
            identity  = self.identitiesFRC?.objectAtIndexPath(indexPath) as? Identity
        {
            // if we have user auth from keychain / touchID
            if let masterKey = identity.masterKey.decryptCipherTextWithKeychain(prompt: "Authorise access to \(identity.name) identity")
            {
                self.delegate?.identityCollectionViewController(self, didSelectIdentity: identity, withDecryptedMasterKey: masterKey)
            }
            // if we need to get the users password
            else
            {
                cell.requestPassword(true, animated: true)
                cell.passwordField.becomeFirstResponder()
                
                self.cellInset = 0 // Cell should take up entire collection view for password
                collectionView.performBatchUpdates {
                    collectionView.collectionViewLayout.invalidateLayout()
                }
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as? IdentityCell
        cell?.requestPassword(false, animated: true)
        cell?.passwordField.resignFirstResponder()
        
        self.cellInset = DefaultCellInset // Cell should take up entire collection view for password
        collectionView.performBatchUpdates {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

    // MARK: - Identity Cell Delegate
    func identityCell(identityCell: IdentityCell, didDecryptStore sensitiveData: NSData)
    {
        if let
            indexPath = self.collectionView?.indexPathForCell(identityCell),
            identity  = self.identitiesFRC?.objectAtIndexPath(indexPath) as? Identity
        {
            self.delegate?.identityCollectionViewController(self, didSelectIdentity: identity, withDecryptedMasterKey: sensitiveData)
        }
        
        // The keyboard will be minimising and cell changing state at this point so we need to invalidate the layout
        identityCell.passwordField.resignFirstResponder()
        self.cellInset = DefaultCellInset
        self.collectionView?.performBatchUpdates {
            self.collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    func storeToDecryptForIdentityCell(identityCell: IdentityCell) -> XORStore?
    {
        if let
            indexPath = self.collectionView?.indexPathForCell(identityCell),
            identity  = self.identitiesFRC?.objectAtIndexPath(indexPath) as? Identity
        {
            return identity.masterKey
        }
        
        return nil
    }
}
