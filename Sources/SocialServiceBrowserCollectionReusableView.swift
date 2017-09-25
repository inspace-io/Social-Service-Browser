//
//  SocialServiceBrowserCollectionReusableView.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 27.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import UIKit

class SocialServiceBrowserCollectionReusableView: UICollectionReusableView, SocialServiceBrowserNodeHeaderConfigurable {
    var tapBlock: (() -> Void)?
    @IBOutlet private weak var titleLabel: UILabel!
    
    func configure(with client: SocialServiceBrowserClient, node: SocialServiceBrowerNode) {
        titleLabel.text = node.nodeName
    }
    
    @IBAction private func headerButtonTaped(_ sender: Any) {
        tapBlock?()
    }
}
