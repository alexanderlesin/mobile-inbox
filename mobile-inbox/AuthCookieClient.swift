//
//  AuthCookieClient.swift
//  mobile-inbox
//
//  Created by Evgeniy Sergeyev on 30/05/2017.
//  Copyright © 2017 OpenIAM. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class AuthCookieClient: RestHelper, RestProtocol {

    let server: String!
    var loginPath: String  = "/idp/login.html"
    var refreshPath: String = "/selfservice/myInfo.html"

    var timer: Timer?

    // MARK: - Initialization

    init(server: String!, loginPath: String? = nil, refreshPath: String? = nil) {
        self.server = server
        if loginPath != nil {
            self.loginPath = loginPath!
        }
        if refreshPath != nil {
            self.refreshPath = refreshPath!
        }
    }

    // MARK: - destructor

    deinit {
        stopTimer()
    }

    // MARK: - Refresh timer that should update auth cookie

    /// refresh often than 30 min expiration time interval allow to not reshedule
    /// refresh timer.
    func startTimer(_ interval: TimeInterval = 5*60) {
        if timer != nil {
            stopTimer()
        } else {
            timer = Timer.scheduledTimer(timeInterval: interval,
                                         target: self,
                                         selector: #selector(self.hitRefreshUrl),
                                         userInfo: nil,
                                         repeats: true)
        }
    }

    func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }

    @objc
    func hitRefreshUrl() {
        request(server + refreshPath, method: .get).response { _ in }
    }

    // MARK: - RestProtocol

    /// successful response:
    ///
    /// {
    ///     "passwordExpired" : false,
    ///     "successToken" : null,
    ///     "unlockURL" : null,
    ///     "userId" : "3000",
    ///     "error" : false,
    ///     "status" : 200,
    ///     "contextValues" : null,
    ///     "tokenInfo" : {
    ///         "timeToLiveSeconds" : -1,
    ///         "authToken" : "7FaJVRjUQF\/xoiGwBcmKEzffWuWv4abc+W4dvx7QJFlmLjJjxnu5tz9\/NqkZKHt4pp4LQYua6ij3M6x6VGU1qGEGvEraP34zkY+qeh4DNerMd\/d7D3rvF7DU+G0gvlTZ64GUHxUqdqJBI+1XbQKB1w=="
    ///     },
    ///     "errorList" : null,
    ///     "objectId" : null,
    ///     "possibleErrors" : null,
    ///     "successMessage" : null,
    ///     "redirectURL" : "\/selfservice"
    /// }

    func login(username: String,
               password: String,
               completionHandler: @escaping (RestResponse) -> Void) {
        let parameters: Parameters? = ["login": username,
                                       "password": password]
        RestHelper.restCall(server + loginPath,
                 method: .post,
                 parameters: parameters) { response in
                    if (response.error == nil) {
                        // everything ok here. shedule timer for update auth cookie
                        self.startTimer()
                    }

                    completionHandler(response)
        }
    }

    ///
    /// the same as restCall but check expiration time for accessToken
    /// and add access_token to request
    ///
    func apiCall(_ path: String,
                 method: HTTPMethod = .get,
                 parameters: Parameters? = nil,
                 withRetryCount: Int = 2,
                 inBackground: Bool = false,
                 completionHandler: @escaping (RestResponse) -> Void) {

        func callWithRetryCount(count: Int) {
            // force refresh on all calls except first one
            RestHelper.restCall(server + path,
                                method: method,
                                parameters: parameters,
                                sessionManager: inBackground ? backgroundSession : nil) { response in
                if response.error != nil  {
                    if ( count > 1) {
                        callWithRetryCount(count: count - 1)
                    } else {
                        completionHandler(RestResponse(error: response.error))
                    }
                } else {
                    completionHandler(response)
                }
            }
        }

        callWithRetryCount(count: withRetryCount)
    }

    ///
    /// the same as apiCall but send raw string instead of key value parameters list
    /// need AlamorifeEncodingExtention.swift
    ///
    func rawPostCall(_ path: String,
                     body: String,
                     withRetryCount: Int = 2,
                     completionHandler: @escaping (RestResponse) -> Void) {

        func callWithRetryCount(count: Int) {
            // force refresh on all calls except first one
            RestHelper.rawPostCall(server + path,
                                   body: body) { response in
                                    if response.error != nil  {
                                        if ( count > 1) {
                                            callWithRetryCount(count: count - 1)
                                        } else {
                                            completionHandler(RestResponse(error: response.error))
                                        }
                                    } else {
                                        completionHandler(response)
                                    }
            }
        }
        
        callWithRetryCount(count: withRetryCount)
    }

}
