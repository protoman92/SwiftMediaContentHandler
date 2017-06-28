# SwiftMediaContentHandler
Media Content Handler for **PHPhotoLibrary**. Based on RxSwift.

![](https://travis-ci.org/protoman92/SwiftMediaContentHandler.svg?branch=master)

This library provides a few convenient classes that abstract most of the work needed to handle media fetching in iOS development:

## LocalMediaDatabase: 
This class provides a convenient Observable to load local **PHAsset** instances. Simply feed it with the **MediaType** (.image, .audio, .video) and the **MediaCollectionType** (.album, .smartAlbum, .moment), one by one or as an **Array**, subscribe to **LocalMediaDatabase.mediaObservable** and call **LocalMediaDatabase.loadInitialAlbums()** to start receiving updates. If **PHPhotoLibrary** permission has yet to be granted, it will automatically ask the user to do so.

For example:

> let mediaDatabase = LocalMediaDatabase.builder()
  .add(mediaTypes: .image, .audio, .video)
  .add(collectionTypes: .album, .smartAlbum, .moment)
  .build()
  
And then subscribe to the listener **Observable**:

> mediaDatabase.mediaObservable.subscribe()

Finally, load initial albums and set up the Change Observer:

> mediaDatabase.loadInitialAlbums()

If permission is denied at this stage, an Error will be thrown.

# Installation

This library requires CocoaPods. Please use:

> pod 'SwiftMediaContentHandler'

for the appropriate build targets.
