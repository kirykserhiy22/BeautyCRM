//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//
import SwiftUI
import PhotosUI
import SwiftData

struct ClientPhotoGridSection: View {

    let client: Client

    @EnvironmentObject var theme: ThemeManager
    @Environment(\.modelContext) private var context

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var sortedPhotos: [ClientPhoto] {
        client.photos.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - STATE

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedPhoto: ClientPhoto?
    @State private var showViewer = false
    @State private var showDeleteAlert = false

    @State private var thumbnails: [String: UIImage] = [:]

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            header

            grid
        }
        .onAppear {
            preloadThumbnails()
        }
        .sheet(isPresented: $showViewer) {

            PhotoGalleryView(
                images: sortedPhotos.compactMap {
                    ClientPhotoStorage.loadImage(from: $0.fileName)
                },
                selectedIndex: sortedPhotos.firstIndex(where: {
                    $0.id == selectedPhoto?.id
                }) ?? 0
            )
        }
        .alert("Delete photo?", isPresented: $showDeleteAlert) {

            Button("Cancel", role: .cancel) { }

            Button("Delete", role: .destructive) {
                if let photo = selectedPhoto {
                    deletePhoto(photo)
                }
            }

        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - HEADER

    private var header: some View {

        HStack {

            Text("Photos")
                .font(.headline)

            Spacer()

            PhotosPicker(
                selection: $selectedItems,
                matching: .images
            ) {
                Image(systemName: "plus")
            }
            .onChange(of: selectedItems) { _, newItems in
                loadImages(from: newItems)
            }
        }
    }

    // MARK: - GRID (FIXED v3 STYLE)

    private var grid: some View {

        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 4),
                count: 3
            ),
            spacing: 4
        ) {

            ForEach(sortedPhotos, id: \.id) { photo in

                photoCell(photo)
            }
        }
    }

    // MARK: - CELL (IMPORTANT FIX)

    @ViewBuilder
    private func photoCell(_ photo: ClientPhoto) -> some View {

        let key = photo.fileName

        if let image = thumbnails[key] {

            imageView(image, photo: photo)

        } else {

            Rectangle()
                .fill(.gray.opacity(0.1))
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .task {
                    await loadThumbnail(for: photo)
                }
        }
    }

    private func imageView(_ image: UIImage, photo: ClientPhoto) -> some View {

        Image(uiImage: image)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                selectedPhoto = photo
                showViewer = true
            }
            .contextMenu {

                Button {
                    savePhotoToLibrary(photo)
                } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                }

                Button {
                    sharePhoto(photo)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button(role: .destructive) {
                    selectedPhoto = photo
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    // MARK: - THUMBNAIL LOADING (v3 CORE FIX)

    private func loadThumbnail(for photo: ClientPhoto) async {

        let key = photo.fileName

        guard thumbnails[key] == nil else { return }

        if let image = await PhotoRenderService.loadThumbnailAsync(fileName: key) {

            await MainActor.run {
                thumbnails[key] = image
            }
        }
    }

    private func preloadThumbnails() {

        let firstBatch = sortedPhotos.prefix(20)

        Task {
            for photo in firstBatch {
                _ = await PhotoRenderService.loadThumbnailAsync(fileName: photo.fileName)
            }
        }
    }

    // MARK: - ACTIONS

    private func deletePhoto(_ photo: ClientPhoto) {

        ClientPhotoService.deletePhoto(
            photo: photo,
            client: client,
            context: context
        )
    }

    private func sharePhoto(_ photo: ClientPhoto) {

        guard let image = ClientPhotoStorage.loadImage(from: photo.fileName) else {
            return
        }

        let controller = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .rootViewController?
            .present(controller, animated: true)
    }

    private func savePhotoToLibrary(_ photo: ClientPhoto) {

        guard let image = ClientPhotoStorage.loadImage(from: photo.fileName) else {
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    // MARK: - UPLOAD

    private func loadImages(from items: [PhotosPickerItem]) {

        guard !items.isEmpty else { return }

        Task {

            for item in items {

                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {

                    await MainActor.run {
                        ClientPhotoService.addPhoto(
                            image: uiImage,
                            client: client,
                            context: context
                        )
                    }
                }
            }

            await MainActor.run {
                selectedItems = []
            }
        }
    }
}
