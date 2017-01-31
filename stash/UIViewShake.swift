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
        animation.fromValue    = NSValue(cgPoint: CGPoint(x: self.center.x - 10, y: self.center.y))
        animation.toValue      = NSValue(cgPoint: CGPoint(x: self.center.x + 10, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
}
