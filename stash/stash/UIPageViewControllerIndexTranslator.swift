//
//  UIPageViewControllerIndexTranslator.swift
//  stash
//
//  Created by James Stidard on 10/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit

protocol UIPageViewControllerIndexTranslatorDelegate: class
{
    func numberOfPagesInPageViewController(pageViewController: UIPageViewController) -> Int
    func pageViewController(pageViewController: UIPageViewController, viewControllerAtIndex: Int) -> UIViewController?
}

class UIPageViewControllerIndexTranslator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    private weak var pendingPage: UIViewController?
    weak var currentPage:         UIViewController?
    weak var delegate:            UIPageViewControllerIndexTranslatorDelegate?
    var currentIndex:             Int = 0
    var wrap:                     Bool = true
    
    
    init(pageViewController pageVC: UIPageViewController, delegate: UIPageViewControllerIndexTranslatorDelegate, startingIndex index: Int, shouldWrap: Bool)
    {
        super.init()
        pageVC.delegate   = self
        pageVC.dataSource = self
        self.delegate     = delegate
        self.currentIndex = index
        self.wrap         = shouldWrap
        
//        assert(pageVC.spineLocation == .None,
//            "UIPageViewControllerIndexTranslator can't be used with PageVC's that present multiple ViewControllers at once")
    }
    
    convenience init(pageViewController pageVC: UIPageViewController, delegate: UIPageViewControllerIndexTranslatorDelegate)
    {
        self.init(pageViewController: pageVC, delegate: delegate, startingIndex: 0, shouldWrap: false)
    }
    
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject])
    {
        self.pendingPage = pendingViewControllers.first as? UIViewController
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool)
    {
        if completed {
            self.currentPage = self.pendingPage
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
        if self.currentIndex > 0
        {
            self.currentIndex--
            return self.delegate?.pageViewController(pageViewController, viewControllerAtIndex: self.currentIndex)
        }
        else if
            let   totalPages = self.delegate?.numberOfPagesInPageViewController(pageViewController)
            where self.wrap
        {
            self.currentIndex = totalPages - 1
            return self.delegate?.pageViewController(pageViewController, viewControllerAtIndex: self.currentIndex)
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
    {
        if
            let   totalPage = self.delegate?.numberOfPagesInPageViewController(pageViewController)
            where totalPage > self.currentIndex + 1
        {
            self.currentIndex++
            return self.delegate?.pageViewController(pageViewController, viewControllerAtIndex: self.currentIndex)
        }
        else if self.wrap
        {
            self.currentIndex = 0
            return self.delegate?.pageViewController(pageViewController, viewControllerAtIndex: self.currentIndex)
        }
        
        return nil
    }
}