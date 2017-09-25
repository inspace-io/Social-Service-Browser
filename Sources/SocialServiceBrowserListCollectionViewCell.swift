//
//  SocialServiceBrowserListCollectionViewCell.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 03.10.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import UIKit

class SocialServiceBrowserListCollectionViewCell: UICollectionViewCell, SocialServiceBrowserNodeCellConfigurable {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var backgroundContentView: UIView!
    
    private var shouldShowBorderWhenSelected: Bool = false

    func configure(with configuration: SocialServiceBrowserViewControllerConfigurable, node: SocialServiceBrowerNode) {
        if case SocialServiceBrowserSelectionMode.select = configuration.selectionMode {
            shouldShowBorderWhenSelected = false
        } else {
            shouldShowBorderWhenSelected = true
        }
        titleLabel.text = node.nodeName
        imageView.setThumbnailImage(with: configuration.client, for: node, completionHandler: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.image = UIImage(named: "page_white_import", in: Bundle(for: type(of: self)), compatibleWith: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundContentView.backgroundColor = isSelected ? UIColor.lightGray.withAlphaComponent(0.25) : UIColor.white
        imageView.image = UIImage(named: "page_white_import", in: Bundle(for: type(of: self)), compatibleWith: nil)
    }
    
    override var isSelected: Bool {
        set {
            backgroundContentView.backgroundColor = newValue ? UIColor.lightGray.withAlphaComponent(0.25) : UIColor.white
            super.isSelected = newValue
        }
        get {
            return super.isSelected
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
}
