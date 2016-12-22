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
	
    let games: NSFetchedResultsController<Game>
    
    // MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        let request = NSFetchRequest<Game>(entityName: "Game")
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games.fetchedObjects!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let game = games.fetchedObjects![indexPath.row]
        cell.textLabel?.text = game.name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let game = games.fetchedObjects![(indexPath as NSIndexPath).row]
        let objectId = game.objectID
        
        CoreDataManager.sharedInstance.coordinateWriting(identifier: "GameDelete") { (context) in
            
            do{
                
                let corresponding = try context.existingObject(with: objectId) as! Game
                context.delete(corresponding)
                
            } catch {
                
                print("Could not find corresponding Game object")
                
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let game = games.fetchedObjects![indexPath.row]
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let detailNav = sb.instantiateViewController(withIdentifier: "DetailNav") as! UINavigationController
        let detailVC = detailNav.viewControllers[0] as! DetailTableVC
        detailVC.game = game
        detailVC.delegate = self
        
        splitViewController?.showDetailViewController(detailNav, sender: self)
        
        
    }
    
    
    // MARK: Actions
    
    
    @IBAction func didPressPlus(_ sender: AnyObject) {
        
        
        let alert = UIAlertController(title: nil, message: "Add a game", preferredStyle: .alert)
        let add = UIAlertAction(title: "Add", style: .default) {(action) in
            
            CoreDataManager.sharedInstance.coordinateWriting(identifier: "InsertGame", block: { (context) in
                
                let input = alert.textFields![0].text
                
                if input != nil && !input!.isEmpty{
                    
                    let newGame = NSEntityDescription.insertNewObject(forEntityName: "Game", into: context) as! Game
                    newGame.name = input
                    
                }
                
            })
            
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(add)
        alert.addAction(cancel)
        alert.addTextField(configurationHandler: nil)
        present(alert, animated: true, completion: nil)
    }
    
    
    
	@IBAction func didPressPlay(_ sender: AnyObject) {
		
		CoreDataManager.sharedInstance.stressing = !CoreDataManager.sharedInstance.stressing
		
		DispatchQueue.global().async {
			CoreDataManager.sharedInstance.stressTest()
		}
		
    }
	
	
    // MARK: FetchedResultsController protocol
    
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>){
        

        
        tableView.beginUpdates()
        
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                                    at indexPath: IndexPath?,
                                                for type: NSFetchedResultsChangeType,
                                                              newIndexPath: IndexPath?){
        
        
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
        
        
        
        
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>){
        
      tableView.endUpdates()
        
    }

     // MARK: DetailVCProtocol protocol
    
    func dismissDetail (_ detail: DetailTableVC){
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let emptyVC = sb.instantiateViewController(withIdentifier: "EmptyVC")
        
        if splitViewController?.isCollapsed == true
        {
            _ = navigationController?.popToRootViewController(animated: true)
            
        } else {
            
            splitViewController?.showDetailViewController(emptyVC, sender: self)
        }

        
    }
    
    
}
