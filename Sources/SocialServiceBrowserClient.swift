//
//  SocialServiceBrowserClientable.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 22.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import Foundation
import UIKit

public enum SocialServiceBrowserFilterType {
    case none
    case images
    case video
    case custom(String)
}

public protocol SocialServiceBrowserClient {
    var serviceName: String { get }
    var filter: SocialServiceBrowserFilterType { get }
    
    func requestRootNode(with completion: @escaping (SocialServiceBrowserResult<SocialServiceBrowerNodeListResponse, Error>) -> Void) -> SocialServiceBrowserOperationPerformable?
    
    func requestChildren(`for` node: SocialServiceBrowerNode, withCompletion completion: @escaping (SocialServiceBrowserResult<SocialServiceBrowerNodeListResponse, Error>) -> Void) -> SocialServiceBrowserOperationPerformable?
    
    func requestThumbnail(`for` node: SocialServiceBrowerNode, withCompletion: @escaping (SocialServiceBrowserResult<UIImage, Error>) -> Void) -> SocialServiceBrowserOperationPerformable?
    
    func requestData(`for` node: SocialServiceBrowerNode, withCompletion: @escaping (SocialServiceBrowserResult<URL, Error>) -> Void) -> SocialServiceBrowserOperationPerformable?
}
