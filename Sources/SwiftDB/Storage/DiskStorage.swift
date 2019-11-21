//
//  DiskStorage.swift
//  
//
//  Created by Harry Richardson on 21/11/2019.
//

import Foundation

/// Can be used for encrypting/decrypting data going onto disk
public class DataTransformer
{
    let setter: (Data) -> Data
    let getter: (Data) -> Data

    public init(setter: @escaping (Data) -> Data, getter: @escaping (Data) -> Data)
    {
        self.setter = setter
        self.getter = getter
    }
}

public struct DiskConfig {
    public let name: String
    public let maxSize: UInt
    public let directory: URL?
    public let dataTransformer: DataTransformer?

    #if os(iOS) || os(tvOS)
    public let fileProtection: FileProtectionType?

    public init(name: String, maxSize: UInt = 0, directory: URL? = nil, fileProtection: FileProtectionType? = nil, dataTransformer: DataTransformer? = nil)
    {
        self.name = name
        self.maxSize = maxSize
        self.directory = directory
        self.fileProtection = fileProtection
        self.dataTransformer = dataTransformer
    }
    #endif
}

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

    func fileUrl<T: Persistable>(for: T.Type, id: String) -> URL {
        return rootFolderUrl
            .appendingPathComponent(T.table)
            .appendingPathComponent(id)
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

    func get<T>(id: String) throws -> T? where T : Persistable {
        let filePath = fileUrl(for: T.self, id: id)
        var data = try Data(contentsOf: filePath)

        if let transformer = config.dataTransformer {
            data = transformer.getter(data)
        }

        let decoded = try JSONDecoder().decode(T.self, from: data)

        return decoded
    }

    func set<T>(object: T) throws where T : Persistable {
        var data = try JSONEncoder().encode(object)
        let filePath = fileUrl(for: T.self, id: object.id)

        if let transformer = config.dataTransformer {
            data = transformer.setter(data)
        }

        _ = fileManager.createFile(atPath: filePath.path, contents: data, attributes: nil)
        try fileManager.setAttributes([.modificationDate: NSDate()], ofItemAtPath: filePath.path)
    }
}
