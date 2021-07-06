import Foundation

public class ChangeNotification {

    public enum Change
    {
        case update
        case move
        case insert
        case delete
    }

    public let change: Change

    init(change: Change) {
        self.change = change
    }
}

protocol ViewDelegate: AnyObject {

    func willUpdate()
    func didUpdate()
    func update(changes: [ChangeNotification])
}

class View<T: Persistable> {

    typealias SortingClosure = (T, T) throws -> Bool
    typealias GroupingClosure = (T) throws -> Int
    typealias FilterClosure = (T) throws -> Bool

    weak var delegate: ViewDelegate? {
        didSet {
            dbUpdated()
        }
    }

    private var token: ObservationToken?
    private var mapping = [Int: [T]]()

    private unowned let db: DatabaseProtocol
    private let sorting: SortingClosure?
    private let grouping: GroupingClosure?
    private let filter: FilterClosure?

    public init(db: DatabaseProtocol, grouping: GroupingClosure?, filter: FilterClosure?, sorting: SortingClosure?) {

        self.db = db
        self.grouping = grouping
        self.filter = filter
        self.sorting = sorting

        self.token = self.db.addObserver(on: T.self) {
            [weak self] in
            self?.dbUpdated()
        }
    }

    deinit {
        token?.cancel()
    }

    private func dbUpdated() {
        delegate?.willUpdate()

        updateMapping()

        // TODO: CHANGE
        delegate?.update(changes: [.init(change: .update)])

        delegate?.didUpdate()
    }

    /// Run through, filtering -> sorting -> grouping the items so they can then be displayed
    // TODO Fix tries
    private func updateMapping() {
        var allItems = try! db.getAll(ofType: T.self)

        if let filter = filter {
            allItems = try! allItems.filter(filter)
        }
        if let sorting = sorting {
            try! allItems.sort(by: sorting)
        }
        if let grouping = grouping {
            mapping = try! Dictionary(grouping: allItems, by: grouping)
        } else {
            mapping = [0: allItems]
        }
    }

    public func numberOfSections() -> Int {
        return mapping.count
    }

    public func numberOfRows(inSection section: Int) -> Int {
        return mapping[section]?.count ?? 0
    }

    public func item(in section: Int, row: Int) -> T? {
        return mapping[section]?[row]
    }

}
