//
//  ReferencePhotos.swift
//  BeautyCRM
//
//  Референси — фото бажаного результату від клієнта (колір, форма нігтів, вигин вій…).
//  ReferenceStrip — рядок мініатюр у картці запису (немає референсів — нічого не показуємо).
//  ReferenceViewer — перегляд на весь екран: гортати вбік, двома пальцями — збільшити.
//

import SwiftUI

struct ReferenceStrip: View {

    let photos: [ClientPhoto]
    let colors: ThemeColors
    let title: String
    let onOpen: (Int) -> Void

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            Label("\(title) · \(photos.count)", systemImage: "photo.on.rectangle")
                .font(.caption.weight(.semibold))
                .foregroundColor(colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        Button {
                            onOpen(index)
                        } label: {
                            Group {
                                if let image = ClientPhotoStorage.loadThumbnail(from: photo.fileName) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    colors.cardSecondary
                                }
                            }
                            .frame(width: 56, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("appointment.reference")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


// Який референс відкрити на весь екран
struct ReferenceViewerStart: Identifiable {
    let index: Int
    var id: Int { index }
}

struct ReferenceViewer: View {

    let photos: [ClientPhoto]
    @State var index: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        ZStack(alignment: .topTrailing) {

            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { offset, photo in
                    Group {
                        if let image = ClientPhotoStorage.loadImage(from: photo.fileName) {
                            ZoomableImageView(image: image)
                        } else {
                            Color.black
                        }
                    }
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.18)))
            }
            .padding()
            .accessibilityIdentifier("reference.close")
        }
    }
}
