//
//  Extensions.swift
//  WebbCompanionTests
//
//  Created by Jeffrey Song on 2024-02-23.
//
import CloudKit
import CoreData
import Foundation

extension ApplicationDataStack {
    func removeAllContainers() throws {
        for i in persistentContainer.persistentStoreCoordinator.persistentStores {
            try persistentContainer.persistentStoreCoordinator.remove(i)
        }
    }
}
