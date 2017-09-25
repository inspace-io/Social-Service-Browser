//
//  SocialServiceBrowerNodeListResponse.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 22.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import Foundation

@objc public protocol SocialServiceBrowerNode {
    var nodeId: String? { get }
    var isDirectory: Bool { get }
    var nodeName: String { get }
    var path: String? { get }
}

public protocol SocialServiceBrowerNodeListResponse {
    var nodes: [SocialServiceBrowerNode] { get }
    var hasMoreResults: Bool { get }
    var nextCursorPath: String? { get }
}
