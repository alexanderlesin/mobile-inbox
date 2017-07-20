//
//  OAuth2Client.swift
//  mobile-inbox
//
//  Created by Alexander Lesin on 7/20/17.
//  Copyright © 2017 Alexander Lesin. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class OAuth2Client: RestHelper, RestProtocol {
    let server: String!
    let clientId: String!
    let clientSecret: String!
    let isAuthInBody: Bool
    
    var authPath: String = "/idp/oauth2/token"
    var refreshPath: String = "/idp/oauth2/token"
    
    var accessToken: String?
    var refreshToken: String?
    var tokenType: String?
    var expiresIn: Int?
    var expirationTime: Date?
    
    init(id: String, secret: String, server: String, isAuthInBody: Bool = true) {
        self.server         = server
        clientId            = id
        clientSecret        = secret
        self.isAuthInBody   = isAuthInBody
    }
    
    init(id: String, secret: String, server: String, authAndRefreshPath: String, isAuthInBody: Bool = true) {
        self.server         = server
        clientId            = id
        clientSecret        = secret
        authPath            = authAndRefreshPath
        refreshPath         = authAndRefreshPath
        self.isAuthInBody   = isAuthInBody
    }
    
    init(id: String, secret: String, server: String, authPath: String, refreshPath: String, isAuthInBody: Bool = true)
    {
        self.server         = server
        clientId            = id
        clientSecret        = secret
        self.authPath       = authPath
        self.refreshPath    = refreshPath
        self.isAuthInBody   = isAuthInBody
    }
    
    func parseAccessTokenResponse(_ json: JSON?) throws {
        
        accessToken = json?["access_token"].string
        if accessToken == nil { throw RestError.invalidAccessToken }
        
        refreshToken = json?["refresh_token"].string
        if refreshToken == nil { throw RestError.invalidRefreshToken }
        
        tokenType = json?["token_type"].string
        if tokenType == nil || tokenType!.caseInsensitiveCompare("Bearer") != .orderedSame {
            throw RestError.invalidTokenType
        }
        
        expiresIn = json?["expires_in"].int
        if expiresIn != nil {
            expirationTime = Date().addingTimeInterval(Double(expiresIn!))
        } else {
            expirationTime = nil
        }
    }
    
    func addClientAuth(_ parameters: Parameters? = nil) -> Parameters? {
        var parameters = parameters
        if parameters != nil {
            parameters!["client_id"] = clientId
            parameters!["client_secrect"] = clientSecret
        } else {
            parameters = ["client_id": clientId, "client_secret": clientSecret]
        }
        return parameters
    }
    
    func addClientAuth(_ headers: HTTPHeaders? = nil) -> HTTPHeaders? {
        return headers
    }
    
    @discardableResult
    func getAccessToken(username: String, password: String, completionHandler: @escaping(RestResponse) -> Void) -> DataRequest {
        var parameters: Parameters? = ["grant_type": "password",
                                       "username": username,
                                       "password": password]
        var headers: HTTPHeaders? = nil
        if (isAuthInBody) {
            parameters = addClientAuth(parameters)
        } else {
            headers = addClientAuth(headers)
        }
        
        return RestHelper.restCall(server + authPath, method: .post, parameters: parameters) { r in
            var response = r
            if response.json != nil {
                do {
                    try self.parseAccessTokenResponse(response.json)
                } catch {
                    response.error = error
                }
                completionHandler(response)
            }
       }
    }
    
    @discardableResult
    func refreshAccessToken(completionHandler: @escaping (RestResponse) -> Void) -> DataRequest? {
        func checkRefreshTokenExists() throws {
            if refreshToken == nil { throw RestError.noRefreshToken }
        }
        
        do {
            try checkRefreshTokenExists()
        } catch {
            completionHandler(RestResponse(error: error))
            return nil
        }
        
        return RestHelper.restCall(server + refreshPath, method: .post, parameters: ["grant_type": "refresh_token", "refresh_token": refreshToken!]) { r in
            var response = r
            if response.json != nil {
                do {
                    try self.parseAccessTokenResponse(response.json)
                } catch {
                    response.error = error
                }
                completionHandler(response)
            }
        }
    }
    
    func refreshTokenIfNeeded(_ forceRefresh: Bool = false, completionHandler: @escaping () -> Void) {
        if(self.expirationTime != nil) {
            let currentTime = Date()
            if (currentTime >= self.expirationTime!) {
                refreshAccessToken() { _ in
                    completionHandler()
                }
            }
        }
        completionHandler()
    }
    
    func addAccessToken(_ parameters: Parameters? = nil) throws -> Parameters? {
        if accessToken == nil { throw RestError.noAccessToken }
        if accessToken != nil {
            if (parameters != nil) {
                var params = parameters
                params!["access_token"] = accessToken
                return params
            } else {
                return ["access_token": accessToken!]
            }
        }
        return parameters
    }
    
    // MARK: - RestProtocol
    func login(username: String, password: String, completionHandler: @escaping (RestResponse) -> Void) {
        getAccessToken(username: username, password: password, completionHandler: completionHandler)
    }
    
    func apiCall(_ path: String,
                 method: HTTPMethod = .get,
                 parameters: Parameters? = nil,
                 withRetryCount: Int = 2,
                 inBackground: Bool = false,
                 completionHandler: @escaping (RestResponse) -> Void) {
        func callWithRetryCount(parameters: Parameters?, count: Int) {
            refreshTokenIfNeeded (count != withRetryCount) { _ in
                RestHelper.restCall(self.server + path,
                                    method: method,
                                    parameters: parameters,
                                    sessionManager: inBackground ? self.backgroundSession : nil) { response in
                                        if response.error != nil || response.json == nil {
                                            if count > 1 {
                                                callWithRetryCount(parameters: parameters, count: count - 1)
                                            } else {
                                                completionHandler(response)
                                            }
                                        } else {
                                            completionHandler(response)
                                        }
                }
            }
        }
        
        do {
            try callWithRetryCount(parameters: addAccessToken(parameters), count: withRetryCount)
        } catch {
            completionHandler(RestResponse(error: error))
        }
    }
    
    func rawPostCall(_ path: String, body: String, withRetryCount: Int, completionHandler: @escaping (RestResponse) -> Void) {
        func callWithRetryCount(body: String, count: Int) {
            refreshTokenIfNeeded (count != withRetryCount){ _ in
                RestHelper.rawPostCall(self.server + path, body: body) { response in
                    if response.error != nil || response.json == nil {
                        if count > 1 {
                            callWithRetryCount(body: body, count: count - 1)
                        } else {
                            completionHandler(response)
                        }
                    } else {
                        completionHandler(response)
                    }
                }
            }
        }
        callWithRetryCount(body: body, count: withRetryCount)
    }
}
