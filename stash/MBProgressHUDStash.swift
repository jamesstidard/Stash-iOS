//
//  MBProgressHUDStash.swift
//  stash
//
//  Created by James Stidard on 21/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension MBProgressHUD
{
    func show(#animated: Bool, _ labelText: String)
    {
        self.labelText = labelText
        self.mode      = .indeterminate
        DispatchQueue.main.async {
            self.show(animated)
        }
    }
    
    func hide(#animated: Bool, _ labelText: String, delay: TimeInterval = 1)
    {
        self.labelText = labelText
        self.mode      = .indeterminate
        DispatchQueue.main.async {
            self.hide(animated, afterDelay: delay)
        }
    }
    
    func hide(#animated: Bool, _ labelText: String, success: Bool, delay: TimeInterval = 1.5)
    {
        let imageName = success ? "Tick" : "Cross"
        
        self.labelText            = labelText
        self.detailsLabelText     = nil
        let image                 = UIImage(named: imageName)
        self.customView           = UIImageView(image: image)
        self.customView.tintColor = UIColor.white
        self.mode                 = .customView
        DispatchQueue.main.async {
            self.hide(animated, afterDelay: delay)
        }
    }
    
    func hide(#animated: Bool, _ labelText: String, detailsText: String, success: Bool, delay: TimeInterval = 1.5)
    {
        self.hide(animated: animated, labelText: labelText, success: success, delay: delay)
        self.detailsLabelText = detailsText
    }
    
    class func showHUDAddedTo(_ view: UIView, animated: Bool, labelText: String) -> MBProgressHUD
    {
        let hud = MBProgressHUD.showAdded(to: view, animated: animated)
        hud?.labelText = labelText
        return hud!
    }
}
