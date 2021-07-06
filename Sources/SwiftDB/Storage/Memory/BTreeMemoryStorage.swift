//
//  BTreeMemoryStorage.swift
//  SwiftDB
//

import Foundation
import BTree

class BTreeMemoryStorage {
    typealias PersistableBTree = BTree<Int, Persistable>

    private var trees = [String: PersistableBTree]()
}

extension BTreeMemoryStorage: StorageProtocol {
    func getAll<T: Persistable>(ofType type: T.Type) throws -> [T] {
        guard let tree = trees[T.table] else {
            return []
        }
        return tree.compactMap { $0.1 as? T }
    }

    func set<T: Persistable>(objects: [T]) throws {
        if var tree = trees[T.table] {
            tree.insertOrReplace((0, objects), at: .first)
            trees[T.table] = tree
        } else {
            var newTree = PersistableBTree()
            newTree.insert((0, objects), at: .first)
            trees[T.table] = newTree
        }
    }
}

extension BTreeMemoryStorage: IdentifiableStorageProtocol {
    func get<T>(id: Int) throws -> T? where T: Persistable & Identifiable {
        guard let tree = trees[T.table] else {
            return nil
        }

        return tree.value(of: id) as? T
    }

    func set<T>(object: T) throws where T: Persistable & Identifiable {
        if var tree = trees[T.table] {
            tree.insertOrReplace((object.id, object), at: .first)
            trees[T.table] = tree
        } else {
            var newTree = PersistableBTree()
            newTree.insert((object.id, object), at: .first)
            trees[T.table] = newTree
        }
    }
}
