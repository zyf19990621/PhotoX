//
//  PhotoCollectionView.swift
//  PhotoX
//
//  Created by Zhang Yuf on 2023/9/26.
//

import SwiftUI
import os.log

struct PhotoCollectionView: View {
    @ObservedObject var photoCollection : PhotoCollection
    
    @Environment(\.displayScale) private var displayScale
        
    private static let itemSpacing = 3.0
    private static let itemCornerRadius = 2.0
    private static let numbersInLine = 3
    private static let itemWidth = (UIScreen.main.bounds.width - CGFloat(numbersInLine - 1) * itemSpacing) / CGFloat(numbersInLine)
    private static let itemSize = CGSize(width: itemWidth, height: itemWidth)
    
    private var imageSize: CGSize {
        return CGSize(width: Self.itemSize.width * min(displayScale, 2), height: Self.itemSize.height * min(displayScale, 2))
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: itemSpacing)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Self.itemSpacing) {
                    ForEach(photoCollection.photoAssets) { asset in
                        if !asset.isTrash {
                            NavigationLink {
                                PhotoView(photoCollection: photoCollection, asset: asset, cache: photoCollection.cache, index: asset.index ?? 0)
                            } label: {
                                photoItemView(asset: asset)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(asset.accessibilityLabel)
                        }
                    }
                }
                .padding([.vertical], Self.itemSpacing)
            }
            .background(Color(uiColor: UIColor(dynamicProvider: { trait in
                trait.userInterfaceStyle == .light ? UIColor(hex: 0xF7F7F7) : UIColor(hex: 0x0A0A0A)
            })))
            .navigationTitle(photoCollection.albumName ?? "图库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                NavigationLink {
                    TrashCollectionView(photoCollection: photoCollection)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primary)
                }

            })
            .statusBar(hidden: false)
        }
    }
    
    private func photoItemView(asset: PhotoAsset) -> some View {
        PhotoItemView(asset: asset, cache: photoCollection.cache, imageSize: imageSize)
            .frame(width: Self.itemSize.width, height: Self.itemSize.height)
            .clipped()
            .cornerRadius(Self.itemCornerRadius)
            .overlay(alignment: .bottomLeading) {
                if asset.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 1)
                        .font(.callout)
                        .offset(x: 4, y: -4)
                }
            }
            .onAppear {
                Task {
                    await photoCollection.cache.startCaching(for: [asset], targetSize: imageSize)
                }
            }
            .onDisappear {
                Task {
                    await photoCollection.cache.stopCaching(for: [asset], targetSize: imageSize)
                }
            }
    }
}


extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat(CGFloat((hex & 0xFF0000) >> 16)/255.0)
        let green = CGFloat(CGFloat((hex & 0x00FF00) >> 8)/255.0)
        let blue = CGFloat(CGFloat((hex & 0x0000FF) >> 0)/255.0)
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
