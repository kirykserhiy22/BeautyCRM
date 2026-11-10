//
//  PhotoGalleryView.swift
//  BeautyCRM
//
//  Перегляд фото клієнта: гортання, збільшення, підпис і позначка «До/Після».
//

import SwiftUI
import SwiftData


struct PhotoGalleryEntry {
    let photo: ClientPhoto
    let image: UIImage
}


struct PhotoGalleryView: View {

    let entries: [PhotoGalleryEntry]
    @State var selectedIndex: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var profession: ProfessionManager

    @State private var draft = ""
    @FocusState private var isEditing: Bool

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var current: PhotoGalleryEntry? {
        entries.indices.contains(selectedIndex) ? entries[selectedIndex] : nil
    }

    var body: some View {

        VStack(spacing: 0) {

            TabView(selection: $selectedIndex) {

                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in

                    ZoomableImageView(image: entry.image)
                        .tag(index)
                        .contentShape(Rectangle())
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .top)
            .onTapGesture {
                // Перший дотик під час введення лише ховає клавіатуру
                if isEditing {
                    isEditing = false
                } else {
                    dismiss()
                }
            }

            if let current {
                panel(current.photo)
            }
        }
        .presentationBackground(.black)
        .onAppear {
            draft = current?.photo.caption ?? ""
        }
        .onChange(of: selectedIndex) { oldIndex, _ in
            saveDraft(at: oldIndex)
            draft = current?.photo.caption ?? ""
        }
        .onChange(of: isEditing) { _, editing in
            if !editing {
                saveDraft(at: selectedIndex)
            }
        }
        .onDisappear {
            saveDraft(at: selectedIndex)
        }
    }


    // MARK: - PANEL

    // Панель завжди темна, як і сам перегляд фото
    private func panel(_ photo: ClientPhoto) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            // Вже поставлену позначку показуємо навіть після зміни спеціалізації
            if profession.config.showsPhotoStages || photo.stage != nil {
                HStack(spacing: 8) {
                    ForEach(ClientPhotoStage.allCases, id: \.self) { stage in
                        stageButton(stage, photo: photo)
                    }
                }
            }

            TextField(
                "",
                text: $draft,
                prompt: Text(localization.localizedString(for: "clients.photo.addCaption"))
                    .foregroundColor(.white.opacity(0.6)),
                axis: .vertical
            )
            .lineLimit(1...3)
            .focused($isEditing)
            .submitLabel(.done)
            .foregroundColor(.white)
            .tint(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .accessibilityIdentifier("photo.caption")
            .onChange(of: draft) { _, text in
                limitDraft(text)
            }

            Text(AppFormatting.date(photo.createdAt, locale: localization.locale, format: .medium))
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("SplashBackground").ignoresSafeArea())
    }

    private func stageButton(_ stage: ClientPhotoStage, photo: ClientPhoto) -> some View {

        let isSelected = photo.stage == stage

        return Button {
            ClientPhotoService.toggleStage(stage, photo: photo, context: context)
        } label: {
            Text(localization.localizedString(for: stage.localizationKey))
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSelected ? colors.buttonPrimary : Color.white.opacity(0.14))
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("photo.stage.\(stage.rawValue)")
    }


    // MARK: - CAPTION

    // Клавіша «Готово» в багаторядковому полі вставляє перенос: сприймаємо її як завершення
    private func limitDraft(_ text: String) {

        if text.contains("\n") {
            draft = text.replacingOccurrences(of: "\n", with: "")
            isEditing = false
        } else if text.count > ClientPhotoService.captionLimit {
            draft = String(text.prefix(ClientPhotoService.captionLimit))
        }
    }

    private func saveDraft(at index: Int) {

        guard entries.indices.contains(index) else {
            return
        }

        ClientPhotoService.updateCaption(draft, photo: entries[index].photo, context: context)
    }
}
