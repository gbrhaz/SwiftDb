import Foundation

public enum Change
{
    case update
    case move
    case insert
    case delete
}

public protocol StorageProtocol {
    func set<T: Persistable>(object: T) throws
    func get<T: Persistable>(id: String) throws -> T?
}

public class SwiftDB {

    public enum StorageConfig
    {
        case memory(MemoryConfig)
        case disk(DiskConfig)
        case both(MemoryConfig, DiskConfig)
    }

    private enum Storage
    {
        case memory(MemoryStorage)
        case disk(DiskStorage)
        case both(MemoryStorage, DiskStorage)
    }

    private let schema: Schema
    private let storage: Storage

    public init(schema: Schema, storageConfig: StorageConfig) throws {

        switch storageConfig {
        case .both(let memoryConfig, let diskConfig):
            let memoryStorage = MemoryStorage(config: memoryConfig)
            let diskStorage = try DiskStorage(config: diskConfig)
            self.storage = .both(memoryStorage, diskStorage)
        case .disk(let diskConfig):
            let diskStorage = try DiskStorage(config: diskConfig)
            self.storage = .disk(diskStorage)
        case .memory(let memoryConfig):
            let memoryStorage = MemoryStorage(config: memoryConfig)
            self.storage = .memory(memoryStorage)
        }
        self.schema = schema


    }
}

extension SwiftDB: StorageProtocol {

    public func get<T>(id: String) throws -> T? where T : Persistable {

        switch storage {
        case .both(let memory, let disk):
            if let item: T = try memory.get(id: id) {
                return item
            } else if let item: T = try disk.get(id: id) {
                try memory.set(object: item)
                return item
            }
            return nil
        case .disk(let disk):
            return try disk.get(id: id)
        case .memory(let memory):
            return try memory.get(id: id)
        }
    }

    public func set<T>(object: T) throws where T : Persistable {
        switch storage {
        case .both(let memory, let disk):
            try memory.set(object: object)
            try disk.set(object: object)
        case .disk(let disk):
            try disk.set(object: object)
        case .memory(let memory):
            try memory.set(object: object)
        }
    }
}

// Store objects to memory, disk, or both
// Be able to hook Table/Collection views to changes to specific type
// B+ Tree

// OnSet:
// 1. Check if item/folder with Key exists
// 2. If exists, need to add .edit to changes
// 3. Set in memory
// 4. Set on disk

