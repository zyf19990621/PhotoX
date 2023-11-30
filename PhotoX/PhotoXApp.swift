//
//  PhotoXApp.swift
//  PhotoX
//
//  Created by Zhang Yuf on 2023/9/26.
//

import SwiftUI

@main
struct PhotoXApp: App {
    @StateObject private var model = DataModel()
    
    init() {
        UINavigationBar.applyCustomAppearance()
        // 设置启动页展示时间
        Thread.sleep(forTimeInterval: 3.0)
    }
    
    var body: some Scene {
        WindowGroup {
            PhotoCollectionView(photoCollection: model.photoCollection)
                .task {
                    await model.loadPhotos()
                }
        }
    }
}

fileprivate extension UINavigationBar {
    static func applyCustomAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light ? UIColor(hex: 0xffffff) : UIColor(hex: 0x1a1a1a)
        })
        
        appearance.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 19)]
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
