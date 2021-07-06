//
//  DataTransformer.swift
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
