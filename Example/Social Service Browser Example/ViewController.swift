//
//  ViewController.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 22.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import UIKit
import SwiftyDropbox
import SocialServiceBrowserFramework

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func showDropboxBrowser(_ sender: Any) {
        guard DropboxClientsManager.authorizedClient != nil else {
            DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                          controller: self,
                                                          openURL: { (url: URL) -> Void in
                                                            if #available(iOS 10.0, *) {
                                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                                            } else {
                                                                UIApplication.shared.openURL(url)
                                                            }
            })
            return
        }
        
        let configuration = SocialServiceBrowserConfigurator(client: SocialServiceBrowserDropboxClient())
        let viewController = SocialServiceBrowserViewController(configuration: configuration, uiConfiguration: configuration)
        viewController.delegate = self
        present(UINavigationController(rootViewController: viewController), animated: true, completion: nil)
    }
    
    fileprivate func showDocumentBrowser(for url: URL) {
        let documentBrowser = UIDocumentInteractionController(url: url)
        documentBrowser.delegate = self
        documentBrowser.presentPreview(animated: true)
    }
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self.presentedViewController!
    }
}

extension ViewController: SocialServiceBrowserViewControllerDelegate {
    func socialServiceBrowser(_ socialServiceBrowser: SocialServiceBrowserViewController, didSelect node: SocialServiceBrowerNode) {
        if case SocialServiceBrowserSelectionMode.download(_) = socialServiceBrowser.configuration.selectionMode {
            return
        }
        socialServiceBrowser.importNode(node) { [weak self] node, error in
            if let node = node {
                self?.showDocumentBrowser(for: node.fileURL)
            }
        }
    }
    
    func socialServiceBrowser(_ socialServiceBrowser: SocialServiceBrowserViewController, didDownload nodes: [SocialServiceBrowserDownloadedNode]) {
        if case SocialServiceBrowserSelectionMode.download(_) = socialServiceBrowser.configuration.selectionMode {
            print(nodes)
            dismiss(animated: true, completion: nil)
        }
    }
}

