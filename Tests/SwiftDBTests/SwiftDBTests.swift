import XCTest
@testable import SwiftDB

struct User: Persistable
{
    var id: String

    let name: String
}

final class SwiftDBTests: XCTestCase {
    func testExample() {
        let schema = SchemaBuilder()
            .table(type: User.self)
            .build()

        let disk = DiskConfig(name: "Disk")
        let db = try! SwiftDB(schema: schema, storageConfig: .disk(disk))

        let user = User(id: "1", name: "Harry")
        try! db.set(object: user)

        let fetched: User? = try! db.get(id: user.id)

        print(fetched)
//        let options = SwiftDB.Options()
//
//        let db = try! SwiftDB(schema: schema, options: options)
    }
}
