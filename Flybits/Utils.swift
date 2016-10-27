//
//  Utils.swift
//  Flybits
//
//  Created by Terry Latanville on 2015-10-30.
//  Copyright © 2015 Flybits. All rights reserved.
//

import FlybitsSDK

open class Utils {
    static func parseListFromRawList<T: ResponseObjectSerializable>(_ response: HTTPURLResponse, rawList: [AnyObject]?) -> [T] {
        var list = [T]()
        guard let rawList = rawList else {
            return list
        }
        
        for entry in rawList {
            if let templistEntry = try? T(response: response, representation: entry), let listEntry = templistEntry {
                list.append(listEntry)
            } else {
                print("Unable to parse: \(entry) into \(T.self)")
            }
        }
        return list
    }
    
    struct ErrorChecker {
        static func isExceptionType(_ type:String, error:NSError) -> Bool {
            guard let flybitsError = FlybitsError(error) else {
                return false
            }
            return flybitsError.exceptionType == type
        }
        
        static func isAccessDenied(_ error: NSError?) -> Bool {
            // com.flybits.request && code == 0
            guard let error = error else {
                return false
            }
            guard error.domain == FlybitsErrorDomain(NetworkingRequestError.Domain) && error.code ==  NetworkingRequestError.unableToParseResponse.rawValue else {
                return false
            }
            return isExceptionType(Const.FBSDK.ExceptionType.AccessDenied, error: error) || isExceptionType("FlybitsCore.Exceptions.AccessDeniedException", error: error)
        }
        
        static func noInternetConnection(_ error: NSError?) -> Bool {
            return error?.domain == NSURLErrorDomain && error?.code ==  NSURLErrorNotConnectedToInternet
        }
        
        static func FlybitsError(_ error:NSError) -> (exceptionTime:String, exceptionType:String, exceptionMessage:String?, details:[[String:AnyObject]]?)? {
            var returnType:(exceptionTime:String, exceptionType:String, exceptionMessage:String?, details:[[String:AnyObject]]?)? = nil
            
            let flybitserror:(_ dict:[String:AnyObject])->Void = { (dict) in
                returnType = (
                    exceptionTime: dict["dateTime"] as? String ?? "",
                    exceptionType: dict[Const.FBSDK.ExceptionKey.ExceptionType] as? String ?? "",
                    exceptionMessage: dict[Const.FBSDK.ExceptionKey.ExceptionMessage] as? String,
                    details: dict[Const.FBSDK.ExceptionKey.Details] as? [[String:AnyObject]]
                )
            }
            
            // contains NSData
            if let obj = error.userInfo[NSLocalizedDescriptionKey] as? NSData,
                let errorJsonString = String(data: obj as Data, encoding: String.Encoding.utf8),
                let errorJsonData = errorJsonString.data(using: String.Encoding.utf8),
                let errorJsonDict = try? JSONSerialization.jsonObject(with: errorJsonData, options: JSONSerialization.ReadingOptions.mutableContainers),
                let dict = errorJsonDict as? [String:AnyObject] {
                    
                    flybitserror(dict)
                    
            // contains Dictionary
            } else if let errorJsonDict = error.userInfo[NSLocalizedDescriptionKey] as? NSDictionary as? [String:AnyObject] {
                
                flybitserror(errorJsonDict)
                
            // contains String
            } else if let obj = error.userInfo[NSLocalizedDescriptionKey] as? String,
                let dataObj = obj.data(using: String.Encoding.utf8),
                let errorJsonString = String(data: dataObj, encoding: String.Encoding.utf8),
                let errorJsonData = errorJsonString.data(using: String.Encoding.utf8),
                let errorJsonDict = try? JSONSerialization.jsonObject(with: errorJsonData, options: JSONSerialization.ReadingOptions.mutableContainers),
                let dict = errorJsonDict as? [String:AnyObject] {
                    
                    flybitserror(dict)
                    
            } else if let errorJsonData = error.localizedDescription.data(using: String.Encoding.utf8),
                let dict = try? JSONSerialization.jsonObject(with: errorJsonData, options: JSONSerialization.ReadingOptions.mutableContainers),
                let errorJsonDict = dict as? [String:AnyObject] {
                    
                    flybitserror(errorJsonDict)
            }
            
            return returnType
        }
        
        static func formatError(_ error:NSError)-> NSError {
            var returningError: NSError = error
            guard error.userInfo[Const.FBSDK.ExceptionKey.FormattedError] == nil else {
                return returningError
            }
            
            if let flyerror = FlybitsError(error) {
                var userInfo:[String:AnyObject] = [
                    NSLocalizedDescriptionKey: flyerror.exceptionMessage as AnyObject? ?? error.localizedDescription as AnyObject,
                    Const.FBSDK.ExceptionKey.FormattedError: 1 as AnyObject
                ]
                if let details = flyerror.details {
                    userInfo[Const.FBSDK.ExceptionKey.Details] = details as AnyObject?
                }
                if flyerror.exceptionType.isEmpty == false {
                    userInfo[Const.FBSDK.ExceptionKey.ExceptionType] = flyerror.exceptionType as AnyObject?
                }
                if let message = flyerror.exceptionMessage {
                    userInfo[Const.FBSDK.ExceptionKey.ExceptionType] = message as AnyObject?
                }
                let e = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
                returningError = e
            } else {
                return returningError
            }
            return returningError
        }
    }
    
    struct UI {
        static func takeUserToLoginPage() {
            OperationQueue.main.addOperation {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Const.App.NotificationKey.Logout), object: nil)
            }
        }
        
        static func presentLogoutUI(_ dimmedViewFrame: CGRect, controller: UIViewController) {
            let dimmedLoadingView = LoadingView(frame: dimmedViewFrame)
            dimmedLoadingView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
            
            let ask = UIAlertController(title: "Are you sure you want to logout?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
            ask.addAction(UIAlertAction(title: "Logout", style: UIAlertActionStyle.destructive, handler: { [weak controller](e) -> Void in
                controller?.view.addSubview(dimmedLoadingView)
                _ = SessionRequest.logout { (success, error) -> Void in
                    OperationQueue.main.addOperation {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Const.App.NotificationKey.Logout), object: nil)
                        dimmedLoadingView.removeFromSuperview()
                    }
                    }.execute()
                }))
            
            ask.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { (e) -> Void in
                ask.dismiss(animated: true, completion: nil)
            }))
            controller.present(ask, animated: true, completion: nil)
        }
    }
    
    struct Formatter {
        static func ZoneDistance(_ distance: Float) -> String {
            if (distance < 1000) {
                return  NSString(format: "%.1f m", distance) as String
            } else if distance < (100000.0) {
                return  NSString(format: "%.0f km", distance/1000.0) as String
            } else {
                return  NSString(format: "%.0fK km", distance/(1000.0 * 1000.0)) as String
            }
        }
    }
    
    static func buildVersionString() -> String {
        var versionString = ""
        let dict = Bundle.main.infoDictionary
        if let short = dict?["CFBundleShortVersionString"] as? String {
            versionString.append(short)
        } else {
            versionString.append("-")
        }
        
        versionString.append(" #")
        if let short = dict?["CFBundleVersion"] as? NSObject {
            versionString.append(short.description)
        } else {
            versionString.append("-")
        }
        return versionString
    }
    
    static func buildInternalVersion() -> Int {
        let dict = Bundle.main.infoDictionary
        if let short = dict?["CFBundleVersion"] as? String {
            return Int(short)!
        } else {
            return -1
        }
    }
}

