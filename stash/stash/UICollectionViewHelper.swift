//
//  UICollectionViewHelper.swift
//  stash
//
//  Created by James Stidard on 23/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension UICollectionView
{
    func performBatchUpdates(updates: (() -> Void)?)
    {
        self.performBatchUpdates(updates, completion: nil)
    }
}