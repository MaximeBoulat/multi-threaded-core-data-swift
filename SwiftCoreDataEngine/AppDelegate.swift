//
//  AppDelegate.swift
//  SwiftCoreDataEngine
//
//  Created by Max on 8/3/16.
//  Copyright © 2016 Max. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    
    // MARK: - Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        
        splitViewController.preferredDisplayMode = .allVisible
        splitViewController.delegate = self
        
        
        _ = CoreDataManager.sharedInstance
        
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: - Split view
    
    // for collapsing
    
    //    func primaryViewControllerForCollapsingSplitViewController(splitViewController: UISplitViewController) -> UIViewController? {
    //
    //        return splitViewController.viewControllers[0]
    //
    //    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        
        //Return false to stop collapsing - i.e. let the split view controller try and incorporate the secondary view controller’s content into the collapsed interface
        //Return true to allow to collapse fully (do not try and incorporate detail in master)
        
        return true
    }
    
    
    
    // for expanding
    
    //    func primaryViewControllerForExpandingSplitViewController(splitViewController: UISplitViewController) -> UIViewController? {
    //
    //        return splitViewController.viewControllers[0]
    //    }
    
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        return nil
        
    }



}

