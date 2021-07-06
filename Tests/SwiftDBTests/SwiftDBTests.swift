import XCTest
@testable import SwiftDB

struct User: Persistable, Equatable, Identifiable {
    var id: Int

    let name: String
}

final class SwiftDBTests: XCTestCase {

    private var schema: Schema!

    override func setUp() {
        super.setUp()

        schema = SchemaBuilder()
            .table(type: User.self)
            .build()

    }

    func testMultipleSetPerformance() {
        let count = 100
        let db = try! SwiftDB(schema: schema, config: .init(name: "Database", diskConfig: .init(name: "DiskConfig")))

        measure {
            for i in 0..<count {
                let user = User(id: i, name: "Harry")
                try! db.set(object: user)
            }
        }


        let fetched: [User] = try! db.getAll(ofType: User.self)

        XCTAssertEqual(fetched.count, count)
    }

    func testMemoryOnlyDatabase() {
        let db = try! SwiftDB(schema: schema, config: .init(name: "Database", diskConfig: nil))

        let user = User(id: 2, name: "Harry")
        try! db.set(object: user)

        let fetched: User? = try! db.get(id: user.id)

        XCTAssertEqual(fetched, user)
    }

//    func test_tree() {
//        let e = expectation(description: "")
//        let tree = TreeTest()
//        tree.bla()
//
//        waitForExpectations(timeout: 1.0, handler: nil)
//    }
}

//class TreeTest {
//
//    struct User: Persistable, Equatable {
//        var id: String
//        let name: String
//    }
//
//    struct Item: Persistable, Equatable {
//        var id: String
//        let section: Int
//        let price: Double
//    }
//
//    private var observer: ObservationToken?
//    private var view: View<Item>!
//
//    deinit {
//        observer?.cancel()
//    }
//
//    func bla() {
//        let schema = SchemaBuilder().build()
//        let db = try! SwiftDB(schema: schema, config: .init(name: "Database", diskConfig: nil))
//
//        view = View<Item>(db: db, grouping: {
//            $0.section
//        }, filter: {
//            return $0.price.truncatingRemainder(dividingBy: 2) == 0
//        }, sorting: {
//            return $0.price > $1.price
//        })
//        view.delegate = self
//
//        let item1 = Item(id: "1", section: 0, price: 124)
//        let item2 = Item(id: "2", section: 0, price: 542)
//        let item3 = Item(id: "3", section: 1, price: 656)
//        let item4 = Item(id: "4", section: 2, price: 666)
//
//        try! db.set(objects: [item1, item2, item3, item4])
//    }
//}
//
//extension TreeTest: ViewDelegate {
//    func update(changes: [ChangeNotification]) {
//        let sections = view.numberOfSections()
//        print("\(sections)")
//    }
//
//    func didUpdate() {
//        print("didUpdate")
//    }
//
//    func willUpdate() {
//        print("willUpdate")
//    }
//}
