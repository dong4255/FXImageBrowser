//
//  ImageBrowserViewController.swift
//  TestImageBrowser
//
//  Created by Dong on 2019/2/27.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit

@objc protocol ImageBrowserViewControllerDelegate {
    @objc func numberOfImages() -> Int
    @objc func imageBrowser(_ imageBrowser:ImageBrowserViewController, imageAt indexPath:IndexPath) -> UIImage?
}

class ImageBrowserViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    open weak var delegate : ImageBrowserViewControllerDelegate?
    
    private var selectedIndex:Int
    private let flowLayout = UICollectionViewFlowLayout()
    private let collectionView : UICollectionView
    let collectionBackgroundView = UIView()
    let backgroundView = UIView()
    
    
    private let smallImageCell:SmallImageCell
    private let smallImageCollectionView:UICollectionView
    private let transitionAnimation:ImageBrowserTransition
    
    init(selectedIndex:Int, cell:SmallImageCell, collectionView:UICollectionView) {
        self.selectedIndex = selectedIndex
        self.smallImageCell = cell
        self.smallImageCollectionView = collectionView
        self.transitionAnimation = ImageBrowserTransition(smallImageCell: cell)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.modalPresentationCapturesStatusBarAppearance = true
        self.transitioningDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        backgroundView.backgroundColor = .black
        backgroundView.alpha = 1
        backgroundView.frame = view.frame
        
        collectionBackgroundView.frame = view.frame
        collectionBackgroundView.backgroundColor = .clear
        collectionBackgroundView.clipsToBounds = true
        
        flowLayout.itemSize = view.bounds.size
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 12
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = .init(top: 0, left: 0, bottom: 0, right: 12)
        
        collectionView.frame = view.frame
        collectionView.frame.size.width = view.bounds.size.width + 12
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.id)
        
        view.addSubview(backgroundView)
        view.addSubview(collectionBackgroundView)
        collectionBackgroundView.addSubview(collectionView)
        
        self.collectionView.scrollToItem(at: IndexPath(row: self.selectedIndex, section: 0), at: .left, animated: false)
        
        setSubviewsLayout()
    }
    
    
    private func setSubviewsLayout() {

        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        
    }
    
    
    open func showImageBrowser(with target:UIViewController?) {
        self.modalPresentationStyle = .custom
        self.modalPresentationCapturesStatusBarAppearance = true
        target?.present(self, animated: true, completion: nil)
        UIApplication.shared.setStatusBarHidden(true, with: .slide)
    }

}

extension ImageBrowserViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.delegate?.numberOfImages() ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.id, for: indexPath) as! ImageCollectionViewCell
        cell.delegate = self
        cell.image = self.delegate?.imageBrowser(self, imageAt: indexPath)
        if indexPath.row == selectedIndex {
            cell.pan.isEnabled = true
        }
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        selectedIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        let cell = collectionView.cellForItem(at: IndexPath(row: selectedIndex, section: 0)) as? ImageCollectionViewCell
        cell?.pan.isEnabled = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for cell in collectionView.visibleCells {
            let imageCell = cell as? ImageCollectionViewCell
            imageCell?.pan.isEnabled = false
        }
    }
    
//    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

//        let pageWidth = scrollView.bounds.size.width
//        let movedDistance = targetContentOffset.pointee.x - pageWidth * CGFloat(selectedIndex)
//        if movedDistance >= pageWidth / 2.0 && selectedIndex < imageArray.count - 1 {
//            selectedIndex += 1
//        }else if movedDistance <= -pageWidth / 2.0 && selectedIndex > 0 {
//            selectedIndex -= 1
//        }
//
//        if abs(velocity.x) >= 2 {
//            targetContentOffset.pointee.x = pageWidth * CGFloat(selectedIndex)
//        }else {
//
//            targetContentOffset.pointee.x = scrollView.contentOffset.x
//            scrollView.setContentOffset(CGPoint(x: pageWidth * CGFloat(selectedIndex), y: 0), animated: true)
//
//        }

//    }
    
}

extension ImageBrowserViewController : ImageCollectionViewCellDelegate {
    
    func browserWillBeginDismiss() {
        let cell = smallImageCollectionView.cellForItem(at: IndexPath(row: selectedIndex, section: 0))
        cell?.isHidden = true
    }
    
    func browserDidCancelDismiss() {
        let cell = smallImageCollectionView.cellForItem(at: IndexPath(row: selectedIndex, section: 0))
        cell?.isHidden = false
    }
    
    func dismissBrowserAction(_ cell:ImageCollectionViewCell, imageView:UIImageView) {
        UIApplication.shared.setStatusBarHidden(false, with: .slide)
        let cell = smallImageCollectionView.cellForItem(at: IndexPath(row: selectedIndex, section: 0)) as? SmallImageCell
        self.transitionAnimation.smallImageCell = cell
        self.transitionAnimation.dismissImageView = imageView
        self.dismiss(animated: true, completion: nil)
    }
}

extension ImageBrowserViewController : UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self.transitionAnimation
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self.transitionAnimation
    }
}
