//
//  ImageBrowserTransition.swift
//  TestImageBrowser
//
//  Created by Dong on 2019/3/1.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit

class ImageBrowserTransition: NSObject , UIViewControllerAnimatedTransitioning {
    
    var smallImageCell:SmallImageCell?
    var dismissImageView:UIImageView?
    private let tempImageView : UIImageView
    
    init(smallImageCell:SmallImageCell) {
        self.smallImageCell = smallImageCell
        self.tempImageView = UIImageView(image: smallImageCell.imageView.image)
        self.tempImageView.contentMode = .scaleAspectFill
        self.tempImageView.clipsToBounds = true
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromVC = transitionContext.viewController(forKey: .from) ,
            let toVC = transitionContext.viewController(forKey: .to) else { return }
                
        
        if toVC.isBeingPresented {
            presentAnimation(using: transitionContext)
        }
        
        if fromVC.isBeingDismissed {
            dismissAnimation(using: transitionContext)
        }
        
    }
    
    
    private func presentAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? ImageBrowserViewController ,
            let image = tempImageView.image else {
                return
        }
        
        let containerView = transitionContext.containerView
        
        if let smallImageCell = self.smallImageCell {
            tempImageView.frame = smallImageCell.convert(smallImageCell.bounds, to: containerView)
        }else {
            tempImageView.frame.size = .zero
            tempImageView.center = containerView.center
        }
        smallImageCell?.isHidden = true
        toVC.backgroundView.alpha = 0
        toVC.collectionBackgroundView.isHidden = true
        
        let scrollView = UIScrollView()
        scrollView.frame = containerView.frame
        
        containerView.addSubview(toVC.view)
        containerView.addSubview(scrollView)
        scrollView.addSubview(tempImageView)
        
        
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.width * image.size.height / image.size.width
        
        if #available(iOS 11.0, *) , height >= UIScreen.main.bounds.size.height{
            scrollView.contentInsetAdjustmentBehavior = .always
        }
        
        scrollView.contentSize = CGSize(width: width, height: max(height, UIScreen.main.bounds.size.height))
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            toVC.backgroundView.alpha = 1
            self.tempImageView.frame.size = CGSize(width: width, height: height)
            if height < UIScreen.main.bounds.size.height {
                self.tempImageView.center = scrollView.center
            }else {
                self.tempImageView.frame.origin = .zero
            }
        }) { (_) in
            toVC.collectionBackgroundView.isHidden = false
            scrollView.removeFromSuperview()
            transitionContext.completeTransition(true)
            self.smallImageCell?.isHidden = false
        }
    }
    
    private func dismissAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromVC = transitionContext.viewController(forKey: .from) as? ImageBrowserViewController ,
            let toVC = transitionContext.viewController(forKey: .to) as? ViewController ,
            let dismissImageView = dismissImageView else {
                return
        }
        
        let containerView = transitionContext.containerView
        
        self.smallImageCell?.isHidden = true
        
        tempImageView.image = dismissImageView.image
        tempImageView.frame = dismissImageView.convert(dismissImageView.bounds, to: fromVC.view)
        
        fromVC.collectionBackgroundView.isHidden = true
        
        containerView.addSubview(tempImageView)
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            if let smallImageCell = self.smallImageCell {
                self.tempImageView.frame = smallImageCell.convert(smallImageCell.bounds, to: toVC.view)
            }else {
                containerView.alpha = 0
            }
            fromVC.backgroundView.alpha = 0
        }) { (_) in
            self.smallImageCell?.isHidden = false
            self.tempImageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }

}
