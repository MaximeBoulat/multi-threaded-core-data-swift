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
    
    enum TransactionType: String {
        case Write = "WRITE"
        case Read = "READ"
        case None = "NONE"
    }
    
    
    class CoreDataOperation: NSBlockOperation{
        
        var type: TransactionType = .None
        var identifier: String = ""
        
        
    }
    
    
    static let sharedInstance = CoreDataManager()
    
    
    var mainThreadContext: NSManagedObjectContext?
    
    
    lazy private var coreDataQueue: NSOperationQueue = {
        
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 5
        return queue
        
    }()
    
    lazy private var stressQueue: NSOperationQueue = {
        
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 20
        return queue
        
    }()
    
    // MARK: Lifecycle
    
    init(){
        
        print("CoreDataManager initializing")
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        mainThreadContext = managedObjectContext
       
    }
    
    // MARK: Public
    
    
    func coordinateReading(identifier identifier: String, block: (NSManagedObjectContext) -> Void){
        
        serializeTransaction(type: .Read, identifier: identifier, block: block)
        
    }
    
    
    func coordinateWriting(identifier identifier: String, block: (NSManagedObjectContext) -> Void){
        
         serializeTransaction(type: .Write, identifier: identifier, block: block)
        
    }
    
    
    func stressTest (){
        
        
        enum OperationType: Int {
            case Read = 0
            case Write
            case Delete
 
        }
        
        
        let readBlock: () -> Void = { [unowned self] in
            
            self.coordinateReading(identifier: "ReadBlock"){ (context) in
                
                let request = NSFetchRequest(entityName: "Game")
                let games = try! context.executeFetchRequest(request)
                
                for item in games {
                    
                    let game = item as! Game
                     _ = game.name
                    
                }
                
            }
            
        }
        
        let writeBlock: () -> Void = { [unowned self] in
            
            self.coordinateWriting(identifier: "WriteBlock") { (context) in
                
                for _ in 0..<20 {
                    
                    let newGame = NSEntityDescription.insertNewObjectForEntityForName("Game", inManagedObjectContext: context) as! Game
                    newGame.name = self.randomStringWithLength(8) as String
                    
                    
                }
                
            }
        }
        
        let deleteBlock: () -> Void = { [unowned self] in
            
            
            self.coordinateWriting(identifier: "DeleteBlock", block: { (context) in
                
                let request = NSFetchRequest(entityName: "Game")
                let results = try! context.executeFetchRequest(request)
                let index = Int(arc4random_uniform(UInt32(results.count)))
                
                
                for i in 0..<index {
                    
                    let game = results [i] as! Game
                    context.deleteObject(game)
                }
                
                
            })
            
        }
        
        while true {
            
            let operation = NSBlockOperation(block: { 
                
                let operationType = OperationType(rawValue: Int(arc4random_uniform(3)))
                
                
                switch operationType!{
                    
                case .Write:
                    writeBlock()
                    
                case .Read:
                    
                    for _ in 0...4 {
                        
                        
                        readBlock()
                        
                        
                    }
                    

                    
                case .Delete:
                    
                    deleteBlock()
   
                    
                }
                
            })
            
            if stressQueue.operationCount < stressQueue.maxConcurrentOperationCount {
                stressQueue.addOperation(operation)
            }
            
            while stressQueue.operationCount > coreDataQueue.maxConcurrentOperationCount {
                NSThread.sleepForTimeInterval(0.5)
            }
            
        }
        
        
        
        
    }
    
    
    // MARK: Private
    
    private func serializeTransaction (type type: TransactionType, identifier: String, block: (NSManagedObjectContext) -> Void){
        
        
        let incoming = CoreDataOperation { [unowned self] in
            
            
            print("Operation of type: \(type.rawValue) with identifier: \(identifier) starting!!!")
            
            // Get a background context for the calling thread
            let context = self.backgroundContext()
            
            
            // This is additional safety, enqueue the block on the context's internal queue (could be redundent)
            context.performBlockAndWait{[unowned context] in
                
                
                
                // execute the block with the context as param
                block(context)
                
                
                // Attempt to save
                do{
                    try context.save()
                    
                    /*
                     
                     This will pass on the changes to the parent context (main thread context), but we still need to save the main thread context to persist the changes to the DB
                     
                     */
                    
                    let parentContext = context.parentContext!
                    
                    context.parentContext?.performBlockAndWait{ [unowned parentContext] in
                        
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
            
            print("Operation of type: \(type.rawValue) with identifier: \(identifier) ending!!!")
        }
        
        
        incoming.type = type;
        incoming.identifier = identifier
        
        /*
         Now lets enforce the dependencies. Read Operations must be serialized with Writes, Writes must be serialized with Reads and Writes
         */
        synced(self) { // Using a lock here because it is critical that no two incoming threads be evaluating the contents of the queue concurrently (basically serializing access to the queue)
            
            
            for item in self.coreDataQueue.operations  {
                
                let queued = item as! CoreDataOperation
                
               
                if incoming.type == .Write {
                    
                    incoming.addDependency(queued)
                    
                } else {
                    
                    if queued.type == .Write {
                    
                        incoming.addDependency(queued)
                    }
                    
                }
            }
            
            
            // Queue the operation
            
            self.coreDataQueue.addOperation(incoming)
            
        }
        
        
    }
    
    
    private func backgroundContext() -> NSManagedObjectContext{
        
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = mainThreadContext
        return context
        
    }
    
    // MARK: // Helpers
    
    private func synced(lock: AnyObject, closure: () -> ()) {
        
        defer { objc_sync_exit(lock) }
        objc_sync_enter(lock)
        closure()
    }
    
    
    
    
    private func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0..<len{
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
    
    // MARK: Boilerplate
    
    lazy var applicationDocumentsDirectory: NSURL = {

        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    

    
    
}



