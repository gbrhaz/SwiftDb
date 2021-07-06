//
//  SwiftDB.swift
//  SwiftDB
//

/*
 TODO:

 - Binary encode BTree to not use JSON decoding/encoding for disk persistence
 - Set Schemas for types similarly to SQL(ite), creating tables
 - Allow keys other than Integers, set up Comparable/Hashable Key that can be implemented by a consumer
 - Set up indexes
 - Inserting/updating
 - Remove dependency on the BTree package, use custom implementation?
 */

import Foundation

public class SwiftDB {

    public struct Config {
        /// Used to uniquely identify multiple databases
        let name: String

        /// Provide an optional disk config to determine whether the database should be persisted to disk.
        /// If this config is not provided, the database will be stored only in memory. The name parameter has no
        /// effect on databases stored only in memory
        let diskConfig: DiskConfig?
    }

    typealias PersistableChangeClosure = () -> Void

    private(set) var observers = [String: [UUID: PersistableChangeClosure]]()

    private let schema: Schema
    private let config: Config

    private let memoryStorage: BTreeMemoryStorage
    private let diskStorage: DiskStorage?

    public init(schema: Schema, config: Config) throws {

        if let diskConfig = config.diskConfig {
            self.diskStorage = try DiskStorage(config: diskConfig)
        } else {
            self.diskStorage = nil
        }

        self.memoryStorage = BTreeMemoryStorage()
        self.schema = schema
        self.config = config
    }
}

extension SwiftDB: ObservableStorage {
    public func addObserver<T: Persistable>(on type: T.Type, closure: @escaping () -> Void) -> ObservationToken {

        let id = UUID()

        if observers[type.table] == nil {
            observers[type.table] = [:]
        }

        observers[type.table]?[id] = {
            closure()
        }

        return ObservationToken {
            [weak self] in
            self?.observers.removeValue(forKey: type.table)
        }
    }
}

extension SwiftDB: DatabaseProtocol {

    public func getAll<T: Persistable>(ofType type: T.Type) throws -> [T] {
        let memoryItems: [T] = try memoryStorage.getAll(ofType: type)

        if memoryItems.count > 0 {
            return memoryItems
        }

        if let disk = diskStorage {
            let diskItems: [T] = try disk.getAll(ofType: type)
            try memoryStorage.set(objects: diskItems)
            return diskItems
        }

        return []
    }

    public func get<T>(id: Int) throws -> T? where T: Persistable & Identifiable {
        if let item: T = try memoryStorage.get(id: id) {
            return item
        } else if let disk = diskStorage, let item: T = try disk.get(id: id) {
            try memoryStorage.set(object: item)
            return item
        }
        return nil
    }

    public func set<T: Persistable>(objects: [T]) throws {
        try memoryStorage.set(objects: objects)

        if let disk = diskStorage {
            try disk.set(objects: objects)
        }

        if let tableObservers = observers[T.table] {
            for observer in tableObservers {
                observer.value()
            }
        }
    }

    public func set<T>(object: T) throws where T: Persistable & Identifiable {
        try memoryStorage.set(object: object)

        if let disk = diskStorage {
            try disk.set(object: object)
        }

        if let tableObservers = observers[T.table] {
            for observer in tableObservers {
                observer.value()
            }
        }
    }
}
