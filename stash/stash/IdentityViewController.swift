//
//  IdentityViewController.swift
//  stash
//
//  Created by James Stidard on 10/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//
import UIKit

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
    @IBOutlet weak var nameLabelCenterY: NSLayoutConstraint!
    @IBOutlet weak var passwordField: UITextField!
    
    weak var identity: Identity?
    var promptForPassword = false {
        didSet {
            if self.detailLabel != nil {
                self.detailLabel.hidden = !promptForPassword
            }
        }
    }
    private var mode: IdenitiyViewControllerMode = .Inactive {
        didSet {
            if self.imageView != nil && self.nameLabel != nil && self.detailLabel != nil {
                switch self.mode
                {
                case .Inactive, .Active:
                    self.imageView.hidden     = false
                    self.nameLabel.hidden     = false
                    self.detailLabel.hidden   = !promptForPassword
                    self.passwordField.hidden = true
                    self.passwordField.resignFirstResponder()
                    
                case .PasswordGathering:
                    self.imageView.hidden     = true
                    self.nameLabel.hidden     = true
                    self.detailLabel.hidden   = true
                    self.passwordField.hidden = false
                    self.passwordField.becomeFirstResponder()
                }
                self.passwordField.placeholder = "Password for \(self.identity!.name)"
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameLabel.text         = self.identity?.name
        self.passwordField.delegate = self
    }
    
    
    // MARK: - Password Text Field
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        // handle user password submission
        
        
        return true
    }
    
    
    // MARK: - UI Actions
    @IBAction func didTap(sender: UITapGestureRecognizer)
    {
        // check if user tap is enabled
        if (self.promptForPassword) {
            self.mode = .PasswordGathering
        }
    }
    
    @IBAction func swipedDown(sender: UISwipeGestureRecognizer)
    {
        if self.mode == .PasswordGathering
        {
            self.mode = (self.promptForPassword) ? .Active : .Inactive
        }
    }
}
