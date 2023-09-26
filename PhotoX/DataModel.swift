//
//  DataModel.swift
//  PhotoX
//
//  Created by Zhang Yuf on 2023/9/26.
//

import AVFoundation
import SwiftUI
import os.log

final class DataModel: ObservableObject {
    let photoCollection = PhotoCollection(smartAlbum: .smartAlbumUserLibrary)
    var isPhotosLoaded = false
    
    func loadPhotos() async {
        guard !isPhotosLoaded else { return }
        
        let authorized = await PhotoLibrary.checkAuthorization()
        guard authorized else {
            logger.error("Photo library access was not authorized.")
            return
        }
        
        Task {
            do {
                try await self.photoCollection.load()
            } catch let error {
                logger.error("Failed to load photo collection: \(error.localizedDescription)")
            }
            self.isPhotosLoaded = true
        }
    }
}

fileprivate let logger = Logger(subsystem: "com.zyf19990621.git.PhotoX", category: "DataModel")

