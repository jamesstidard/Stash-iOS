//
//  UIViewShake.swift
//  stash
//
//  Created by James Stidard on 24/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension UIView
{
    func shake()
    {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration     = 0.07
        animation.repeatCount  = 4
        animation.autoreverses = true
        animation.fromValue    = NSValue(CGPoint: CGPointMake(self.center.x - 10, self.center.y))
        animation.toValue      = NSValue(CGPoint: CGPointMake(self.center.x + 10, self.center.y))
        self.layer.addAnimation(animation, forKey: "position")
    }
}