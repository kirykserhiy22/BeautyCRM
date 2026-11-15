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
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var profession: ProfessionManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var sortedPhotos: [ClientPhoto] {
        client.photos
            .filter { $0.deletedAt == nil }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - STATE

    @State private var selectedItems: [PhotosPickerItem] = []
    // Довге натискання на мініатюру → «Видалити»: видаляється весь допис (для окремого фото — саме фото)
    @State private var postToDelete: ClientPhotoPost?
    // Стрічка відкривається на фото, по якому тапнули
    @State private var feedStart: ClientPhoto?
    // Вибрані в галереї фото чекають на позначку й підпис
    @State private var drafts: [ClientPhotoDraft] = []
    @State private var showEditor = false

    @State private var thumbnails: [String: UIImage] = [:]

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            header

            grid
        }
        .onAppear {
            preloadThumbnails()
        }
        .navigationDestination(item: $feedStart) { photo in
            ClientPhotoFeedView(client: client, startPhotoID: photo.id)
        }
        .sheet(isPresented: $showEditor, onDismiss: { drafts = [] }) {
            ClientPhotoEditorView(
                drafts: drafts,
                showsStages: profession.config.showsPhotoStages
            ) { ready, asPost in
                addPhotos(ready, asPost: asPost)
            }
        }
        .alert(
            localization.localizedString(
                for: postToDelete?.isCarousel == true ? "photos.deletePost.title" : "clients.deletePhotoTitle"
            ),
            isPresented: Binding(get: { postToDelete != nil }, set: { if !$0 { postToDelete = nil } })
        ) {

            Button(
                localization.localizedString(for: "clients.cancel"),
                role: .cancel
            ) {
                postToDelete = nil
            }

            Button(
                localization.localizedString(for: "clients.delete"),
                role: .destructive
            ) {
                if let post = postToDelete {
                    ClientPhotoService.deletePost(post.photos, client: client, context: context)
                }
                postToDelete = nil
            }

        } message: {
            if let post = postToDelete, post.isCarousel {
                Text(String(format: localization.localizedString(for: "photos.deletePost.message"), post.photos.count))
            } else {
                Text(localization.localizedString(for: "clients.deletePhotoMessage"))
            }
        }
    }

    // MARK: - HEADER

    private var header: some View {

        HStack {

            Text(localization.localizedString(for: "clients.photos"))
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

            // Одна клітинка — один допис: окреме фото або карусель
            ForEach(ClientPhotoPost.group(client.photos)) { post in

                photoCell(post)
            }
        }
    }

    // MARK: - CELL (IMPORTANT FIX)

    @ViewBuilder
    private func photoCell(_ post: ClientPhotoPost) -> some View {

        let photo = post.cover
        let isCarousel = post.isCarousel
        let key = photo.fileName

        if let image = thumbnails[key] {

            imageView(image, post: post)
                .overlay(alignment: .topTrailing) {
                    // Як в Instagram: значок, що в дописі кілька фото
                    if isCarousel {
                        Image(systemName: "square.fill.on.square.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                            .padding(6)
                            .accessibilityIdentifier("client.photo.carousel")
                    }
                }

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

    private func imageView(_ image: UIImage, post: ClientPhotoPost) -> some View {

        let photo = post.cover

        return 
Image(uiImage: image)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topLeading) {
                if let stage = photo.stage {
                    ClientPhotoStageBadge(stage: stage, compact: true)
                        .padding(5)
                }
            }
            .onTapGesture {
                feedStart = photo
            }
            .accessibilityIdentifier("client.photo")
            .contextMenu {

                Button {
                    savePhotoToLibrary(photo)
                } label: {
                    Label(
                        localization.localizedString(for: "clients.saveToPhotos"),
                        systemImage: "square.and.arrow.down"
                    )
                }

                Button {
                    sharePhoto(photo)
                } label: {
                    Label(
                        localization.localizedString(for: "clients.share"),
                        systemImage: "square.and.arrow.up"
                    )
                }

                Divider()

                // Як і в стрічці: допис з кількох фото видаляється цілком
                Button(role: .destructive) {
                    postToDelete = post
                } label: {
                    Label(
                        localization.localizedString(for: post.isCarousel ? "photos.deletePost" : "clients.delete"),
                        systemImage: "trash"
                    )
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

    // Вибрані фото спершу йдуть у редактор (позначка «До / Після», підпис), а не одразу в сітку
    private func loadImages(from items: [PhotosPickerItem]) {

        guard !items.isEmpty else { return }

        Task {

            var loaded: [ClientPhotoDraft] = []

            for item in items {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = await Task.detached(priority: .userInitiated, operation: { UIImage(data: data) }).value
                else {
                    continue
                }
                loaded.append(ClientPhotoDraft(image: image, stage: nil, caption: ""))
            }

            selectedItems = []

            if !loaded.isEmpty {
                drafts = loaded
                showEditor = true
            }
        }
    }

    // «Додати» в редакторі: JPEG і мініатюра — у фоні (#39), запис у базу — тут.
    // Окремо: перше вибране фото стає найновішим (першим у сітці), як в Instagram.
    // Одним дописом: спільний postID, фото в порядку вибору (так їх гортатимуть).
    private func addPhotos(_ ready: [ClientPhotoDraft], asPost: Bool) {

        let postID: UUID? = asPost ? UUID() : nil
        let ordered = asPost ? ready : ready.reversed()
        // Допис має один підпис — на першому фото
        let postCaption = asPost ? ClientPhotoService.postCaption(ready.map(\.caption)) : nil

        Task {
            for (index, draft) in ordered.enumerated() {
                let image = draft.image
                let fileName = await Task.detached(priority: .userInitiated) {
                    ClientPhotoService.storeFiles(for: image)
                }.value

                if let fileName {
                    ClientPhotoService.addPhoto(
                        fileName: fileName,
                        stage: draft.stage,
                        caption: asPost ? (index == 0 ? postCaption : nil) : draft.caption,
                        postID: postID,
                        client: client,
                        context: context
                    )
                }
            }
        }
    }
}
