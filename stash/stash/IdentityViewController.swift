//
//  IdentityViewController.swift
//  stash
//
//  Created by James Stidard on 10/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//
import UIKit

class IdentityViewController: UIViewController
{
    static let StoryboardID = "IdentityViewController"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var nameLabelCenterY: NSLayoutConstraint!
    
    weak var identity: Identity?
    var promptForPassword = false {
        didSet {
            if self.detailLabel != nil {
                self.detailLabel.hidden = !promptForPassword
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameLabel.text = self.identity?.name
    }
}
