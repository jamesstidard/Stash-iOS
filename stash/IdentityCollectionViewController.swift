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
        _ identityCollectionViewController: IdentityCollectionViewController,
        didSelectIdentity identity: Identity,
        withDecryptedMasterKey masterKey: Data)
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
    fileprivate var identitiesFRC:    NSFetchedResultsController<NSFetchRequestResult>?
    fileprivate let DefaultCellInset: CGFloat = 20.0
    fileprivate lazy var cellInset:   CGFloat = self.DefaultCellInset
    
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func invalidate()
    {
        // TODO:
        self.collectionView?.reloadData()
    }
    
    @IBAction func downSwipe(_ sender: UISwipeGestureRecognizer)
    {
        if let indexPaths = self.collectionView?.indexPathsForVisibleItems as? [IndexPath]
        {
            for indexPath in indexPaths {
                self.collectionView(self.collectionView!, didDeselectItemAtIndexPath: indexPath)
            }
        }
    }
    
    // MARK: - Fetched Results Controller
    fileprivate func createIdentitiesFetchedResultsController() {
        if let context = self.context {
            self.identitiesFRC = Identity.fetchedResultsController(context, delegate: self)
        }
    }
    

    // MARK: - CollectionView Layout
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake(cellInset, cellInset, cellInset, cellInset)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        return cellInset * 2
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return cellInset * 2
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let size            = collectionView.bounds.size
        let (width, height) = (size.width - (cellInset * 2), size.height - (cellInset * 2))
        
        return CGSize(width: width, height: height)
    }
    
    
    // MARK: CollectionView DataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int
    {
        return self.identitiesFRC?.fetchedObjects?.count ?? 0
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IdentityCell.ReuseID, for: indexPath) as! IdentityCell
        let identity = self.identitiesFRC?.object(at: indexPath) as? Identity
        
        cell.nameLabel.text = identity?.name
        cell.delegate       = self
        
        return cell
    }

    // MARK: CollectionView Delegate
    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath)
    {
        if let
            cell      = collectionView.cellForItem(at: indexPath) as? IdentityCell,
            let sqrlLink  = self.dataSource?.sqrlLink,
            let identity  = self.identitiesFRC?.object(at: indexPath) as? Identity
        {
            // if we have user auth from keychain / touchID
            if let masterKey = identity.masterKey.decryptCipherTextWithKeychain(prompt: "Authorise access to \(identity.name) identity") {
                self.delegate?.identityCollectionViewController(self, didSelectIdentity: identity, withDecryptedMasterKey: masterKey)
            }
            // if we need to get the users password
            else {
                self.showPasswordCapture(true, forIdentityCell: cell, onCollectionView: collectionView)
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? IdentityCell {
            self.showPasswordCapture(false, forIdentityCell: cell, onCollectionView: collectionView)
        }
    }
    
    func showPasswordCapture(_ show: Bool, forIdentityCell cell: IdentityCell, onCollectionView collectionView: UICollectionView)
    {
        cell.requestPassword(show, animated: true)
        collectionView.isScrollEnabled = !show
        
        if show {
            cell.passwordField.becomeFirstResponder()
            self.cellInset = 0
        } else {
            cell.passwordField.resignFirstResponder()
            self.cellInset = DefaultCellInset
        }
        
        collectionView.performBatchUpdates {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    // MARK: - Identity Cell Delegate
    func identityCell(_ identityCell: IdentityCell, didDecryptStore sensitiveData: Data)
    {
        if let
            indexPath = self.collectionView?.indexPath(for: identityCell),
            let identity  = self.identitiesFRC?.object(at: indexPath) as? Identity
        {
            self.delegate?.identityCollectionViewController(self, didSelectIdentity: identity, withDecryptedMasterKey: sensitiveData)
        }
        
        // The keyboard will be minimising and cell changing state at this point so we need to invalidate the layout
        self.showPasswordCapture(false, forIdentityCell: identityCell, onCollectionView: self.collectionView!)
    }
    
    func storeToDecryptForIdentityCell(_ identityCell: IdentityCell) -> XORStore?
    {
        if let
            indexPath = self.collectionView?.indexPath(for: identityCell),
            let identity  = self.identitiesFRC?.object(at: indexPath) as? Identity
        {
            return identity.masterKey
        }
        
        return nil
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.collectionView?.reloadData()
    }
}
