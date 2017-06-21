//
//  Protocols.swift
//  Flybits
//
//  Created by Alex on 5/18/17.
//  Copyright © 2017 Flybits. All rights reserved.
//

import Foundation

protocol DictionaryConvertible {
    func toDictionary() throws -> [String: AnyObject]
}
