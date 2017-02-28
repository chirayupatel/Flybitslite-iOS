//
//  ProprietaryDataProvider.swift
//  Flybits
//
//  Created by Chirayu Patel on 2017-02-25.
//  Copyright © 2017 Flybits. All rights reserved.
//

import Foundation
import FlybitsSDK

// ProprietaryDataProvider allows to create and send proprietary custom context data for evaluating context rules.
public class ProprietaryDataProvider: NSObject, ContextDataProvider {
    public let contextCategory: String = "ctx.sdk.demo"
    public var pollFrequency: Int32 = 60
    public var uploadFrequency: Int32 = 60
    public var priority: ContextDataPriority = .any

    public override init() {
        super.init()
    }

    // Initialize proprietary custom data
    public var mortgageExpiry = 20 // number of days
    public var persona = "Business" // persona value
    public var creditRating = 750 // credit rating

    public func refreshData(completion: @escaping (Any?, NSError?) -> Void) {
        // Build context data for rules evaluation
        let data : [String : AnyObject]? = [
            "mortgageExpiry" : mortgageExpiry as AnyObject,
            "persona" : persona as AnyObject,
            "creditRating" : creditRating as AnyObject
        ]
        guard let customData = data else {
            return
        }
//        print("### custom data fetch - \(customData)")
        completion(customData, nil)
    }
}

