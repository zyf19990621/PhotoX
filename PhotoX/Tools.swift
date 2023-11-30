//
//  Tools.swift
//  PhotoX
//
//  Created by Zhang Yuf on 2023/11/30.
//

import SwiftUI

// MARK: 蒙层
struct MaskView: View {
    var bgColor: Color
    var alpha: Double
    var body: some View {
        VStack {
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(bgColor)
        .edgesIgnoringSafeArea(.all)
        .opacity(1 - alpha)
    }
}
