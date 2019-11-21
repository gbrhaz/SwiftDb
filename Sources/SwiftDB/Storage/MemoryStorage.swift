//
//  File.swift
//  
//
//  Created by Harry Richardson on 21/11/2019.
//

import Foundation

public struct MemoryConfig {
    // Limits?
}

class MemoryStorage
{
//    private let cache: NSCache<String, AnyObject>

    init(config: MemoryConfig)
    {

    }
}

extension MemoryStorage: StorageProtocol {
    func get<T>(id: String) throws -> T? where T : Persistable {
        return nil
    }

    func set<T>(object: T) throws where T : Persistable {

    }
}
