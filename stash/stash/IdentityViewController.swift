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
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    weak var identity: Identity?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
