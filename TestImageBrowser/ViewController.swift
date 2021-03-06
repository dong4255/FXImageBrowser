//
//  ViewController.swift
//  TestImageBrowser
//
//  Created by Dong on 2019/2/27.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import Kingfisher
import SKPhotoBrowser

class ViewController: UIViewController {
    
    private let flowLayout = UICollectionViewFlowLayout()
    private var collectionView : UICollectionView!
    private let cellId = "smallImageCell"
    private var dataSource = [(imageUrl:URL,imageSize:CGSize?)]()
    
    private var page = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        flowLayout.minimumInteritemSpacing = 6
        flowLayout.minimumLineSpacing = 6
        flowLayout.sectionInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
//        flowLayout.columnCount = 3
        flowLayout.scrollDirection = .vertical
        
        let rect = CGRect(x: 0, y: 20, width: view.bounds.size.width, height: view.bounds.size.height - 20)
        collectionView = UICollectionView(frame: rect, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SmallImageCell.self, forCellWithReuseIdentifier: cellId)
        
        view.addSubview(collectionView)
        
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        requestImageData()
    }

    private func requestImageData() {
        guard let urlString = NSString(string: "http://gank.io/api/data/福利/50/\(page)").addingPercentEscapes(using: String.Encoding.utf8.rawValue),
            let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, aError) in
            DispatchQueue.main.async {
                if let valueData = data,
                    let value = try? JSONSerialization.jsonObject(with: valueData, options: []) ,
                    let json = value as? [String:Any],
                    let results = json["results"] as? [[String:Any]] {
                    
                    for item in results {
                        if let imageUrlString = item["url"] as? String ,
                            let imageUrl = URL(string: imageUrlString) {
                            self.dataSource.append((imageUrl,nil))
                        }
                    }
                    
                    self.collectionView.reloadData()
                }
            }
        }
        
        task.resume()
    }

}

extension ViewController : UICollectionViewDelegate, UICollectionViewDataSource , UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
//        if let imageSize = dataSource[indexPath.row].imageSize {
//            return imageSize
//        }
        
        let itemWidthHeight = (UIScreen.main.bounds.width - 24) / 3.0
        return CGSize(width: itemWidthHeight, height: itemWidthHeight)
//        let image = imageArray[indexPath.row]
//        return CGSize(width: itemWidthHeight, height: itemWidthHeight * image.size.height / image.size.width)
//        return CGSize(width: itemWidthHeight, height: itemWidthHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! SmallImageCell
        cell.imageView.contentMode = .scaleAspectFill
        cell.imageView.clipsToBounds = true
        cell.imageView.kf.setImage(with: dataSource[indexPath.row].imageUrl) { (image, aError, cacheType, url) in
            if let image = image {
                self.dataSource[indexPath.row].imageSize = image.size
                collectionView.reloadItems(at: [indexPath])
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
//        let cell = collectionView.cellForItem(at: indexPath) as! SmallImageCell
//        let imageBrowser = ImageBrowserViewController(selectedIndex: indexPath.row, cell: cell, collectionView: collectionView)
//        imageBrowser.delegate = self
//        imageBrowser.showImageBrowser(with: self)
        
        let photos = dataSource.map{ SKKFPhoto(url: $0.imageUrl.absoluteString) }
        let imageBrowser = SKPhotoBrowser(photos: photos, initialPageIndex: indexPath.item)
        imageBrowser.delegate = self
        self.present(imageBrowser, animated: true, completion: nil)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height <= 150 , dataSource.count > 0 {
            page += 1
            requestImageData()
        }
    }
    
}

extension ViewController : ImageBrowserViewControllerDelegate {
    
    func numberOfImages() -> Int {
        return dataSource.count
    }
    
    func imageBrowser(_ imageBrowser: ImageBrowserViewController, imageAt indexPath: IndexPath) -> UIImage? {
        let imageKey = dataSource[indexPath.row].imageUrl.absoluteString
        return ImageCache.default.retrieveImageInMemoryCache(forKey: imageKey) ?? ImageCache.default.retrieveImageInDiskCache(forKey: imageKey)
    }
    
    
}

extension ViewController: SKPhotoBrowserDelegate {
    
    func didShowPhotoAtIndex(_ browser: SKPhotoBrowser, index: Int) {
        collectionView.visibleCells.forEach({$0.isHidden = false})
        collectionView.cellForItem(at: IndexPath(item: index, section: 0))?.isHidden = true
    }
    
    func willDismissAtPageIndex(_ index: Int) {
        collectionView.visibleCells.forEach({$0.isHidden = false})
        collectionView.cellForItem(at: IndexPath(item: index, section: 0))?.isHidden = true
    }
    
    func didDismissAtPageIndex(_ index: Int) {
        collectionView.cellForItem(at: IndexPath(item: index, section: 0))?.isHidden = false
    }
    
    func viewForPhoto(_ browser: SKPhotoBrowser, index: Int) -> UIView? {
        return collectionView.cellForItem(at: IndexPath(item: index, section: 0))
    }
}

