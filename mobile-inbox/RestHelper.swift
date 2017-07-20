//
//  RestHelper.swift
//  mobile-inbox
//
//  Created by Alexander Lesin on 7/19/17.
//  Copyright © 2017 Alexander Lesin. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class RestHelper {
    
    // MARK: - Background session
    var _backgroundSession: SessionManager? = nil
    
    var backgroundSession: SessionManager {
        get {
            if _backgroundSession != nil {
                return _backgroundSession!
            } else {
                let bundleId = Bundle.main.bundleIdentifier ?? "com.openiam.mobile-inbox"
                let configuration = URLSessionConfiguration.background(withIdentifier: bundleId)
                _backgroundSession = Alamofire.SessionManager(configuration: configuration)
                if (_backgroundSession == nil) {
                    fatalError("can't get background SessionManager")
                    // TODO: ? _backgroundSession = Alamofire.SessionManager.default
                }
                return _backgroundSession!
            }
        }
    }
    
    // MARK: - destructor
    
    deinit {
        if (_backgroundSession != nil) {
            _backgroundSession?.session.finishTasksAndInvalidate()
        }
    }
    
    // MARK: - Rest helper functions
    
    static func checkForErrors(_ json: JSON?) throws {
        if json == nil { throw RestError.noData }
        
        if let err = json!["error"].string {
            throw RestError.errorInResponse(err: err,
                                            description: json!["error_description"].string ?? json!["message"].string)
        }
        
        if json!["error"].bool != nil {
            var exceptionError: String = "Unknown error"
            var exceptionMessage: String = ""
            if let errorList = json?["errorList"] {
                if let error = errorList["error"].string {
                    exceptionError = error
                }
                if let message = errorList["message"].string {
                    exceptionMessage = message
                }
            } else {
                throw RestError.errorInResponse(err: exceptionError,
                                                description: exceptionMessage)
            }
        }
    }
    
    @discardableResult
    static func restCall(_ url: String,
                         method: HTTPMethod = .post,
                         parameters: Parameters? = nil,
                         sessionManager: SessionManager? = nil, completionHandler: @escaping (RestResponse) -> Void) -> DataRequest {
        var sessionManager = sessionManager
        if sessionManager == nil {
            sessionManager = Alamofire.SessionManager.default
        }
        
        return sessionManager!.request(url,
                                       method: method,
                                       parameters: parameters).responseJSON { responseJson in
                                        var response = RestResponse(error: responseJson.error)
                                        
                                        if response.error != nil || responseJson.result.isFailure {
                                            completionHandler(response)
                                            return;
                                        }
                                        
                                        do {
                                            guard let value = responseJson.value else { throw RestError.noData }
                                            response.json = JSON(value)
                                            try self.checkForErrors(response.json)
                                        } catch {
                                            response.error = error
                                        }
                                        completionHandler(response)
        }
    }
    
    @discardableResult
    static func rawPostCall(_ url: String,
                            body: String,
                            completionHandler: @escaping (RestResponse) -> Void) -> DataRequest {
        
        return request(url,
                       method: .post,
                       parameters: [:],
                       encoding: body as! ParameterEncoding).responseJSON { responseJson in
                        var response = RestResponse(error: responseJson.error)
                        
                        if response.error != nil || responseJson.result.isFailure {
                            completionHandler(response)
                            return;
                        }
                        
                        do {
                            guard let value = responseJson.value else { throw RestError.noData }
                            response.json = JSON(value)
                            try self.checkForErrors(response.json)
                        } catch {
                            response.error = error
                        }
                        completionHandler(response)
        }
    }
    
}
