//
//  PhotoGalleryView.swift
//  BeautyCRM
//
//  Перегляд фото клієнта як стрічка Instagram: фото одне під одним,
//  над фото позначка «До / Після» і дата, під фото підпис. Двома пальцями — збільшити.
//  «⋯» біля фото: змінити позначку чи підпис, зберегти, поділитися, видалити.
//

import SwiftUI
import SwiftData


struct ClientPhotoFeedView: View {

    let client: Client
    // Фото, на якому відкрити стрічку (те, по якому тапнули в сітці)
    let startPhotoID: UUID?

    @Environment(\.modelContext) private var context
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var profession: ProfessionManager

    @State private var editing: ClientPhoto?
    @State private var deleting: ClientPhoto?
    @State private var didScroll = false

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // Той самий порядок, що й у сітці: нові дописи першими
    private var posts: [ClientPhotoPost] {
        ClientPhotoPost.group(client.photos)
    }

    // Яке фото зараз видно в кожному дописі-каруселі (postID → номер)
    @State private var pages: [UUID: Int] = [:]

    var body: some View {

        ScrollViewReader { proxy in

            ScrollView {

                LazyVStack(spacing: 28) {
                    ForEach(posts) { item in
                        post(item)
                            .id(item.id)
                    }
                }
                .padding(.vertical, 12)
            }
            .onAppear {
                guard !didScroll, let startPhotoID else { return }
                didScroll = true
                proxy.scrollTo(startPhotoID, anchor: .top)
            }
        }
        .background(colors.background)
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { photo in
            if let image = ClientPhotoStorage.loadImage(from: photo.fileName) {
                ClientPhotoEditorView(
                    drafts: [ClientPhotoDraft(image: image, stage: photo.stage, caption: photo.caption ?? "")],
                    showsStages: profession.config.showsPhotoStages,
                    isEditingExisting: true
                ) { drafts, _ in
                    if let draft = drafts.first {
                        ClientPhotoService.update(stage: draft.stage, caption: draft.caption, photo: photo, context: context)
                    }
                }
            }
        }
        .alert(
            localization.localizedString(for: "clients.deletePhotoTitle"),
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
        ) {
            Button(localization.localizedString(for: "common.cancel"), role: .cancel) {
                deleting = nil
            }
            Button(localization.localizedString(for: "common.delete"), role: .destructive) {
                if let photo = deleting {
                    ClientPhotoService.deletePhoto(photo: photo, client: client, context: context)
                }
                deleting = nil
            }
        } message: {
            Text(localization.localizedString(for: "clients.deletePhotoMessage"))
        }
    }

    // MARK: - POST

    private func post(_ item: ClientPhotoPost) -> some View {

        // Позначка, підпис і «⋯» — того фото, яке зараз видно в каруселі
        let index = min(pages[item.id] ?? 0, item.photos.count - 1)
        let photo = item.photos[index]

        return VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 8) {
                if let stage = photo.stage {
                    ClientPhotoStageBadge(stage: stage, compact: true)
                }
                Text(AppFormatting.date(photo.createdAt, locale: localization.locale, format: .medium))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                Spacer()
                if item.isCarousel {
                    Text("\(index + 1)/\(item.photos.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(colors.textSecondary)
                }
                menu(photo)
            }
            .padding(.horizontal)

            if item.isCarousel {
                // Допис з кількох фото: гортаються вбік, як карусель в Instagram
                TabView(selection: Binding(
                    get: { index },
                    set: { pages[item.id] = $0 }
                )) {
                    ForEach(Array(item.photos.enumerated()), id: \.element.id) { offset, photo in
                        FeedPhotoImage(fileName: photo.fileName, fixedPortrait: true)
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .aspectRatio(4 / 5, contentMode: .fit)
                .accessibilityIdentifier("photo.carousel")

                // Крапки під фото
                HStack(spacing: 5) {
                    ForEach(item.photos.indices, id: \.self) { dot in
                        Circle()
                            .fill(dot == index ? colors.accent : colors.textMuted.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                FeedPhotoImage(fileName: photo.fileName)
            }

            if let caption = photo.caption, !caption.isEmpty {
                Text(caption)
                    .font(.subheadline)
                    .foregroundColor(colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .accessibilityIdentifier("photo.caption")
            }
        }
    }

    private func menu(_ photo: ClientPhoto) -> some View {
        Menu {
            Button {
                editing = photo
            } label: {
                Label(localization.localizedString(for: "photos.menu.edit"), systemImage: "pencil")
            }
            Button {
                if let image = ClientPhotoStorage.loadImage(from: photo.fileName) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            } label: {
                Label(localization.localizedString(for: "clients.saveToPhotos"), systemImage: "square.and.arrow.down")
            }
            Button {
                share(photo)
            } label: {
                Label(localization.localizedString(for: "clients.share"), systemImage: "square.and.arrow.up")
            }
            Divider()
            Button(role: .destructive) {
                deleting = photo
            } label: {
                Label(localization.localizedString(for: "common.delete"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundColor(colors.textPrimary)
                .frame(width: 36, height: 28)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text(localization.localizedString(for: "photos.menu")))
        .accessibilityIdentifier("photo.menu")
    }

    private func share(_ photo: ClientPhoto) {
        guard let image = ClientPhotoStorage.loadImage(from: photo.fileName) else {
            return
        }
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(controller, animated: true)
    }
}


// Фото на всю ширину; повне зображення вантажиться у фоні, поки видно мініатюру.
// Двома пальцями — збільшити, відпустив — повертається, як в Instagram.
private struct FeedPhotoImage: View {

    let fileName: String
    // У каруселі всі фото в однаковій рамці 4:5 (інакше висота стрибала б при гортанні)
    var fixedPortrait = false

    @State private var image: UIImage?
    @GestureState private var zoom: CGFloat = 1

    var body: some View {
        Group {
            if let image, fixedPortrait {
                Color.clear
                    .aspectRatio(4 / 5, contentMode: .fit)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .aspectRatio(4 / 5, contentMode: .fit)
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(zoom)
        .zIndex(zoom > 1 ? 1 : 0)
        .gesture(
            MagnifyGesture()
                .updating($zoom) { value, state, _ in
                    state = max(1, min(value.magnification, 4))
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: zoom == 1)
        .task(id: fileName) {
            if image == nil {
                image = ClientPhotoStorage.loadThumbnail(from: fileName)
            }
            // Спершу мініатюра (миттєво), повне фото — наступним кроком, щоб стрічка не гальмувала
            await Task.yield()
            if let full = ClientPhotoStorage.loadImage(from: fileName) {
                image = full
            }
        }
    }
}
