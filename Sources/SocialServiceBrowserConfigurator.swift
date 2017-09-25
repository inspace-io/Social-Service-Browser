//
//  SocialServiceBrowserConfigurator.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 27.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import UIKit

public enum SocialServiceBrowserSelectionMode {
    case select
    case download(maxSelectedItemsCount: Int)
    
    var maxSelectedItemsCount: Int {
        switch self {
        case .select: return 1
        case .download(let count): return count
        }
    }
}

public enum SocialServiceBrowserDisplayMode {
    case list
    case grid
}

public protocol SocialServiceBrowserViewControllerUIConfigurable {
    var displayMode: SocialServiceBrowserDisplayMode { get }
    
    var backBarButtonItem: UIBarButtonItem { get }
    var closeBarButtonItem: UIBarButtonItem { get }
    var importBarButtonItem: UIBarButtonItem { get }
    
    func registerCells(for collectionView: UICollectionView)
    func reusableIdentifierForCell(`in` displayMode: SocialServiceBrowserDisplayMode) -> String
    func reusableIdentifierForHeader(`in` displayMode: SocialServiceBrowserDisplayMode) -> String
}

extension SocialServiceBrowserViewControllerUIConfigurable {
    public var backBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
    }
    
    public var closeBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(title: "Close", style: .plain, target: nil, action: nil)
    }
    
    public var importBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(title: "Import", style: .plain, target: nil, action: nil)
    }
}

public protocol SocialServiceBrowserViewControllerConfigurable {
    var client: SocialServiceBrowserClient { get }
    var parentNode: SocialServiceBrowerNode? { get }
    var selectionMode: SocialServiceBrowserSelectionMode { get }
    
    func newConfiguration(with parentNode: SocialServiceBrowerNode) -> SocialServiceBrowserViewControllerConfigurable
}

public struct SocialServiceBrowserConfigurator: SocialServiceBrowserViewControllerConfigurable, SocialServiceBrowserViewControllerUIConfigurable {
    public let selectionMode: SocialServiceBrowserSelectionMode
    public let displayMode: SocialServiceBrowserDisplayMode = .grid
    public let client: SocialServiceBrowserClient
    public let parentNode: SocialServiceBrowerNode?
    
    public init(client: SocialServiceBrowserClient, parentNode: SocialServiceBrowerNode? = nil, selectionMode: SocialServiceBrowserSelectionMode = .select) {
        self.client = client
        self.parentNode = parentNode
        self.selectionMode = selectionMode
    }
    
    public func registerCells(for collectionView: UICollectionView) {
        collectionView.register(UINib(nibName: String(describing: SocialServiceBrowserGridCollectionViewCell.self),
                                      bundle: Bundle(for: SocialServiceBrowserGridCollectionViewCell.self)),
                                forCellWithReuseIdentifier: reusableIdentifierForCell(in: .grid))
        collectionView.register(UINib(nibName: String(describing: SocialServiceBrowserCollectionReusableView.self),
                                      bundle: Bundle(for: SocialServiceBrowserCollectionReusableView.self)),
                                forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                withReuseIdentifier: reusableIdentifierForHeader(in: .grid))
        collectionView.register(UINib(nibName: String(describing: SocialServiceBrowserListCollectionViewCell.self),
                                      bundle: Bundle(for: SocialServiceBrowserListCollectionViewCell.self)),
                                forCellWithReuseIdentifier: reusableIdentifierForCell(in: .list))
    }
    
    public func reusableIdentifierForCell(in displayMode: SocialServiceBrowserDisplayMode) -> String {
        if displayMode == .list {
            return String(describing: SocialServiceBrowserListCollectionViewCell.self)
        }
        return String(describing: SocialServiceBrowserGridCollectionViewCell.self)
    }
    
    public func reusableIdentifierForHeader(in displayMode: SocialServiceBrowserDisplayMode) -> String {
        return String(describing: SocialServiceBrowserCollectionReusableView.self)
    }
    
    public func newConfiguration(with parentNode: SocialServiceBrowerNode) -> SocialServiceBrowserViewControllerConfigurable {
        return SocialServiceBrowserConfigurator(client: client, parentNode: parentNode)
    }
}
