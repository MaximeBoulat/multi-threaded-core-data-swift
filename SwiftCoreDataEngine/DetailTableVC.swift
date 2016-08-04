//
//  DetailTableVC.swift
//  SwiftCoreDataEngine
//
//  Created by Max on 8/3/16.
//  Copyright © 2016 Max. All rights reserved.
//

import UIKit
import CoreData


protocol DetailVCProtocol {
    
    func dismissDetail (detail: DetailTableVC)
    
}


class DetailTableVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    
    var game: Game? = nil {
        
        didSet{
            
            var request = NSFetchRequest(entityName: "Player")
            request.predicate = NSPredicate(format:"game = %@", game!)
            request.sortDescriptors = [NSSortDescriptor(key: "screenName", ascending: true)]
            players = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.sharedInstance.mainThreadContext!, sectionNameKeyPath: nil, cacheName: nil)
            players!.delegate = self
            try! players!.performFetch()
            
            request = NSFetchRequest(entityName: "Game")
             request.predicate = NSPredicate(format:"self = %@", game!)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            gameListener = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.sharedInstance.mainThreadContext!, sectionNameKeyPath: nil, cacheName: nil)
            gameListener!.delegate = self
            try! gameListener!.performFetch()
            
        }
        
    }
    
    private var players: NSFetchedResultsController? = nil
    private var gameListener: NSFetchedResultsController? = nil
    var delegate: DetailVCProtocol?
    
    
    // MARK: Lifecycle
    
    
    override func viewDidLoad() {
        
        
        super.viewDidLoad()

        title = "Games"
        
        
    }
    
    // MARK: Tableview
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players!.fetchedObjects!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let player = players!.fetchedObjects![indexPath.row] as! Player
        cell.textLabel?.text = player.screenName
        
        return cell
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return .Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let player = players!.fetchedObjects![indexPath.row]
        let objectId = player.objectID
        
        CoreDataManager.sharedInstance.coordinateWriting(identifier: "GameDelete") { (context) in
            
            do{
                
                let corresponding = try context.existingObjectWithID(objectId) as! Player
                context.deleteObject(corresponding)
                
            } catch {
                
                print("Could not find corresponding Player object")
                
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func didPressAdd(sender: AnyObject) {
        
        let alert = UIAlertController(title: nil, message: "Add a player", preferredStyle: .Alert)
        let add = UIAlertAction(title: "Add", style: .Default) {(action) in
            
            CoreDataManager.sharedInstance.coordinateWriting(identifier: "InsertPlayer", block: { (context) in
                
                let input = alert.textFields![0].text
                
                if input != nil && !input!.isEmpty{
                    
                    do{
                        let correspondingGame = try context.existingObjectWithID(self.game!.objectID) as! Game
                        
                        let newPlayer = NSEntityDescription.insertNewObjectForEntityForName("Player", inManagedObjectContext: context) as! Player
                        newPlayer.screenName = input
                        newPlayer.game = correspondingGame
                        
                    } catch {
                        
                        print("Failed to retrieve corresponding Game record")
                        
                    }
                    
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
        
        if controller === players {
            tableView.beginUpdates()
        }
        
    }
    
    
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                                    atIndexPath indexPath: NSIndexPath?,
                                                forChangeType type: NSFetchedResultsChangeType,
                                                              newIndexPath: NSIndexPath?){
        
        
        if controller === players {
            
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
            
        } else if controller === gameListener && type == .Delete {
            
            delegate?.dismissDetail(self)
            
        }
        
        
        
    }
    
    
    func controllerDidChangeContent(controller: NSFetchedResultsController){
        
        if controller === players {
            
            tableView.endUpdates()
            
        }
        
    }
    
    
    
}
