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
    // Роботи чи референси — окремі стрічки
    var kind: ClientPhotoKind = .work

    // Для референсів — дата запису, до якого їх надіслали
    @Query private var appointments: [Appointment]

    @Environment(\.modelContext) private var context
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var profession: ProfessionManager

    // Дія з меню «⋯» стосується всього допису (для окремого фото — це допис з одного фото)
    @State private var editing: ClientPhotoPost?
    @State private var deleting: ClientPhotoPost?
    @State private var didScroll = false

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // Той самий порядок, що й у сітці: нові дописи першими
    private var posts: [ClientPhotoPost] {
        ClientPhotoPost.group(client.photos, kind: kind)
    }

    // Яке фото зараз видно в кожному дописі-каруселі (postID → номер)
    @State private var pages: [UUID: Int] = [:]

    var body: some View {

        ScrollViewReader { proxy in

            ScrollView {

                LazyVStack(spacing: 18) {
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
        .sheet(item: $editing) { item in
            ClientPhotoEditorView(
                drafts: item.photos.enumerated().compactMap { index, photo in
                    ClientPhotoStorage.loadImage(from: photo.fileName).map {
                        ClientPhotoDraft(image: $0, stage: photo.stage, caption: index == 0 ? (item.caption ?? "") : "")
                    }
                },
                showsStages: profession.config.showsPhotoStages && kind == .work,
                isEditingExisting: true,
                sharedCaption: true
            ) { drafts, _ in
                ClientPhotoService.updatePost(
                    item.photos,
                    stages: drafts.map(\.stage),
                    caption: drafts.first?.caption,
                    context: context
                )
            }
        }
        .alert(
            localization.localizedString(for: deleting?.isCarousel == true ? "photos.deletePost.title" : "clients.deletePhotoTitle"),
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
        ) {
            Button(localization.localizedString(for: "common.cancel"), role: .cancel) {
                deleting = nil
            }
            Button(localization.localizedString(for: "common.delete"), role: .destructive) {
                if let item = deleting {
                    ClientPhotoService.deletePost(item.photos, client: client, context: context)
                }
                deleting = nil
            }
        } message: {
            if let item = deleting, item.isCarousel {
                Text(String(format: localization.localizedString(for: "photos.deletePost.message"), item.photos.count))
            } else {
                Text(localization.localizedString(for: "clients.deletePhotoMessage"))
            }
        }
    }

    // MARK: - POST

    private func post(_ item: ClientPhotoPost) -> some View {

        // Як в Instagram: спершу фото, під ним — дата, «⋯» і підпис цього ж допису,
        // далі роздільна лінія — тож одразу видно, до якого фото що належить
        let index = min(pages[item.id] ?? 0, item.photos.count - 1)
        let photo = item.photos[index]

        return VStack(alignment: .leading, spacing: 10) {

            if item.isCarousel {
                // Допис з кількох фото: гортаються вбік, як карусель в Instagram
                TabView(selection: Binding(
                    get: { index },
                    set: { pages[item.id] = $0 }
                )) {
                    ForEach(Array(item.photos.enumerated()), id: \.element.id) { offset, photo in
                        FeedPhotoImage(fileName: photo.fileName, fixedPortrait: true)
                            .overlay(alignment: .topLeading) { stageBadge(photo) }
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .aspectRatio(4 / 5, contentMode: .fit)
                // «2/3» — на самому фото, як в Instagram
                .overlay(alignment: .topTrailing) {
                    Text("\(index + 1)/\(item.photos.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.55)))
                        .padding(10)
                }
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
                    .overlay(alignment: .topLeading) { stageBadge(photo) }
            }

            VStack(alignment: .leading, spacing: 6) {

                HStack(spacing: 8) {
                    Text(AppFormatting.date(item.cover.createdAt, locale: localization.locale, format: .medium))
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                    if let visit = visit(for: item.cover) {
                        Text("· " + String(
                            format: localization.localizedString(for: "photos.references.forVisit"),
                            AppFormatting.template("dMMMM", visit.startDate, locale: localization.locale)
                        ))
                        .font(.caption)
                        .foregroundColor(colors.accent)
                    }
                    Spacer()
                    menu(item, current: photo)
                }

                if let caption = item.caption {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundColor(colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("photo.caption")
                }
            }
            .padding(.horizontal)

            // Межа між дописами
            Rectangle()
                .fill(colors.divider)
                .frame(height: 1)
                .padding(.top, 10)
        }
    }

    private func visit(for photo: ClientPhoto) -> Appointment? {
        guard photo.kind == .reference, let id = photo.appointmentID else { return nil }
        return appointments.first { $0.id == id }
    }

    @ViewBuilder
    private func stageBadge(_ photo: ClientPhoto) -> some View {
        if let stage = photo.stage {
            ClientPhotoStageBadge(stage: stage)
                .padding(10)
        }
    }

    // Зберегти й поділитися — фото, яке зараз видно; змінити й видалити — увесь допис
    private func menu(_ item: ClientPhotoPost, current photo: ClientPhoto) -> some View {
        Menu {
            Button {
                editing = item
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
                deleting = item
            } label: {
                Label(
                    localization.localizedString(for: item.isCarousel ? "photos.deletePost" : "common.delete"),
                    systemImage: "trash"
                )
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
