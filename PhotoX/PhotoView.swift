//
//  PhotoView.swift
//  PhotoX
//
//  Created by Zhang Yuf on 2023/9/26.
//

import SwiftUI
import Photos

struct PhotoView: View {
    @ObservedObject var photoCollection : PhotoCollection
    @State var asset: PhotoAsset
    var cache: CachedImageManager?
    @State var index: Int
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    @Environment(\.dismiss) var dismiss
    private let imageSize = CGSize(width: 1024, height: 1024)
    
    @State private var dragOffset = CGSize.zero
    @State private var dragHorizontal = false
    @State private var dragVertical = false
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .offset(dragOffset)
                    .accessibilityLabel(asset.accessibilityLabel)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.5), value: image)
        .gesture(DragGesture(minimumDistance: 10.0, coordinateSpace: .global)
            .onChanged({ value in
                if dragHorizontal {
                    dragOffset = CGSize(width: value.translation.width, height: 0)
                } else if dragVertical {
                    dragOffset = value.translation
                } else if abs(value.translation.width) > abs(value.translation.height) {
                    dragOffset = CGSize(width: value.translation.width, height: 0)
                    dragHorizontal = true
                } else {
                    dragOffset = value.translation
                    dragVertical = true
                }
            })
            .onEnded { value in
                print(value.translation)
                if dragHorizontal && value.translation.width < -60 {
                    print("left swipe")
                    Task {
                        await showNextPhoto()
                    }
                } else if dragHorizontal && value.translation.width > 60 {
                    print("right swipe")
                    Task {
                        await showPrevPhoto()
                    }
                } else if dragVertical && value.translation.height < -60 {
                    print("up swipe")
                    Task {
                        await photoCollection.deleteImage(asset)
                        await reloadPhoto()
                    }
                } else if dragVertical && value.translation.height > 60 {
                    print("down swipe")
                } else { print("no clue") }
                dragOffset = .zero
                dragHorizontal = false
                dragVertical = false
            }
        )
        .ignoresSafeArea()
        .navigationTitle("照片")
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
                NavigationLink {
                    TrashCollectionView(photoCollection: photoCollection)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primary)
                }
            }
        })
        .overlay(alignment: .bottom) {
            buttonsView()
                .offset(x: 0, y: -50)
        }
        .task {
            guard image == nil, let cache = cache else { return }
            imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
                Task {
                    if let result = result {
                        self.image = result.image
                    }
                }
            }
        }
    }
    
    private func buttonsView() -> some View {
        HStack(spacing: 60) {
            Button {
                Task {
                    await asset.setIsFavorite(!asset.isFavorite)
                }
            } label: {
                Label("Favorite", systemImage: asset.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 24))
            }

            Button {
                Task {
                    await asset.delete()
                    await MainActor.run {
                        dismiss()
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.system(size: 24))
            }
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
        .background(Color.secondary.colorInvert())
        .cornerRadius(15)
    }
}

extension PhotoView {
    func showPrevPhoto() async {
        guard let cache = cache, index > 0 else { return }
        index -= 1
        asset = photoCollection.photoAssets[index]
        imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
            Task {
                if let result = result {
                    self.image = result.image
                }
            }
        }
    }
    
    func showNextPhoto() async {
        guard let cache = cache, index < photoCollection.photoAssets.count - 1 else { return }
        index += 1
        asset = photoCollection.photoAssets[index]
        imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
            Task {
                if let result = result {
                    self.image = result.image
                }
            }
        }
    }
    
    func reloadPhoto() async {
        guard let cache = cache, index >= 0 && index < photoCollection.photoAssets.count else { return }
        asset = photoCollection.photoAssets[index]
        imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
            Task {
                if let result = result {
                    self.image = result.image
                }
            }
        }
    }
}


