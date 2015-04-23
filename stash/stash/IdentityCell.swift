//
//  IdentityCell.swift
//  stash
//
//  Created by James Stidard on 23/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit

class IdentityCell: UICollectionViewCell {

    static let ReuseID = "Identity Cell"
    
    @IBOutlet weak var identityView:  UIView!
    @IBOutlet weak var imageView:     UIImageView!
    @IBOutlet weak var nameLabel:     UILabel!
    @IBOutlet weak var passwordView:  UIView!
    @IBOutlet weak var passwordField: UITextField!
    
    var requestPassword: Bool = false {
        didSet {
            identityView.hidden =  requestPassword
            passwordView.hidden = !requestPassword
            
            identityView.alpha  =  requestPassword ? 0.0 : 1.0
            passwordView.alpha  =  requestPassword ? 1.0 : 0.0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    func requestPassword(request: Bool, animated: Bool)
    {
        self.identityView.hidden = false
        self.passwordView.hidden = false
        
        UIView.animateWithDuration(0.4, animations: {
            self.identityView.alpha = request ? 0.0 : 1.0
            self.passwordView.alpha = request ? 1.0 : 0.0
            
        }) { complete in
            self.requestPassword = request
        }
    }
}
