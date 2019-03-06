//
//  SmallImageCell.swift
//  TestImageBrowser
//
//  Created by Dong on 2019/3/5.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit

class SmallImageCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
