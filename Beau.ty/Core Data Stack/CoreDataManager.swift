//
//  CoreDataManager.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-11-26.
//

import Foundation
import Combine
import CoreData

class CoreDataManager: ObservableObject {
    
    static let shared = CoreDataManager()
    
    private init() {
        
    }
    
    @Published var failedUploadeds: [Int] = []   // array of orderID
    @Published var saveFailedUploadedError: CoreDataError?
    
    /// A persistent container to set up the Core Data stack.
    lazy var container: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "Beau_ty")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    /// Creates and configures a private queue context.
    private func newTaskContext() -> NSManagedObjectContext {
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        taskContext.automaticallyMergesChangesFromParent = true
        return taskContext
    }
    
    enum CoreDataError: Error {
        case saveFailedUploaded
        case fetch
    }
}
