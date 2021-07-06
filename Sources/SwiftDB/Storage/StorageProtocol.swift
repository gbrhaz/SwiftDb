//
//  StorageProtocol.swift
//  SwiftDB
//

import Foundation

protocol IdentifiableStorageProtocol {
    func set<T>(object: T) throws where T: Persistable & Identifiable
    func get<T>(id: Int) throws -> T? where T: Persistable & Identifiable
}

protocol StorageProtocol {
    func getAll<T: Persistable>(ofType type: T.Type) throws -> [T]
    func set<T: Persistable>(objects: [T]) throws
}
