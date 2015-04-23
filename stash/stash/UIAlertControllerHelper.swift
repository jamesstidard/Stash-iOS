//
//  UIAlertControllerHelper.swift
//  stash
//
//  Created by James Stidard on 22/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension UIAlertController
{
    class func showAlert(#title: String, message: String, viewController: UIViewController, actions: UIAlertAction...)
    {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .Alert)
        
        actions.map { alert.addAction($0) }
        
        dispatch_async(dispatch_get_main_queue()) {
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
}