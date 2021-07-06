//
//  Schema.swift
//  
//

import Foundation

public struct Schema {
    let tables: [Table]
}

public struct Table {
    let name: String
}

public class TableSchemaBuilder {
    private let type: Persistable.Type

    init(forType type: Persistable.Type) {
        self.type = type
    }

    func build() -> Table {
        let name = String(describing: type)
        return Table(name: name)
    }
}

public class SchemaBuilder {
    private var tableBuilders = [TableSchemaBuilder]()

    public func table(type: Persistable.Type) -> SchemaBuilder {
        let tableSchema = TableSchemaBuilder(forType: type)
        tableBuilders.append(tableSchema)
        return self
    }

    func build() -> Schema {
        let tables = tableBuilders.map { $0.build() }
        return Schema(tables: tables)
    }
}
