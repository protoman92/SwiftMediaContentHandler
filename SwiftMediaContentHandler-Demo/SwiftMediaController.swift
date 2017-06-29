//
//  SwiftMediaController.swift
//  SwiftMediaContentHandler-Demo
//
//  Created by Hai Pham on 4/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import RxSwift
import RxCocoa
import SwiftUtilities
import UIKit

final class SwiftMediaController: UIViewController {
    @IBOutlet weak var collectionView1: UICollectionView!
    @IBOutlet weak var label1: UILabel!

    fileprivate let albumHolder = AlbumHolder()
    fileprivate let disposeBag = DisposeBag()
    fileprivate let cellSpacing: CGFloat = 2
    fileprivate let imageManager = PHImageManager()
    fileprivate var mediaDatabase: LocalMediaDatabase!
    
    deinit {
        print("Deinit \(self)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mediaDatabase = LocalMediaDatabase.builder()
            .add(collectionTypes: .album, .smartAlbum, .moment)
            .add(mediaTypes: .image, .video, .audio)
            .build()
        
        let albumStream = mediaDatabase
            .albumStream
            .filter({$0.value != nil})
            .map({$0.value!})
            .startWith(Album.withErrorMedia(5) as AlbumType)
            .map(AlbumEither.right)
            .share()
        
        let errorStream = mediaDatabase
            .databaseErrorStream
            .map({$0?.localizedDescription ?? ""})
            .share()
                
        self.mediaDatabase = mediaDatabase
        collectionView1.rx.setDataSource(self).addDisposableTo(disposeBag)
        collectionView1.rx.setDelegate(self).addDisposableTo(disposeBag)
        
        albumStream
            .doOnNext({[weak self] in self?.albumReceived($0, with: self)})
            .subscribe()
            .addDisposableTo(disposeBag)
        
        errorStream
            .bind(to: label1.rx.text)
            .addDisposableTo(disposeBag)
        
        errorStream
            .map({$0.isNotEmpty})
            .bind(to: collectionView1.rx.isHidden)
            .addDisposableTo(disposeBag)
        
        // Start loading media
        mediaDatabase.loadInitialMedia()
    }
    
    fileprivate func albumReceived(_ result: AlbumEither,
                                   with current: SwiftMediaController?) {
        if let current = current {
            let collectionView = current.collectionView1

            albumHolder.safeAppend(result) {_ in
                collectionView?.reloadData()
            }
        } else {
            fatalError()
        }
    }
}

extension SwiftMediaController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int)
        -> CGFloat
    {
        return cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int)
        -> CGFloat
    {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: cellSpacing / 2,
                            left: 0,
                            bottom: cellSpacing / 2,
                            right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let pFrame = collectionView.bounds
        
        return CGSize(width: pFrame.width / 5 - cellSpacing,
                      height: pFrame.width / 5 - cellSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {}
}

extension SwiftMediaController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return albumHolder.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return albumHolder.albumEithers.element(at: section)?.value?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "GalleryCell",
            for: indexPath) as! GalleryCell
        
        cell.backgroundColor = .lightGray
        cell.imageView1.backgroundColor = .black
        
        if let lmt = albumHolder.albumEithers
            .element(at: indexPath.section)?.value?
            .albumMedia
            .element(at: indexPath.row)
        {
            switch lmt {
            case .success(let media):
                let asset = media.localAsset
                cell.label1.text = media.id
                
                imageManager.requestImage(
                    for: asset,
                    targetSize: CGSize(width: 200, height: 200),
                    contentMode: .aspectFit,
                    options: nil)
                {
                    cell.imageView1.image = $0.0
                }
                
            case .failure(let error):
                cell.imageView1.image = nil
                cell.label1.text = error.localizedDescription
            }
        }
        
        return cell
    }
}

class GalleryCell: UICollectionViewCell {
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var label1: UILabel!
}

extension Album {
    public static func withErrorMedia(_ count: Int) -> Album {
        let media = (0..<count)
            .map({_ in "Error"})
            .map(MediaError.init)
            .map(LMTEither.left)
        
        return Album.builder()
            .with(name: "Error media")
            .add(media: media)
            .build()
    }
}
