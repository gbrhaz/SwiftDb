//
//  DiskStorage.swift
//

import Foundation

// Remove dependency on JSON encoding and move to BTrees with binary encoding
class DiskStorage {
    private let config: DiskConfig
    private let rootFolderUrl: URL
    private let fileManager: FileManager = .default

    init(config: DiskConfig) throws {
        self.config = config

        let url: URL
        if let directory = config.directory {
            url = directory
        } else {
            url = try fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }

        self.rootFolderUrl = url.appendingPathComponent(config.name, isDirectory: true)

        try createDirectoryIfNeeded(folderUrl: rootFolderUrl)
        try applyAttributesIfAny(folderUrl: rootFolderUrl)
    }
}

extension DiskStorage {
    func createDirectoryIfNeeded(folderUrl: URL) throws {
        guard !fileManager.fileExists(atPath: folderUrl.path) else {
            return
        }

        try fileManager.createDirectory(
            atPath: folderUrl.path,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    func applyAttributesIfAny(folderUrl: URL) throws {
        #if os(iOS) || os(tvOS)
        if let fileProtection = config.fileProtection {
            let attributes: [FileAttributeKey: Any] = [
                FileAttributeKey.protectionKey: fileProtection
            ]

            try fileManager.setAttributes(attributes, ofItemAtPath: folderUrl.path)
        }
        #endif
    }

    func fileUrl<T: Persistable>(for type: T.Type, id: Int) -> URL {
        return tableDirectory(for: type).appendingPathComponent("\(id)")
    }

    func tableDirectory<T: Persistable>(for: T.Type) -> URL {
        return rootFolderUrl.appendingPathComponent(T.table)
    }

    /// Calculates total disk cache size.
    func totalSize() throws -> UInt64 {
        var size: UInt64 = 0
        let contents = try fileManager.contentsOfDirectory(atPath: rootFolderUrl.path)
        for pathComponent in contents {
            let filePath = NSString(string: rootFolderUrl.path).appendingPathComponent(pathComponent)
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            if let fileSize = attributes[.size] as? UInt64 {
                size += fileSize
            }
        }

        return size
    }
}

extension DiskStorage: StorageProtocol {
    func set<T: Persistable>(objects: [T]) throws {
        var data = try JSONEncoder().encode(objects)
        let filePath = fileUrl(for: T.self, id: 0)

        if let transformer = config.dataTransformer {
            data = transformer.setter(data)
        }

        try createDirectoryIfNeeded(folderUrl: tableDirectory(for: T.self))
        _ = fileManager.createFile(atPath: filePath.path, contents: data, attributes: nil)
        try fileManager.setAttributes([.modificationDate: NSDate()], ofItemAtPath: filePath.path)
    }

    func getAll<T: Persistable>(ofType type: T.Type) throws -> [T] {
        let filePath = fileUrl(for: T.self, id: 0)

        guard fileManager.fileExists(atPath: filePath.path) else { return [] }

        var data = try Data(contentsOf: filePath)

        if let transformer = config.dataTransformer {
            data = transformer.getter(data)
        }

        let decoded = try JSONDecoder().decode([T].self, from: data)
        return decoded
    }
}

extension DiskStorage: IdentifiableStorageProtocol {
    func get<T>(id: Int) throws -> T? where T: Persistable & Identifiable {
        let filePath = fileUrl(for: T.self, id: id)
        var data = try Data(contentsOf: filePath)

        if let transformer = config.dataTransformer {
            data = transformer.getter(data)
        }

        let decoded = try JSONDecoder().decode(T.self, from: data)

        return decoded
    }

    func set<T>(object: T) throws where T: Persistable & Identifiable {
        var data = try JSONEncoder().encode(object)
        let filePath = fileUrl(for: T.self, id: object.id)

        if let transformer = config.dataTransformer {
            data = transformer.setter(data)
        }

        try createDirectoryIfNeeded(folderUrl: tableDirectory(for: T.self))
        _ = fileManager.createFile(atPath: filePath.path, contents: data, attributes: nil)
        try fileManager.setAttributes([.modificationDate: NSDate()], ofItemAtPath: filePath.path)
    }

}
