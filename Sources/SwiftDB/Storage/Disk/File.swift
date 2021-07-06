//
//  File.swift
//  SwiftDB
//

import Foundation

public struct DiskConfig {
    public let name: String
    public let maxSize: UInt
    public let directory: URL?
    public let dataTransformer: DataTransformer?

    #if os(iOS) || os(tvOS)
    public let fileProtection: FileProtectionType?

    public init(name: String, maxSize: UInt = 0, directory: URL? = nil, fileProtection: FileProtectionType? = nil, dataTransformer: DataTransformer? = nil) {
        self.name = name
        self.maxSize = maxSize
        self.directory = directory
        self.fileProtection = fileProtection
        self.dataTransformer = dataTransformer
    }
    #else
    public init(name: String, maxSize: UInt = 0, directory: URL? = nil, dataTransformer: DataTransformer? = nil) {
        self.name = name
        self.maxSize = maxSize
        self.directory = directory
        self.dataTransformer = dataTransformer
    }
    #endif
}
