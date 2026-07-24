//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.05.26.
//

import SwiftUI

struct ZoomableImageView: View {

    let image: UIImage

    // MARK: - Zoom state
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    // MARK: - Pan state
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // MARK: - Gesture state
    @GestureState private var isDragging = false

    var body: some View {

        GeometryReader { geo in

            let minScale: CGFloat = 1
            let maxScale: CGFloat = 4

            ZStack {

                Color.black
                    .ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()

                    // 🔥 KEY FIX: жорстке центрування в контейнері
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height,
                        alignment: .center
                    )

                    .scaleEffect(scale)
                    .offset(offset)

                    // 🔥 важливо для gesture hit area
                    .contentShape(Rectangle())

                    // 🔥 KEY FIX — дозволяє TabView swipe коли scale == 1
                    .highPriorityGesture(
                        dragGesture(
                            minScale: minScale,
                            imageSize: image.size,
                            containerSize: geo.size
                        ),
                        including: scale > 1 ? .gesture : .none
                    )

                    // pinch always active
                    .simultaneousGesture(
                        magnificationGesture(minScale: minScale, maxScale: maxScale)
                    )

                    // double tap reset/zoom
                    .onTapGesture(count: 2) {
                        withAnimation(.spring) {
                            if scale > 1 {
                                reset()
                            } else {
                                zoomToCenter()
                            }
                        }
                    }
            }
        }
    }

    // MARK: - RESET

    private func reset() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }

    private func zoomToCenter() {
        scale = 3
        lastScale = 3
    }

    // MARK: - DRAG

    private func dragGesture(minScale: CGFloat, imageSize: CGSize, containerSize: CGSize) -> some Gesture {

        DragGesture(minimumDistance: 10)
            .onChanged { value in

                guard scale > minScale else { return }

                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )

                offset = clampOffset(
                    proposed,
                    scale: scale,
                    imageSize: imageSize,
                    containerSize: containerSize
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
    
    private func clampOffset(_ proposed: CGSize, scale: CGFloat, imageSize: CGSize, containerSize: CGSize) -> CGSize {

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        let maxX = max((scaledWidth - containerSize.width) / 2, 0)
        let maxY = max((scaledHeight - containerSize.height) / 2, 0)

        let clampedX = min(max(proposed.width, -maxX), maxX)
        let clampedY = min(max(proposed.height, -maxY), maxY)

        return CGSize(width: clampedX, height: clampedY)
    }

    // MARK: - PINCH

    private func magnificationGesture(minScale: CGFloat, maxScale: CGFloat) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                scale = min(max(newScale, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale

                if scale < 1 {
                    reset()
                }
            }
    }
}
