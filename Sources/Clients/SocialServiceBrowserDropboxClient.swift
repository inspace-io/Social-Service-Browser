//
//  SocialServiceBrowserDropboxClient.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 25.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import Foundation
import SwiftyDropbox
import Alamofire

#if IMPORT_SOCIAL_BROWSER_FRAMEWORK
import SocialServiceBrowserFramework
#endif

extension Alamofire.Request: SocialServiceBrowserOperationPerformable {
    public func run() {
        resume()
    }
}

private let globalDropboxOperationQueue = OperationQueue()

class DropboxBlockOperation: BlockOperation, SocialServiceBrowserOperationPerformable {
    public func run() {
        globalDropboxOperationQueue.addOperation(self)
    }
}

extension CallError: Error {
    
}

extension Files.Metadata: SocialServiceBrowerNode {
    public var nodeId: String? {
        if let file = self as? Files.FileMetadata {
            return file.id
        }
        if let folder = self as? Files.FolderMetadata {
            return folder.id
        }
        return nil
    }
    
    public var isImageFile: Bool {
        guard !isDirectory else {
            return false
        }
        if name.range(of: "\\.jpeg|\\.jpg|\\.JPEG|\\.JPG|\\.png|\\.PNG|\\.TIFF|\\.tiff", options: .regularExpression, range: nil, locale: nil) != nil {
            return true
        }
        return false
    }
    
    public var isVideoFile: Bool {
        guard !isDirectory else {
            return false
        }
        if name.range(of: "\\.mov|\\.mp4|\\.mpv|\\.3gp|\\.MOV|\\.MP4|\\.MPV|\\.3GP", options: .regularExpression, range: nil, locale: nil) != nil {
            return true
        }
        return false
    }

    public var isDirectory: Bool {
        return self is Files.FolderMetadata
    }
    
    public var nodeName: String {
        return name
    }
    
    public var path: String? {
        return pathLower
    }
}

private var filesAssociatedFilterObjectHandle: UInt8 = 0

extension Files.ListFolderResult: SocialServiceBrowerNodeListResponse {
    var filter: SocialServiceBrowserFilterType? {
        get {
            guard let filter = objc_getAssociatedObject(self, &filesAssociatedFilterObjectHandle) as? SocialServiceBrowserFilterType else {
                return nil
            }
            return filter
        }
        set {
            objc_setAssociatedObject(self, &filesAssociatedFilterObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var nodes: [SocialServiceBrowerNode] {
        guard let filter = filter else {
            return entries
        }
        switch filter {
            case .images: return entries.filter({ $0.isImageFile || $0.isDirectory })
            case .video: return entries.filter({ $0.isVideoFile || $0.isDirectory })
            default: return entries
        }
    }
    
    public var hasMoreResults: Bool {
        return hasMore
    }
    
    public var nextCursorPath: String? {
        return cursor
    }
}

extension DownloadRequestFile: SocialServiceBrowserOperationPerformable {
    public func run() {
        request.run()
    }
}

public class SocialServiceBrowserDropboxClient: SocialServiceBrowserClient {
    public var serviceName: String = "Dropbox"
    
    public var filter: SocialServiceBrowserFilterType = .none
    private var client: DropboxClient? {
        return DropboxClientsManager.authorizedClient
    }
    
    public init() {
        
    }
    
    public func requestRootNode(with completion: @escaping (SocialServiceBrowserResult<SocialServiceBrowerNodeListResponse, Error>) -> Void) -> SocialServiceBrowserOperationPerformable? {
        return client?.files.listFolder(path: "").response(completionHandler: { [weak self] response, error in
            if let error = error {
                completion(SocialServiceBrowserResult.failure(NSError(domain: "SocialServiceBrowserDropboxClientDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: error.description] as [String: Any])))
            } else if let response = response {
                response.filter = self?.filter
                completion(SocialServiceBrowserResult.success(response))
            } else {
                fatalError()
            }
        }).request
    }
    
    public func requestChildren(for node: SocialServiceBrowerNode, withCompletion completion: @escaping (SocialServiceBrowserResult<SocialServiceBrowerNodeListResponse, Error>) -> Void) -> SocialServiceBrowserOperationPerformable? {
        return client?.files.listFolder(path: node.path!).response(completionHandler: { [weak self] response, error in
            if let error = error {
                completion(SocialServiceBrowserResult.failure(error))
            } else if let response = response {
                response.filter = self?.filter
                completion(SocialServiceBrowserResult.success(response))
            } else {
                fatalError()
            }
        }).request
    }
    
    public func requestThumbnail(for node: SocialServiceBrowerNode, withCompletion completion: @escaping (SocialServiceBrowserResult<UIImage, Error>) -> Void) -> SocialServiceBrowserOperationPerformable? {
        let filePath = NSTemporaryDirectory().appending("/thumb_\(node.nodeName)")
        
        if let nodePath = node.path as NSString?, let image = UIImage(named: "page_white_\(nodePath.pathExtension)", in: Bundle(for: type(of: self)), compatibleWith: nil) {
            return DropboxBlockOperation {
                completion(SocialServiceBrowserResult.success(image))
            }
        }
        
        if !FileManager.default.fileExists(atPath: filePath) {
            return client?.files.getThumbnail(path: node.path!, format: .jpeg, size: .w128h128, overwrite: true, destination: { (_, _) -> URL in
                return URL(fileURLWithPath: filePath)
            }).response(completionHandler: { (metadata, error) in
                if let error = error,
                    case .routeError(let boxed, _, _, _) = error,
                    case .unsupportedExtension = boxed.unboxed {
                    
                    if let nodePath = node.path as NSString?, let image = UIImage(named: "page_white_\(nodePath.pathExtension)", in: Bundle(for: type(of: self)), compatibleWith: nil) {
                        DispatchQueue.global(qos: .background).async {
                            try? UIImagePNGRepresentation(image)?.write(to: URL(fileURLWithPath: filePath))
                        }
                        completion(SocialServiceBrowserResult.success(image))
                    } else {
                        let image = UIImage(named: "page_white_import", in: Bundle(for: type(of: self)), compatibleWith: nil)!
                        DispatchQueue.global(qos: .background).async {
                            try? UIImagePNGRepresentation(image)?.write(to: URL(fileURLWithPath: filePath))
                        }
                        completion(SocialServiceBrowserResult.success(image))
                    }
                    
                } else if let error = error {
                    completion(SocialServiceBrowserResult.failure(error))
                } else if let url = metadata?.1 {
                    DispatchQueue.global(qos: .background).async {
                        if let image = UIImage(contentsOfFile: url.path) {
                            DispatchQueue.main.async {
                                completion(SocialServiceBrowserResult.success(image))
                            }
                        } else {
                            DispatchQueue.main.async {
                            completion(SocialServiceBrowserResult.failure(NSError(domain: "SocialServiceBrowserDropboxClientDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to download image"] as [String: Any])))
                            }
                        }
                    }
                }
            }).request
        }
        
        return DropboxBlockOperation {
            let image = UIImage(contentsOfFile: filePath)
            if let image = image {
                completion(.success(image))
            } else {
                completion(.success(UIImage()))
            }
        }
    }
    
    public func requestData(for node: SocialServiceBrowerNode, withCompletion: @escaping (SocialServiceBrowserResult<URL, Error>) -> Void) -> SocialServiceBrowserOperationPerformable? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        guard let localPath = documentsPath?.appending("/\(node.nodeName)") else {
            return nil
        }
        
        guard !FileManager.default.fileExists(atPath: localPath) else {
            return DropboxBlockOperation {
                OperationQueue.main.addOperation {
                    withCompletion(SocialServiceBrowserResult.success(URL(fileURLWithPath: localPath)))
                }
            }
        }
        
        let downloadRequest = client?.files?.download(path: node.path!, rev: nil, overwrite: true, destination: { (_, _) -> URL in
            return URL(fileURLWithPath: localPath)
        }).response(completionHandler: { (url, error) in
            if let error = error {
                withCompletion(SocialServiceBrowserResult.failure(NSError(domain: "SocialServiceBrowserDropboxClientDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: error.description] as [String: Any])))
            } else if let url = url {
                withCompletion(SocialServiceBrowserResult.success(url.1))
            } else {
                fatalError()
            }
        })
        return downloadRequest
    }
    
}
