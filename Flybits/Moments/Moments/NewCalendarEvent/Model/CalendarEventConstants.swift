//
//  CalendarMoment.swift
//  Flybits
//
//  Created by Alex on 5/18/17.
//  Copyright © 2017 Flybits. All rights reserved.
//

import Foundation
import FlybitsSDK

class CalendarMoment: NSObject {
    
    struct APIConstants {
        static let eventsEndpoint            = "/events"
        static let locationsEndpoint         = APIConstants.eventsEndpoint + "/locations"
        static let calendarAttendeesEndpoint = "/users"
        
        struct Kernel {
            static let id              = "id"
            static let localizations   = "localizations"
            static let pagination      = "pagination"
        }
        
        struct Query {
            static let limit           = "limit"
            static let offset          = "offset"
            static let sortBy          = "sortBy"
            static let sortOrder       = "order"
        }
    }
}
