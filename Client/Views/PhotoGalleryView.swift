//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//

import SwiftUI

struct PhotoGalleryView: View {

    let images: [UIImage]
    @State var selectedIndex: Int

    @Environment(\.dismiss) private var dismiss
    
   
    var body: some View {

        ZStack {

            Color.black.ignoresSafeArea()

            TabView(selection: $selectedIndex) {

                ForEach(Array(images.enumerated()), id: \.offset) { index, image in

                    ZoomableImageView(image: image)
                        .tag(index)
                        .contentShape(Rectangle()) // 🔥 IMPORTANT FIX
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onTapGesture {
                dismiss()
            }
        }
    }
}
