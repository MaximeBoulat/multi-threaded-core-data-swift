//
//  MasterTableVC.swift
//  SwiftCoreDataEngine
//
//  Created by Max on 8/3/16.
//  Copyright © 2016 Max. All rights reserved.
//

import UIKit
import CoreData

class MasterTableVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    
    
    let games: NSFetchedResultsController
    
    
    // MARK: Lifecycle
    
    
    
    required init?(coder aDecoder: NSCoder) {
        
        let request = NSFetchRequest(entityName: "Game")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        games = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.sharedInstance.mainThreadContext!, sectionNameKeyPath: nil, cacheName: nil)
        
        
        try! games.performFetch()
        
        
        super.init(coder: aDecoder)
        
        games.delegate = self
        
        
        
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(insertNewGame(_:)))
        navigationItem.rightBarButtonItem = addButton
        
    }
    
    // MARK: Tableview
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.fetchedObjects!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let game = games.fetchedObjects![indexPath.row] as! Game
        cell.textLabel?.text = game.name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return .Delete
    }
    
    
    // MARK: Actions
    
    func insertNewGame(sender: AnyObject){
        
        let alert = UIAlertController(title: nil, message: "Add a game", preferredStyle: .Alert)
        let add = UIAlertAction(title: "Add", style: .Default) {(action) in
            
            CoreDataManager.sharedInstance.coordinateWriting(identifier: "InsertGame", block: { (context) in
                
                let input = alert.textFields![0].text
                
                if input != nil && !input!.isEmpty{
                    
                    let newGame = NSEntityDescription.insertNewObjectForEntityForName("Game", inManagedObjectContext: context) as! Game
                    newGame.name = input
                    
                }
                
            })
            
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alert.addAction(add)
        alert.addAction(cancel)
        alert.addTextFieldWithConfigurationHandler(nil)
        presentViewController(alert, animated: true, completion: nil)
        
        
    }
    
    // MARK: FetchedResultsController protocol
    
    
    
    func controllerWillChangeContent(controller: NSFetchedResultsController){
        
        tableView.beginUpdates()
        
    }
    
    
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                                    atIndexPath indexPath: NSIndexPath?,
                                                forChangeType type: NSFetchedResultsChangeType,
                                                              newIndexPath: NSIndexPath?){
        
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        default:
            break
        }
        
        
        
        
    }
    
    
    func controllerDidChangeContent(controller: NSFetchedResultsController){
        
      tableView.endUpdates()
        
    }
    
    
}
