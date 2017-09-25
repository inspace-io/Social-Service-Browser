//
//  SocialServiceBrowserOperationPerformable.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 22.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import Foundation

public protocol SocialServiceBrowserOperationPerformable: class {
    func cancel()
    func run()
}
