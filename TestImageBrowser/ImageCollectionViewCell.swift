//
//  ImageCollectionViewCell.swift
//  TestImageBrowser
//
//  Created by Dong on 2019/2/27.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit

@objc protocol ImageCollectionViewCellDelegate {
    @objc optional func browserWillBeginDismiss()
    @objc optional func browserDidCancelDismiss()
    @objc optional func dismissBrowserAction(_ cell:ImageCollectionViewCell, imageView:UIImageView)
}

class ImageCollectionViewCell: UICollectionViewCell {
    
    weak var delegate:ImageCollectionViewCellDelegate?
    
    static let id = "ImageCollectionViewCell"
    
    private let scrollView = UIScrollView()
    
    private let imageView = UIImageView()
    
    lazy var pan = {
        return UIPanGestureRecognizer(target: self, action: #selector(scrollViewPanAction(_:)))
    }()
    
    var image : UIImage? {
        didSet{
            changeImageViewFrame()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 创建子视图
    /// 创建子视图
    private func createSubviews() {
        
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        
        scrollView.backgroundColor = .clear
        scrollView.frame = self.contentView.frame
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.zoomScale = 1
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 1.5

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(scrollViewSingleTapAction(_:)))
        singleTap.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(singleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(scrollViewDoubleTapAction(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        singleTap.require(toFail: doubleTap)
        
        pan.isEnabled = false
        pan.delegate = self
        pan.maximumNumberOfTouches = 1
        scrollView.addGestureRecognizer(pan)
        
        imageView.contentMode = .scaleAspectFit
        
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        
        setSubviewsLayout()
    }
    
    private func setSubviewsLayout() {

        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    
    private func changeImageViewFrame() {
        guard let image = self.image else {
            return
        }
        
        imageView.image = image
        
        let width = bounds.size.width
        let height = bounds.size.width * image.size.height / image.size.width
        
        imageView.frame.size = CGSize(width: width, height: height)
        scrollView.contentSize = CGSize(width: width, height: max(height, bounds.size.height))
        if height < bounds.size.height {
            imageView.center = scrollView.center
        }else {
            imageView.frame.origin = .zero
        }
        imageView.autoresizingMask = .flexibleWidth
        
    }
    
    
    // MARK: - UI Action
    // MARK: 移动手势
    @objc private func scrollViewPanAction(_ pan:UIPanGestureRecognizer) {
        guard let collectionView = self.superview as? UICollectionView ,
            let backgroundView = collectionView.superview?.superview?.subviews.first else { return }
        let offset = pan.translation(in: pan.view)
        
        switch pan.state {
        case .began :
            self.delegate?.browserWillBeginDismiss?()
            UIApplication.shared.setStatusBarHidden(false, with: .slide)
            fallthrough
        case .changed:
            collectionView.isScrollEnabled = false
            collectionView.superview?.transform = CGAffineTransform(translationX: 0, y: offset.y)
            backgroundView.alpha = 1 - abs(offset.y) / scrollView.bounds.size.height
        case .cancelled , .ended:
            if abs(offset.y) >= bounds.size.height * 0.22 {
                dismissBrowser()
            }else if pan.velocity(in: pan.view).y >= 800 , pan.isEnabled {
                dismissBrowser()
            }else {
                collectionView.isScrollEnabled = true
                collectionView.superview?.transform = .identity
                backgroundView.alpha = 1
                self.delegate?.browserDidCancelDismiss?()
                UIApplication.shared.setStatusBarHidden(true, with: .slide)
            }
        default:
            break
        }
    }
    
    // MARK: 单击手势
    @objc private func scrollViewSingleTapAction(_ singleTap:UITapGestureRecognizer) {
        dismissBrowser()
    }
    
    // MARK: 双击手势
    @objc private func scrollViewDoubleTapAction(_ doubleTap:UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.setZoomScale(1.5, animated: true)
        }else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    private func dismissBrowser() {
        self.delegate?.dismissBrowserAction?(self, imageView: imageView)
    }
    

}

extension ImageCollectionViewCell : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


extension ImageCollectionViewCell : UIScrollViewDelegate {
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        let offsetX = max((scrollView.bounds.size.width - scrollView.contentInset.left - scrollView.contentInset.right - scrollView.contentSize.width) * 0.5, 0.0)
        let offsetY = max((scrollView.bounds.size.height - scrollView.contentInset.top - scrollView.contentInset.bottom - scrollView.contentSize.height) * 0.5, 0.0)

        self.imageView.center = CGPoint(x:scrollView.contentSize.width * 0.5 + offsetX,
                                        y:scrollView.contentSize.height * 0.5 + offsetY)
        
    }
    
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 && Int(scrollView.contentOffset.y) < Int(scrollView.contentSize.height - scrollView.bounds.size.height) {
            pan.isEnabled = false
        }else {
            pan.isEnabled = true
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 && Int(scrollView.contentOffset.y) < Int(scrollView.contentSize.height - scrollView.bounds.size.height) {
            pan.isEnabled = false
        }else {
            pan.isEnabled = true
        }
    }

}
