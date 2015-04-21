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
    func show(#animated: Bool, labelText: String)
    {
        self.labelText = labelText
        self.mode      = .Indeterminate
        dispatch_async(dispatch_get_main_queue()) {
            self.show(animated)
        }
    }
    
    func hide(#animated: Bool, labelText: String, delay: NSTimeInterval = 1)
    {
        self.labelText = labelText
        self.mode      = .Indeterminate
        dispatch_async(dispatch_get_main_queue()) {
            self.hide(animated, afterDelay: delay)
        }
    }
    
    func hide(#animated: Bool, labelText: String, success: Bool, delay: NSTimeInterval = 1.5)
    {
        let imageName = success ? "Tick" : "Cross"
        
        self.labelText            = labelText
        let image                 = UIImage(named: imageName)
        self.customView           = UIImageView(image: image)
        self.customView.tintColor = UIColor.whiteColor()
        self.mode                 = .CustomView
        dispatch_async(dispatch_get_main_queue()) {
            self.hide(animated, afterDelay: delay)
        }
    }
    
    class func showHUDAddedTo(view: UIView, animated: Bool, labelText: String) -> MBProgressHUD
    {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: animated)
        hud.labelText = labelText
        return hud
    }
}