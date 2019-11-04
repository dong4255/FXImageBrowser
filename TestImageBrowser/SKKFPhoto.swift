//
//  SKKFPhoto.swift
//  TestImageBrowser
//
//  Created by MAC on 2019/11/4.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit
import Kingfisher
import SKPhotoBrowser

class SKKFPhoto: NSObject, SKPhotoProtocol {
    
    var index: Int = 0
    
    var underlyingImage: UIImage?
    
    var caption: String?
    
    var contentMode: UIView.ContentMode = .scaleAspectFill
    
    var photoURL: String?
    
    override init() {
        super.init()
    }
    
    convenience init(image: UIImage) {
        self.init()
        underlyingImage = image
    }
    
    convenience init(url: String?) {
        self.init()
        photoURL = url
    }
    
    convenience init(url: String?, holder: UIImage?) {
        self.init()
        photoURL = url
        underlyingImage = holder
    }
    
    func checkCache() {
        guard let photoURL = photoURL else {
            return
        }
        
        ImageCache.default.retrieveImage(forKey: photoURL, options: nil) { (image, cacheType) in
            if let image = image {
                self.underlyingImage = image
            }
        }
    }
    
    func loadUnderlyingImageAndNotify() {
        guard photoURL != nil, let URL = URL(string: photoURL!) else { return }
        
        KingfisherManager.shared.retrieveImage(with: URL, options: nil, progressBlock: nil) { (image, aError, cacheType, url) in
            if let image = image {
                self.underlyingImage = image
                self.loadUnderlyingImageComplete()
            }
        }
    }
    
    func loadUnderlyingImageComplete() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: SKPHOTO_LOADING_DID_END_NOTIFICATION), object: self)
    }
    
}
