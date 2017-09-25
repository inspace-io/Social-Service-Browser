//
//  SocialServiceBrowserResult.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 22.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import Foundation

public enum SocialServiceBrowserResult<Value, Error> {
    case success(Value)
    case failure(Error)

    /// Returns `true` if the result is a success, `false` otherwise.
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// Returns `true` if the result is a failure, `false` otherwise.
    var isFailure: Bool {
        return !isSuccess
    }
    
    /// Returns the associated value if the result is a success, `nil` otherwise.
    var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
