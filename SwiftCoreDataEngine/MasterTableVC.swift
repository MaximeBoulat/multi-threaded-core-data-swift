//
//  MasterTableVC.swift
//  SwiftCoreDataEngine
//
//  Created by Max on 8/3/16.
//  Copyright © 2016 Max. All rights reserved.
//

import UIKit
import CoreData

class MasterTableVC: UITableViewController, NSFetchedResultsControllerDelegate, DetailVCProtocol {
    
    
    
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
        title = "Games"
        
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
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let game = games.fetchedObjects![indexPath.row]
        let objectId = game.objectID
        
        CoreDataManager.sharedInstance.coordinateWriting(identifier: "GameDelete") { (context) in
            
            do{
                
                let corresponding = try context.existingObjectWithID(objectId) as! Game
                context.deleteObject(corresponding)
                
            } catch {
                
                print("Could not find corresponding Game object")
                
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let game = games.fetchedObjects![indexPath.row] as! Game
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let detailNav = sb.instantiateViewControllerWithIdentifier("DetailNav") as! UINavigationController
        let detailVC = detailNav.viewControllers[0] as! DetailTableVC
        detailVC.game = game
        detailVC.delegate = self
        
        splitViewController?.showDetailViewController(detailNav, sender: self)
        
        
    }
    
    
    // MARK: Actions
    
    
    @IBAction func didPressPlus(sender: AnyObject) {
        
        
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
    
    
    
    @IBAction func didPressPlay(sender: AnyObject) {
        
        CoreDataManager.sharedInstance.stressing = !CoreDataManager.sharedInstance.stressing
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            CoreDataManager.sharedInstance.stressTest()
        }
        
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

     // MARK: DetailVCProtocol protocol
    
    func dismissDetail (detail: DetailTableVC){
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let emptyVC = sb.instantiateViewControllerWithIdentifier("EmptyVC")
        
        if splitViewController?.collapsed == true
        {
            navigationController?.popToRootViewControllerAnimated(true)
            
        } else {
            
            splitViewController?.showDetailViewController(emptyVC, sender: self)
        }

        
    }
    
    
}
