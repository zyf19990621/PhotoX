//
//  TrashCollectionView.swift
//
//
//  Created by Zhang Yuf on 2023/9/18.
//

import SwiftUI

struct TrashCollectionView: View {
    @ObservedObject var photoCollection : PhotoCollection
    
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) var dismiss
        
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
                    ForEach(photoCollection.trashPhotoAssets) {  asset in
                        photoItemView(asset: asset)
                        .buttonStyle(.borderless)
                        .accessibilityLabel(asset.accessibilityLabel)
                    }
                }
                .padding([.vertical], Self.itemSpacing)
            }
            .background(Color(uiColor: UIColor(dynamicProvider: { trait in
                trait.userInterfaceStyle == .light ? UIColor(hex: 0xF7F7F7) : UIColor(hex: 0x0A0A0A)
            })))
            .navigationTitle(photoCollection.albumName ?? "废纸篓")
//            .toolbarBackground(.red, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("全部删除", role: .destructive) {
                        Task {
                            await photoCollection.deleteAllTrashPhotos()
                            await MainActor.run {
                                dismiss()
                            }
                        }
                    }
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

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TrashCollectionView(photoCollection: DataModel().photoCollection)
    }
}

