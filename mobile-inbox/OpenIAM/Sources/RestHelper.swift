//
//  RestHelper.swift
//  mobile-inbox
//
//  Created by Alexander Lesin on 7/22/17.
//  Copyright © 2017 Alexander Lesin. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class RestHelper {
    
    // MARK: - Members
    private static var _backgroundSession: SessionManager?
    var backgroundSession: SessionManager {
        get {
            if RestHelper._backgroundSession != nil {
                return RestHelper._backgroundSession!
            } else {
                let bundleId = Bundle.main.bundleIdentifier ?? "com.openiam.mobile-inbox"
                let configuration = URLSessionConfiguration.background(withIdentifier: bundleId)
                
                RestHelper._backgroundSession = Alamofire.SessionManager(configuration: configuration)
                if RestHelper._backgroundSession == nil {
                    fatalError("[OpenIAM]: Could not get background SessionManager")
                }
                return RestHelper._backgroundSession!
            }
        }
    }
    
    // MARK: - Rest Helper Functions
    @discardableResult
    static func restCall(_ url: String,
                         method: HTTPMethod = .post,
                         parameters: Parameters? = nil,
                         sessionManager: SessionManager? = nil,
                         completionHandler: @escaping (RestResponse) -> Void) -> DataRequest{
        var sessionManager = sessionManager
        
        if sessionManager == nil {
            sessionManager = Alamofire.SessionManager.default
        }
        
        return sessionManager!.request(url, method: method, parameters: parameters).responseJSON {
            responseJson in
            
            var response = RestResponse(error: responseJson.error)
            if response.error != nil || responseJson.result.isFailure {
                print("[OpenIAM RestCall]: Error occured while calling RestAPi")
                completionHandler(response)
                return;
            }
            
            do {
                guard let value = responseJson.value else {
                    throw RestError.noData
                }
                response.json = JSON(value)
                print("[OpenIAM RestCall]: Calling RestAPI is successfully finished")
                print("[OpenIAM RestCall]: Return Values from server")
                print(value)
            } catch {
                response.error = error
            }
            completionHandler(response)
        }
    }
}
