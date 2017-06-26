//
// CalendarEventConstants.swift
// Copyright (c) :YEAR: Flybits (http://flybits.com)
//
// Permission to use this codebase and all related and dependent interfaces
// are granted as bound by the licensing agreement between Flybits and
// :COMPANY_NAME: effective :EFFECTIVE_DATE:.
//
// Flybits Framework version :VERSION:
// Built: :BUILD_DATE:
//

import Foundation
import FlybitsSDK

class CalendarMoment: NSObject {
    
    struct APIConstants {
        static let eventsEndpoint            = "/events"
        static let locationsEndpoint         = "/locations"
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
