//
//  GalleryController.swift
//  TestApplication
//
//  Created by Hai Pham on 4/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import RxSwift
import RxCocoa
import SwiftMediaContentHandler
import SwiftUtilities
import UIKit

final class SwiftMediaController: UIViewController {
    @IBOutlet weak var collectionView1: UICollectionView!
    @IBOutlet weak var label1: UILabel!

    fileprivate let disposeBag = DisposeBag()
    fileprivate let cellSpacing: CGFloat = 2
    fileprivate let imageManager = PHImageManager()
    fileprivate var mediaDatabase: LocalMediaDatabase!
    fileprivate var albums = [AlbumType]()
    
    deinit {
        print("Deinit \(self)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mediaDatabase = LocalMediaDatabase.builder()
            .add(collectionTypes: .album, .smartAlbum, .moment)
            .add(mediaTypes: .image, .video, .audio)
            .build()
        
        let albumObservable = mediaDatabase
            .albumStream
            .filter({$0.value != nil})
            .map({$0.value!})
            .startWith(Album.withErrorMedia(5) as AlbumType)
            .share()
        
        let errorObservable = mediaDatabase
            .databaseErrorStream
            .map({$0?.localizedDescription ?? ""})
            .share()
                
        self.mediaDatabase = mediaDatabase
        collectionView1.rx.setDataSource(self).addDisposableTo(disposeBag)
        collectionView1.rx.setDelegate(self).addDisposableTo(disposeBag)
        
        albumObservable
            .doOnNext({[weak self] in self?.albumReceived($0, with: self)})
            .subscribe()
            .addDisposableTo(disposeBag)
        
        errorObservable
            .bind(to: label1.rx.text)
            .addDisposableTo(disposeBag)
        
        errorObservable
            .map({$0.isNotEmpty})
            .bind(to: collectionView1.rx.isHidden)
            .addDisposableTo(disposeBag)
        
        // Start loading media
        mediaDatabase.loadInitialMedia()
    }
    
    fileprivate func albumReceived(_ album: AlbumType,
                                   with current: SwiftMediaController?) {
        if let current = current {
            current.albums.append(album)
            current.collectionView1.reloadData()
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
        
        return CGSize(width: pFrame.width / 4 - cellSpacing,
                      height: pFrame.width / 4 - cellSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {}
}

extension SwiftMediaController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return albums.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return albums.element(at: section)?.count ?? 0
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
        
        if let lmt = albums
            .element(at: indexPath.section)?
            .albumMedia
            .element(at: indexPath.row)
        {
            switch lmt {
            case .success(let media):
                let asset = media.localAsset
                cell.label1.text = media.id
                
                imageManager.requestImage(
                    for: asset,
                    targetSize: CGSize(width: 500, height: 500),
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
            .map(LMTResult.init)
        
        return Album.builder()
            .with(name: "Error media")
            .add(media: media)
            .build()
    }
}
