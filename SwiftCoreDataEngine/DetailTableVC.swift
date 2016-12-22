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
    func dismissDetail (_ detail: DetailTableVC)
}

class DetailTableVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var game: Game? = nil {
        didSet{
            let request = NSFetchRequest<Player>(entityName: "Player")
            request.predicate = NSPredicate(format:"game = %@", game!)
            request.sortDescriptors = [NSSortDescriptor(key: "screenName", ascending: true)]
            self.players = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.sharedInstance.mainThreadContext!, sectionNameKeyPath: nil, cacheName: nil)
            self.players!.delegate = self
            try! players!.performFetch()
            
            let request2 = NSFetchRequest<Game>(entityName: "Game")
             request2.predicate = NSPredicate(format:"self = %@", game!)
            request2.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            self.gameListener = NSFetchedResultsController(fetchRequest: request2, managedObjectContext: CoreDataManager.sharedInstance.mainThreadContext!, sectionNameKeyPath: nil, cacheName: nil)
            self.gameListener!.delegate = self
            try! self.gameListener!.performFetch()
        }
    }
    
    private var players: NSFetchedResultsController<Player>?
    private var gameListener: NSFetchedResultsController<Game>?
    var delegate: DetailVCProtocol?
    
    // MARK: Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Players"
    }
    
    // MARK: Tableview
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.players!.fetchedObjects!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let player = self.players!.fetchedObjects![indexPath.row]
        cell.textLabel?.text = player.screenName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let player = self.players!.fetchedObjects![(indexPath as NSIndexPath).row]
        let objectId = player.objectID
        CoreDataManager.sharedInstance.coordinateWriting(identifier: "GameDelete") { (context) in
            do{
                let corresponding = try context.existingObject(with: objectId) as! Player
                context.delete(corresponding)
            } catch {
                print("Could not find corresponding Player object")
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func didPressAdd(_ sender: AnyObject) {
        let alert = UIAlertController(title: nil, message: "Add a player", preferredStyle: .alert)
        let add = UIAlertAction(title: "Add", style: .default) {(action) in
            CoreDataManager.sharedInstance.coordinateWriting(identifier: "InsertPlayer", block: { (context) in
                let input = alert.textFields![0].text
                if input != nil && !input!.isEmpty{
                    do{
                        let correspondingGame = try context.existingObject(with: self.game!.objectID) as! Game
                        let newPlayer = NSEntityDescription.insertNewObject(forEntityName: "Player", into: context) as! Player
                        newPlayer.screenName = input
                        newPlayer.game = correspondingGame
                    } catch {
                        print("Failed to retrieve corresponding Game record")
                    }
                }
            })
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(add)
        alert.addAction(cancel)
        alert.addTextField(configurationHandler: nil)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: FetchedResultsController protocol
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>){
        if controller === self.players {
            tableView.beginUpdates()
        }
    }
    
    
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
	                didChange anObject: Any,
	                at indexPath: IndexPath?,
	                for type: NSFetchedResultsChangeType,
	                newIndexPath: IndexPath?){
        if controller === self.players {
            switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .automatic)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .automatic)
            case .move:
                tableView.deleteRows(at: [indexPath!], with: .automatic)
                tableView.insertRows(at: [newIndexPath!], with: .automatic)
            default:
                break
            }
        } else if controller === self.gameListener && type == .delete {
            delegate?.dismissDetail(self)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>){
        if controller === self.players {
            tableView.endUpdates()
        }
    }
}
