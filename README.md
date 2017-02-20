# multi-threaded-core-data
This is an example of a thread-safe, serialized, core data transaction pipeline supporting a purely data driven interface through the use of NSFetchedResultsControllers.

This project demonstrates  two things:

*	Threading in core data by using a hierarchy of contexts and propagating non blocking UI updates with FetchedResultsControllers.
*	Concurrency across threads, and how to throttle a high volume of concurrent, possibly conflictual core data transactions using a queue and dependencies.


The project features a simple drill-down navigation which allows to populate two levels of a data hierarchy:
Games -> Players.

The database transactions are dispatched off the main thread using the following APIs:

```
func coordinateWriting(identifier: String, block: @escaping (NSManagedObjectContext) -> Void)
```

and 

```
func coordinateReading(identifier: String, block: @escaping (NSManagedObjectContext) -> Void)
```


### Serializing conflictual operations
These APIs enqueue blocks into a private queue and enforces dependencies between “destructive” (write) operations and “non-destructive”(read) operations. The writes are not allowed to evaluate concurrently to any other type of operation, while the reads are allowed to evaluate concurrently with each other. 

### Hierarchy of contexts
This solution provides thread safety by spawning child contexts on demand. When a block is evaluated, it acquires a child context from the main thread context. Once the block has evaluated, and before the next operation starts, the changes are saved all the way up the context hierarchy, ensuring that the next operation’s context is not outdated. 

### Asynchronous UI updates using Fetched Results Controllers
All the tableviews are hooked into the main thread context with FetchedResultsControllers calibrated to the results of a query. Since all commits made in the background using the hierarchy of contexts are surfaced to disk through the main thread context, the FRC callbacks are invoked accordingly and update their respective tables at the row level. 

### Stress test:

For a bit of fun, and to illustrate the resilience of this pattern in the face of extreme data activity, the user can activate a loop which will continuously enqueue Read, Write and Delete operations by pressing the Play button.
