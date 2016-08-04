//
//  MasterTableVC.swift
//  SwiftCoreDataEngine
//
//  Created by Max on 8/3/16.
//  Copyright © 2016 Max. All rights reserved.
//

import UIKit
import CoreData

class MasterTableVC: UITableViewController {
    
    
    
    let games: NSFetchedResultsController
    
    
    
    required init?(coder aDecoder: NSCoder) {
        
        
        games = NSFetchedResultsController()
        
        
        
        super.init(coder: aDecoder)
        
        
    
    }
    
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        
        return cell
    }
    
    
    
    

}
