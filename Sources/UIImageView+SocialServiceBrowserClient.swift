//
//  UIImageView+SocialServiceBrowserClient.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 27.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import UIKit

private var imageOperationKey: Void?

extension DispatchQueue {
    // This method will dispatch the `block` to self.
    // If `self` is the main queue, and current thread is main thread, the block
    // will be invoked immediately instead of being dispatched.
    func safeAsync(_ block: @escaping () -> Void) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
}

extension UIImageView {
    @discardableResult func setThumbnailImage(with client: SocialServiceBrowserClient, for node: SocialServiceBrowerNode, completionHandler: ((UIImage?, Error?) -> Void)?) -> SocialServiceBrowserOperationPerformable? {
        
        imageOperation?.cancel()
        setImageOperation(nil)
        
        var operation: SocialServiceBrowserOperationPerformable?
        
        operation = client.requestThumbnail(for: node, withCompletion: { [weak self] result in
            DispatchQueue.main.safeAsync {
                guard let strongSelf = self else {
                    completionHandler?(result.value, result.error)
                    return
                }
                strongSelf.image = result.value
                strongSelf.setImageOperation(nil)
                completionHandler?(result.value, result.error)
            }
        })
        
        setImageOperation(operation)
        operation?.run()
        return operation
    }
    
    fileprivate var imageOperation: SocialServiceBrowserOperationPerformable? {
        return objc_getAssociatedObject(self, &imageOperationKey) as? SocialServiceBrowserOperationPerformable
    }
    
    fileprivate func setImageOperation(_ operation: SocialServiceBrowserOperationPerformable?) {
        objc_setAssociatedObject(self, &imageOperationKey, operation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
