//
//  PhotoAssetCollection.swift
//  PhotoX
//
//  Created by Zhang Yuf on 2023/9/26.
//

import Photos

class PhotoAssetCollection: RandomAccessCollection {
    private(set) var fetchResult: PHFetchResult<PHAsset>
    private var iteratorIndex: Int = 0
    
    private var cache = [Int : PhotoAsset]()
    
    var startIndex: Int { 0 }
    var endIndex: Int { fetchResult.count }
    
    init(_ fetchResult: PHFetchResult<PHAsset>) {
        self.fetchResult = fetchResult
    }

    subscript(position: Int) -> PhotoAsset {
        if let asset = cache[position] {
            return asset
        }
        let asset = PhotoAsset(phAsset: fetchResult.object(at: position), index: position)
        cache[position] = asset
        return asset
    }
    
    var phAssets: [PHAsset] {
        var assets = [PHAsset]()
        fetchResult.enumerateObjects { (object, count, stop) in
            assets.append(object)
        }
        return assets
    }
    
    func putTrash(at position: Int) {
        if var asset = cache[position] {
            asset.isTrash = true
            cache[position] = asset
            return
        }
        var asset = PhotoAsset(phAsset: fetchResult.object(at: position), index: position)
        asset.isTrash = true
        cache[position] = asset
    }
}

extension PhotoAssetCollection: Sequence, IteratorProtocol {

    func next() -> PhotoAsset? {
        if iteratorIndex >= count {
            return nil
        }
        
        defer {
            iteratorIndex += 1
        }
        
        return self[iteratorIndex]
    }
}
