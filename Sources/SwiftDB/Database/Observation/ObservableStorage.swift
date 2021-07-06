//
//  ObservableStorage.swift
//  SwiftDB
//

import Foundation

public protocol ObservableStorage {
    func addObserver<T: Persistable>(on type: T.Type, closure: @escaping () -> Void) -> ObservationToken
}
