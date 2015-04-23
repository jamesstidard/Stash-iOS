//
//  IdentityViewController.swift
//  stash
//
//  Created by James Stidard on 10/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//
import UIKit

protocol IdentityViewControllerDelegate: class
{
    func identityViewController(
        identityViewController: IdentityViewController,
        didSelectIdentity identity: Identity,
        withDecryptedMasterKey masterKey: NSData)
}

private enum IdenitiyViewControllerMode
{
    case Inactive
    case Active
    case PasswordGathering
}

class IdentityViewController: UIViewController,
    UITextFieldDelegate
{
    static let StoryboardID = "IdentityViewController"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var leftSpacingConstaint: NSLayoutConstraint!
    @IBOutlet weak var rightSpacingConstaint: NSLayoutConstraint!
    @IBOutlet weak var topSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSpacingContraint: NSLayoutConstraint!
    
    weak var delegate:   IdentityViewControllerDelegate?
    weak var dataSource: SqrlLinkDataSource?
    weak var identity:   Identity?
    
    private var mode: IdenitiyViewControllerMode = .Inactive {
        didSet {
            if self.imageView != nil && self.nameLabel != nil && self.detailLabel != nil {
                self.imageView.hidden     = false
                self.nameLabel.hidden     = false
                self.detailLabel.hidden   = false
                self.passwordField.hidden = false
                self.view.layoutIfNeeded()
                
                UIView.animateWithDuration(0.35, animations: {
                    switch self.mode
                    {
                    case .Inactive, .Active:
                        self.imageView.alpha     = 1.0
                        self.nameLabel.alpha     = 1.0
                        self.detailLabel.alpha   = self.dataSource?.sqrlLink != nil ? 1.0 : 0.0
                        self.passwordField.alpha = 0.0
                        self.leftSpacingConstaint.constant   = -10
                        self.rightSpacingConstaint.constant  = -10
                        self.bottomSpacingContraint.constant = 6
                        self.topSpacingConstraint.constant   = 6
                        
                    case .PasswordGathering:
                        self.imageView.alpha     = 0.0
                        self.nameLabel.alpha     = 0.0
                        self.detailLabel.alpha   = 0.0
                        self.passwordField.alpha = 1.0
                        self.leftSpacingConstaint.constant   = -16
                        self.rightSpacingConstaint.constant  = -16
                        self.bottomSpacingContraint.constant = 0
                        self.topSpacingConstraint.constant   = 51
                    }
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    
                    switch self.mode
                    {
                    case .Inactive, .Active:
                        self.imageView.hidden     = false
                        self.nameLabel.hidden     = false
                        self.detailLabel.hidden   = self.dataSource?.sqrlLink == nil
                        self.passwordField.hidden = true
                        self.passwordField.text   = nil
                        
                    case .PasswordGathering:
                        self.imageView.hidden     = true
                        self.nameLabel.hidden     = true
                        self.detailLabel.hidden   = true
                        self.passwordField.hidden = false
                        self.passwordField.text   = nil
                    }
                })
                (self.mode == .PasswordGathering) ? self.passwordField.becomeFirstResponder() : self.passwordField.resignFirstResponder()
                self.passwordField.placeholder = "Password for \(self.identity!.name)"
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameLabel.text         = self.identity?.name
        self.passwordField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.invalidate()
        self.view.layoutIfNeeded()
    }
    
    func invalidate() {
        // if we are gathering a password and we loose the sqrl link
        if self.dataSource?.sqrlLink == nil && self.mode == .PasswordGathering {
            self.passwordField.resignFirstResponder()
        }
        // else set mode based on sqrl link state
        else {
            self.mode = (self.dataSource?.sqrlLink != nil) ? .Active : .Inactive
        }
    }
    
    
    // MARK: - Password Text Field
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        // handle user password submission
        if let key = self.identity?.masterKey.decryptCipherTextWithPassword(textField.text)
        {
            self.delegate?.identityViewController(self, didSelectIdentity: self.identity!, withDecryptedMasterKey: key)
        }
        
        self.mode = (self.dataSource?.sqrlLink != nil) ? .Active : .Inactive
        return true
    }
    
    
    // MARK: - UI Actions
    @IBAction func didTap(sender: UITapGestureRecognizer)
    {
        // if there is a sqrl link and a keychained password
        if  self.dataSource?.sqrlLink != nil,
        let key = self.identity?.masterKey.decryptCipherTextWithKeychain(prompt: "Authorise access to \(self.identity!.name) identity")
        {
            self.delegate?.identityViewController(self, didSelectIdentity: identity!, withDecryptedMasterKey: key)
        }
        // if there is a sqrl link and password is needed
        else if self.dataSource?.sqrlLink != nil
        {
            self.mode = .PasswordGathering
        }
    }
    
    @IBAction func swipedDown(sender: UISwipeGestureRecognizer)
    {
        if self.mode == .PasswordGathering
        {
            self.mode = (self.dataSource?.sqrlLink != nil) ? .Active : .Inactive
        }
    }
}
