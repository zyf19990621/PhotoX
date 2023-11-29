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
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    @Environment(\.dismiss) var dismiss
    @Environment(\.undoManager) var undoManager
    private let imageSize = CGSize(width: 1024, height: 1024)
    
    /// 所展示图片在collection中位置
    @State var index: Int
    
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
                correctPosition()
                if dragHorizontal && value.translation.width < -60 { //从右往左轻扫
                    Task {
                        await showNextPhoto()
                        guard index < photoCollection.photoAssets.count - 1 else { return }
                        undoManager?.registerUndo(withTarget: photoCollection, handler: { photoCollection in
                            Task {
                                await self.showPrevPhoto()
                            }
                        })
                    }
                } else if dragHorizontal && value.translation.width > 60 { //从左往右
                    Task {
                        await showPrevPhoto()
                        guard index > 0 else { return }
                        undoManager?.registerUndo(withTarget: photoCollection, handler: { photoCollection in
                            Task {
                                await self.showNextPhoto()
                            }
                        })
                    }
                } else if dragVertical && value.translation.height < -60 { //自下而上滑动
                    Task {
                        await photoCollection.deleteImage(asset)
                        await showNextPhoto()
                        undoManager?.registerUndo(withTarget: photoCollection, handler: { photoCollection in
                            Task {
                                await photoCollection.revertLastTrash()
                                await self.showPrevPhoto()
                            }
                        })
                    }
                } else if dragVertical && value.translation.height > 60 { //自上而下
                    
                } else { }
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    undoManager?.undo()
                } label: {
                    Label("Delete", systemImage: "arrow.counterclockwise.circle")
                        .font(.system(size: 18, weight: .medium))
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
//                    await reloadPhoto()
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

private extension PhotoView {
    func showPrevPhoto() async {
        guard let cache = cache, index > 0 else { return }
        let tempIndex = index
        let tempAsset = asset
        repeat {
            index -= 1
            asset = photoCollection.photoAssets[index]
        } while asset.isTrash && index > 0
        
        guard !asset.isTrash else { //往前所有图片均放入“废纸篓”，则恢复index和asset为当前图片
            index = tempIndex
            asset = tempAsset
            return
        }
        imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
            Task {
                if let result = result {
                    self.image = result.image
                }
            }
        }
    }
    
    func showNextPhoto() async {
        guard let cache = cache else { return }
        //TODO: 展示占位图“没有更多照片”
        guard index < photoCollection.photoAssets.count - 1 else { return }
        let tempIndex = index
        let tempAsset = asset
        repeat {
            index += 1
            asset = photoCollection.photoAssets[index]
        } while asset.isTrash && index < photoCollection.photoAssets.count - 1
        guard !asset.isTrash else { //展示占位图“没有更多照片”，index还原
            index = tempIndex
            asset = tempAsset
            return
        }
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
    
    func correctPosition() {
        guard let currentIndex = photoCollection.photoAssets.firstIndex(of: asset),
              currentIndex != index else { return }
        index = currentIndex
    }
}


