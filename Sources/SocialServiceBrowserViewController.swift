//
//  SocialServiceBrowserViewController.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 22.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import UIKit

public class SocialServiceBrowserDownloadedNode: NSObject {
    public let node: SocialServiceBrowerNode
    public let fileURL: URL
    public init(node: SocialServiceBrowerNode, fileURL: URL) {
        self.node = node
        self.fileURL = fileURL
        super.init()
    }
    
    override public var description: String {
        return "node: \(node), filePath: \(fileURL)"
    }
}

@objc public protocol SocialServiceBrowserViewControllerDelegate: class {
    @objc optional func socialServiceBrowser(_ socialServiceBrowser: SocialServiceBrowserViewController, didSelect node: SocialServiceBrowerNode)
    @objc optional func socialServiceBrowser(_ socialServiceBrowser: SocialServiceBrowserViewController, didDownload nodes: [SocialServiceBrowserDownloadedNode])
    @objc optional func socialServiceBrowser(_ socialServiceBrowser: SocialServiceBrowserViewController, configure cell: UICollectionViewCell, with node: SocialServiceBrowerNode)
    @objc optional func didDismissSocialServiceBrowser(_ socialServiceBrowser: SocialServiceBrowserViewController)
}

public protocol SocialServiceBrowserNodeHeaderConfigurable {
    var tapBlock: (() -> Void)? { get set }
    func configure(with client: SocialServiceBrowserClient, node: SocialServiceBrowerNode)
}

public protocol SocialServiceBrowserNodeCellConfigurable {
    func configure(with configuration: SocialServiceBrowserViewControllerConfigurable, node: SocialServiceBrowerNode)
}

public class SocialServiceBrowserViewController: UICollectionViewController {
    public weak var delegate: SocialServiceBrowserViewControllerDelegate?
    
    public private(set) var downloadThumbnailOperations: [SocialServiceBrowserOperationPerformable] = []
    public private(set) var downloadFilesOperations: [SocialServiceBrowserOperationPerformable] = []
    
    public private(set) var configuration: SocialServiceBrowserViewControllerConfigurable
    public private(set) var uiConfiguration: SocialServiceBrowserViewControllerUIConfigurable
    
    private var refreshControl: UIRefreshControl!
    private var progressView: UIProgressView?
    private var backgroundProcess: UIBackgroundTaskIdentifier?
    
    public var parentNode: SocialServiceBrowerNode? {
        return configuration.parentNode
    }
    public fileprivate(set) var fileNodes: [SocialServiceBrowerNode] = []
    public fileprivate(set) var directoryNodes: [SocialServiceBrowerNode] = []
    public fileprivate(set) var selectedFiles: [SocialServiceBrowerNode] = []
    
    private var cancelledLoadingOperations: Bool = false
    
    deinit {
        if let backgroundProcess = backgroundProcess {
            UIApplication.shared.endBackgroundTask(backgroundProcess)
            self.backgroundProcess = nil
        }
        cancelLoadingAllOperations()
    }
    
    private func cancelLoadingAllOperations() {
        cancelledLoadingOperations = true
        
        for operation in downloadThumbnailOperations {
            operation.cancel()
        }
        for operation in downloadFilesOperations {
            operation.cancel()
        }
        downloadFilesOperations.removeAll()
        downloadThumbnailOperations.removeAll()
    }
    
    public init(configuration: SocialServiceBrowserViewControllerConfigurable, uiConfiguration: SocialServiceBrowserViewControllerUIConfigurable) {
        self.configuration = configuration
        self.uiConfiguration = uiConfiguration
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        if let collectionView = collectionView {
            uiConfiguration.registerCells(for: collectionView)
        }
        
        collectionView?.backgroundColor = UIColor.clear
        collectionView?.allowsMultipleSelection = true
        collectionView?.alwaysBounceVertical = true
        
        view.backgroundColor = UIColor(hue: 0.58, saturation: 0.01, brightness: 0.93, alpha: 1.0)
        title = configuration.client.serviceName
        navigationItem.hidesBackButton = true
        
        let closeButton = uiConfiguration.closeBarButtonItem
        closeButton.action = #selector(self.closeButtonTapped)
        closeButton.target = self
        
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            let spaceFix = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            spaceFix.width = -12
            
            let backButton = uiConfiguration.backBarButtonItem
            backButton.action = #selector(self.backButtonTapped)
            backButton.target = self

            navigationItem.leftBarButtonItems = [spaceFix, backButton, closeButton]
        } else {
            navigationItem.leftBarButtonItems = [closeButton]
        }
        
        if case SocialServiceBrowserSelectionMode.download(_) = configuration.selectionMode {
            navigationItem.rightBarButtonItem = uiConfiguration.importBarButtonItem
            navigationItem.rightBarButtonItem?.target = self
            navigationItem.rightBarButtonItem?.action = #selector(self.importButtonTapped(_:))
            navigationItem.rightBarButtonItem?.isEnabled = selectedFiles.count > 0
        }
        
        if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.headerReferenceSize = CGSize(width: 2, height: 56)
            
            if uiConfiguration.displayMode == .grid {
                flowLayout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
                configureCollectionViewLayout(withNumberOfItemsInRow: 4, spacing: 4, aspectRatio: CGSize(width: 1, height: 1))
            } else {
                flowLayout.itemSize = CGSize(width: view.bounds.size.width, height: 56)
                flowLayout.minimumLineSpacing = 0
                flowLayout.minimumInteritemSpacing = 0
            }
        }
        configureRefreshControl()
        configureProgressView()
    }
    
    private func configureCollectionViewLayout(withNumberOfItemsInRow numberOfItemsInRow: Int, spacing: Float, aspectRatio: CGSize) {
        guard let collectionView = collectionView else { return }
        let collectionViewWidth = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
        let spacingWidth = CGFloat(Float(numberOfItemsInRow - 1) * spacing)
        assert(collectionViewLayout is UICollectionViewFlowLayout)
        guard let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        let itemWidth: Float = Float(collectionViewWidth - collectionViewLayout.sectionInset.left - collectionViewLayout.sectionInset.right - spacingWidth) / Float(numberOfItemsInRow)
        let itemHeight: Float = Float(aspectRatio.height) * itemWidth / Float(aspectRatio.width)
        let itemSize = CGSize(width: CGFloat(floorf(itemWidth)), height: CGFloat(floorf(itemHeight)))
        
        collectionViewLayout.itemSize = itemSize
        collectionViewLayout.minimumInteritemSpacing = CGFloat(spacing)
        collectionViewLayout.minimumLineSpacing = CGFloat(spacing)
    }
    
    private func configureProgressView() {
        guard let navigationController = navigationController else { return }
        
        let progressView = UIProgressView(progressViewStyle: .bar)
        let yOrigin = navigationController.navigationBar.bounds.size.height - progressView.bounds.size.height
        let width = navigationController.navigationBar.bounds.size.width
        let height = progressView.bounds.size.height
        progressView.frame = CGRect(x: 0, y: yOrigin, width: width, height: height)
        progressView.alpha = 0.0
        progressView.trackTintColor = UIColor.lightGray
        navigationController.navigationBar.addSubview(progressView)
        self.progressView = progressView
    }
    
    private func configureRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.reloadContent(_:)), for: .valueChanged)
        collectionView?.addSubview(refreshControl)
        self.refreshControl = refreshControl
        
        refreshControl.beginRefreshing()
        reloadContent()
    }
    
    private func reloadContent() {
        if let parentNode = parentNode {
            let operation = configuration.client.requestChildren(for: parentNode, withCompletion: { [weak self] result in
                if let response = result.value {
                    self?.procressResponse(response)
                }
                self?.finishLoading()
            })
            guard operation != nil else {
                finishLoading()
                return
            }
            operation?.run()
        } else {
            let operation = configuration.client.requestRootNode(with: { [weak self] result in
                if let response = result.value {
                    self?.procressResponse(response)
                }
                self?.finishLoading()
            })
            guard operation != nil else {
                finishLoading()
                return
            }
            operation?.run()
        }
    }
    
    private func procressResponse(_ response: SocialServiceBrowerNodeListResponse) {
        var fileList: [SocialServiceBrowerNode] = []
        var directoryList: [SocialServiceBrowerNode] = []
        
        for node in response.nodes {
            if node.isDirectory {
                directoryList.append(node)
            } else {
                fileList.append(node)
            }
        }
        self.directoryNodes = directoryList
        self.fileNodes = fileList
    }
    
    private func finishLoading() {
        for indexPath in collectionView?.indexPathsForSelectedItems ?? [] {
            collectionView?.deselectItem(at: indexPath, animated: true)
        }
        collectionView?.reloadData()
        refreshControl.endRefreshing()
    }
    
    fileprivate func showSubdirectory(for node: SocialServiceBrowerNode) {
        guard node.isDirectory else { return }
        let childNodeViewController = SocialServiceBrowserViewController(configuration: configuration.newConfiguration(with: node), uiConfiguration: uiConfiguration)
        childNodeViewController.delegate = delegate
        navigationController?.pushViewController(childNodeViewController, animated: true)
    }
    
    @objc private func reloadContent(_ sender: AnyObject) {
        reloadContent()
    }
    
    @objc private func backButtonTapped(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func closeButtonTapped(_ sender: AnyObject) {
        cancelLoadingAllOperations()
        guard delegate?.didDismissSocialServiceBrowser?(self) != nil else {
            if presentingViewController != nil {
                dismiss(animated: true, completion: nil)
            } else {
                for viewController in navigationController?.viewControllers.reversed() ?? [] {
                    if !(viewController is SocialServiceBrowserViewController) {
                        navigationController?.popToViewController(viewController, animated: true)
                        return
                    }
                }
            }
            return
        }
    }
    
    @objc private func importButtonTapped(_ sender: AnyObject) {
        importNodes(selectedFiles) { [weak self] (_, _) in
            self?.removeSelectedFiles()
        }
    }
    
    public func removeSelectedFiles() {
        selectedFiles.removeAll()
        navigationItem.rightBarButtonItem?.isEnabled = self.selectedFiles.count > 0
    }
    
    public func importNode(_ node: SocialServiceBrowerNode, with completion: ((SocialServiceBrowserDownloadedNode?, Error?) -> Void)?) {
        importNodes([node]) { nodes, errors in
            completion?(nodes.first, errors?.first)
        }
    }
    
    public func importNodes(_ nodes: [SocialServiceBrowerNode], with completion: (([SocialServiceBrowserDownloadedNode], [Error]?) -> Void)?) {
        backgroundProcess = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
            guard let backgroundProcess = self?.backgroundProcess else { return }
            UIApplication.shared.endBackgroundTask(backgroundProcess)
            self?.backgroundProcess = nil
        })
        
        collectionView?.isUserInteractionEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        progressView?.progress = 0.0
        
        UIView.animate(withDuration: 0.75) {
            self.collectionView?.alpha = 0.5
            self.progressView?.alpha = 1.0
        }
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.tintColor = UIColor.darkGray
        activityIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(activityIndicator)
        
        let group = DispatchGroup()
        var downloadedURLs: [Int: SocialServiceBrowserDownloadedNode] = [:]
        var errors: [Error] = []
        var numberOfTaskCompleted: Int = 0
        let allOperationsCount = nodes.count
        
        for i in 0..<nodes.count {
            let node = nodes[i]
            
            group.enter()
            var operation: SocialServiceBrowserOperationPerformable!
            operation = configuration.client.requestData(for: node, withCompletion: { [weak self, weak operation] result in
                if let downloadedURL = result.value {
                    downloadedURLs[i] = SocialServiceBrowserDownloadedNode(node: node, fileURL: downloadedURL)
                }
                if let error = result.error {
                    errors.append(error)
                }
                numberOfTaskCompleted += 1
                let progress = CGFloat(numberOfTaskCompleted)/CGFloat(allOperationsCount)
                self?.progressView?.progress = Float(progress)
                if let operation = operation, let index = self?.downloadFilesOperations.index(where: { $0 === operation }) {
                    self?.downloadFilesOperations.remove(at: index)
                }
                group.leave()
            })
            
            downloadFilesOperations.append(operation)
            operation.run()
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let weakSelf = self else { return }
            
            weakSelf.collectionView?.isUserInteractionEnabled = true
            weakSelf.navigationItem.rightBarButtonItem?.isEnabled = true
            activityIndicator.removeFromSuperview()
            
            UIView.animate(withDuration: 0.75) {
                weakSelf.collectionView?.alpha = 1.0
                weakSelf.progressView?.alpha = 0.0
            }
            for indexPath in weakSelf.collectionView?.indexPathsForSelectedItems ?? [] {
                weakSelf.collectionView?.deselectItem(at: indexPath, animated: true)
            }
            if let backgroundProcess = weakSelf.backgroundProcess {
                UIApplication.shared.endBackgroundTask(backgroundProcess)
                weakSelf.backgroundProcess = nil
            }

            if !weakSelf.cancelledLoadingOperations {
                weakSelf.cancelledLoadingOperations = false
                
                let downloadedNodes = downloadedURLs.sorted(by: { $0.key < $1.key }).map({ $0.value })
                
                completion?(downloadedNodes, errors)
                weakSelf.delegate?.socialServiceBrowser?(weakSelf, didDownload: downloadedNodes)
            }
            
        }
    }
}

// MARK: - UICollectionViewDataSource

extension SocialServiceBrowserViewController: UICollectionViewDelegateFlowLayout {
    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return directoryNodes.count + (fileNodes.count > 0 ? 1 : 0)
    }
    
    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section < directoryNodes.count {
            return 0
        }
        return fileNodes.count
    }
    
    override public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let collectionViewHeaderClass = uiConfiguration.reusableIdentifierForHeader(in: uiConfiguration.displayMode)
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: String(describing: collectionViewHeaderClass), for: indexPath)
        let node = directoryNodes[indexPath.section]
        if var header = headerView as? SocialServiceBrowserNodeHeaderConfigurable {
            header.configure(with: configuration.client, node: node)
            header.tapBlock = { [weak self] in
                self?.showSubdirectory(for: node)
            }
        }
        
        return headerView
    }
    
    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCellClass = uiConfiguration.reusableIdentifierForCell(in: uiConfiguration.displayMode)
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: collectionViewCellClass), for: indexPath)
        let node = fileNodes[indexPath.row]
        
        if let cell = collectionViewCell as? SocialServiceBrowserNodeCellConfigurable {
            cell.configure(with: configuration, node: node)
        }
        
        delegate?.socialServiceBrowser?(self, configure: collectionViewCell, with: node)
        return collectionViewCell
    }
    
    override public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if case SocialServiceBrowserSelectionMode.select = configuration.selectionMode {
            return true
        }

        if selectedFiles.count < configuration.selectionMode.maxSelectedItemsCount {
            return true
        }
        
        var message = "You cannot select more than \(configuration.selectionMode.maxSelectedItemsCount) items"
        if configuration.selectionMode.maxSelectedItemsCount == 1 {
            message = "You cannot select more than one item"
        }
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        return false
    }
    
    override public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if case SocialServiceBrowserSelectionMode.download(_) = configuration.selectionMode {
            let node = fileNodes[indexPath.row]
            selectedFiles.append(node)
            navigationItem.rightBarButtonItem?.isEnabled = selectedFiles.count > 0
        }
        delegate?.socialServiceBrowser?(self, didSelect: fileNodes[indexPath.row])
    }
    
    override public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let node = fileNodes[indexPath.row]
        if let index = selectedFiles.index(where: { $0 === node }) {
            selectedFiles.remove(at: index)
        }
        navigationItem.rightBarButtonItem?.isEnabled = selectedFiles.count > 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize.zero
        }
        if section < directoryNodes.count {
            return collectionViewLayout.headerReferenceSize
        }
        return CGSize.zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout, section >= directoryNodes.count else {
            return UIEdgeInsets.zero
        }
        return collectionViewLayout.sectionInset
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout, section >= directoryNodes.count else {
            return 0
        }
        return collectionViewLayout.minimumLineSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout, section >= directoryNodes.count else {
            return 0
        }
        return collectionViewLayout.minimumInteritemSpacing
    }
}
