//
//  SocialServiceBrowserCollectionViewCell.swift
//  Social Service Browser
//
//  Created by Michal Zaborowski on 27.09.2017.
//  Copyright © 2017 Inspace. All rights reserved.
//

import UIKit

class SocialServiceBrowserGridCollectionViewCell: UICollectionViewCell, SocialServiceBrowserNodeCellConfigurable {
    @IBOutlet private weak var imageView: UIImageView!
    private var shouldShowBorderWhenSelected: Bool = false

    func configure(with configuration: SocialServiceBrowserViewControllerConfigurable, node: SocialServiceBrowerNode) {
        if case SocialServiceBrowserSelectionMode.select = configuration.selectionMode {
            shouldShowBorderWhenSelected = false
        } else {
            shouldShowBorderWhenSelected = true
        }
        
        imageView.setThumbnailImage(with: configuration.client, for: node, completionHandler: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.image = UIImage(named: "page_white_import", in: Bundle(for: type(of: self)), compatibleWith: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage(named: "page_white_import", in: Bundle(for: type(of: self)), compatibleWith: nil)
    }
    
    override var isSelected: Bool {
        set {
            layer.borderWidth = newValue ? 2.0 : 0.0
            layer.borderColor = newValue ? UIColor.darkGray.cgColor : UIColor.clear.cgColor
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
