//
//  File.swift
//  SwiftCoreDataEngine
//
//  Created by Max on 8/3/16.
//  Copyright © 2016 Max. All rights reserved.
//

import UIKit
import CoreData


class CoreDataManager{
    
    static let sharedInstance = CoreDataManager()
    var mainThreadContext: NSManagedObjectContext?
    var stressing = false
	
    lazy private var coreDataQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 20
        return queue
    }()
    
    enum TransactionType {
        case write
        case read
        case none
		
		var displayString: String{
			switch self{
			case .write:
				return "WRITE"
			case .read:
				return "READ"
			case .none:
				return "NONE"
			}
		}
    }
	
    class CoreDataOperation: BlockOperation {
        var type: TransactionType = .none
        var identifier: String = ""
    }
    
    // MARK: Lifecycle
    
    init() {
        print("CoreDataManager initializing")
//        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        self.mainThreadContext = self.persistentContainer.viewContext
		self.mainThreadContext?.automaticallyMergesChangesFromParent = true
		 

    }
	
	// MARK: Public
	
	func coordinateReading(identifier: String, block: @escaping (NSManagedObjectContext) -> Void){
		
		self.persistentContainer.performBackgroundTask { (context) in
			
			block(context)
			try! context.save()
			
		}
		
//		serializeTransaction(type: .read, identifier: identifier, block: block)
	}
	
	func coordinateWriting(identifier: String, block: @escaping (NSManagedObjectContext) -> Void){
		
		self.persistentContainer.performBackgroundTask { (context) in
			
			block(context)
			try! context.save()
			
		}
		
//		serializeTransaction(type: .write, identifier: identifier, block: block)
	}
	
    func stressTest() {
		
        enum OperationType: Int {
            case read = 0
            case write
            case delete
        }
        
        let readBlock: () -> Void = { [unowned self] in
			
            self.coordinateReading(identifier: "ReadBlock"){ (context) in
                let request = NSFetchRequest<Game>(entityName: "Game")
                let games = try! context.fetch(request)
                for item in games {
                    let game = item
                    _ = game.name
                }
            }
        }
        
        let writeBlock: () -> Void = { [unowned self] in
			
            self.coordinateWriting(identifier: "WriteBlock") { (context) in
                for _ in 0..<20 {
                    let newGame = NSEntityDescription.insertNewObject(forEntityName: "Game", into: context) as! Game
                    newGame.name = self.randomStringWithLength(8) as String
                }
            }
        }
        
        let deleteBlock: () -> Void = { [unowned self] in
			
            self.coordinateWriting(identifier: "DeleteBlock", block: { (context) in
                let request = NSFetchRequest<Game>(entityName: "Game")
                let results = try! context.fetch(request)
                let index = Int(arc4random_uniform(UInt32(results.count)))
                for i in 0..<index {
                    let game = results [i]
                    context.delete(game)
                }
            })
        }
		
        while self.stressing {
            switch OperationType(rawValue: Int(arc4random_uniform(3)))!{
            case .write:
                writeBlock()
            case .read:
				for _ in 0...4 {
                    readBlock()
                }
            case .delete:
                deleteBlock()
            }
			
			 Thread.sleep(forTimeInterval: 0.007)
			
        }
        self.coreDataQueue.cancelAllOperations()
    }
    
    // MARK: Private
    
    private func serializeTransaction (type: TransactionType, identifier: String, block: @escaping (NSManagedObjectContext) -> Void){
        
        let incoming = CoreDataOperation { [unowned self] in
            print("Operation of type: \(type.displayString) with identifier: \(identifier) starting!!!")
            // Get a background context for the calling thread
            let context = self.backgroundContext()
            // This is additional safety, enqueue the block on the context's internal queue (could be redundent)
            context.performAndWait{[unowned context] in
                // execute the block with the context as param
                block(context)
                // Attempt to save
                do{
                    try context.save()
                    /* This will pass on the changes to the parent context (main thread context), but we still need to save the main thread context to persist the changes to the DB */
                    let parentContext = context.parent!
                    context.parent?.performAndWait{ [unowned parentContext] in
                        do{
                            try parentContext.save()
                        } catch {
                            print("Error saving parent context for operation with identifier: \(identifier) and error: \(error)")
                        }
                    }
                }
                catch{
                    print("Error saving background context for operation with identifier: \(identifier) and error: \(error)")
                }
            }
            print("Operation of type: \(type.displayString) with identifier: \(identifier) ending!!!")
        }
        
        incoming.type = type;
        incoming.identifier = identifier
        
        /* Now lets enforce the dependencies. Read Operations must be serialized with Writes, Writes must be serialized with Reads and Writes */
        synced(self) { // Using a lock here because it is critical that no two incoming threads be evaluating the contents of the queue concurrently (basically serializing access to the queue)
            for item in self.coreDataQueue.operations  {
                let queued = item as! CoreDataOperation
                if incoming.type == .write {
                    incoming.addDependency(queued)
                } else {
					if queued.type == .write {
                        incoming.addDependency(queued)
                    }
                }
            }
			
            // Queue the operation
            self.coreDataQueue.addOperation(incoming)
        }
    }
    
    private func backgroundContext() -> NSManagedObjectContext{
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.mainThreadContext
        return context
    }
    
    // MARK: // Helpers
    
    private func synced(_ lock: AnyObject, closure: () -> ()) {
        defer { objc_sync_exit(lock) }
        objc_sync_enter(lock)
        closure()
    }
    
    private func randomStringWithLength (_ len : Int) -> NSString {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        for _ in 0..<len{
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        return randomString
    }
    
    // MARK: Boilerplate
    
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }() 
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        return coordinator
    }()
	
	
	
	// MARK: - Core Data stack
	
	lazy var persistentContainer: NSPersistentContainer = {
		/*
		The persistent container for the application. This implementation
		creates and returns a container, having loaded the store for the
		application to it. This property is optional since there are legitimate
		error conditions that could cause the creation of the store to fail.
		*/
		let container = NSPersistentContainer(name: "Model")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				
				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()
	
	// MARK: - Core Data Saving support
	
	func saveContext () {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
}



