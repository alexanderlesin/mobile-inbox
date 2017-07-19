//
//  RestProtocol.swift
//  mobile-inbox
//
//  Created by Alexander Lesin on 7/19/17.
//  Copyright © 2017 Alexander Lesin. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

enum RestError: Error {
    case noData
    case noRefreshToken
    case invalidAccessToken
    case invalidRefreshToken
    case invalidTokenType
    case errorInResponse(err: String, description: String?)
}

struct RestResponse {
    var error: Error? = nil
    var json: JSON? = nil
    
    init(error: Error?) {
        self.error = error
    }
}

protocol RestProtocol {
    func login (username: String,
                password: String,
                completionHandler: @escaping (RestResponse) -> Void)
    
    func apiCall(_ path: String,
                 method: HTTPMethod,
                 parameters: Parameters?,
                 withRetryCount: Int,
                 inBackground: Bool,
                 completionHandler: @escaping (RestResponse) -> Void)
    func rawPostCall(_ path: String,
                     body: String,
                     withRetryCount: Int,
                     completionHandler: @escaping (RestResponse) -> Void)
}
