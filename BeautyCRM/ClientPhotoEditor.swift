//
//  ClientPhotoEditor.swift
//  BeautyCRM
//
//  Фото клієнта як в Instagram: вибрані фото спершу відкриваються тут —
//  позначка «До / Після» і підпис для кожного, — і лише після «Додати» потрапляють у сітку.
//  Той самий екран редагує позначку й підпис уже доданого фото (меню «⋯» у стрічці).
//

import SwiftUI


// Одне фото, яке ще редагується
struct ClientPhotoDraft: Identifiable {
    let id = UUID()
    let image: UIImage
    var stage: ClientPhotoStage?
    var caption: String
}


struct ClientPhotoEditorView: View {

    @State var drafts: [ClientPhotoDraft]
    // Позначки «До / Після» показуємо, якщо вони має сенс для спеціалізації (або вже стоять)
    let showsStages: Bool
    // «Нові фото» чи «Редагувати фото» — заголовок і кнопка
    var isEditingExisting = false
    // asPost — true, якщо майстер вибрав «Одним дописом»
    let onDone: ([ClientPhotoDraft], _ asPost: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @State private var page = 0
    @State private var askHowToAdd = false

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var title: String {
        if isEditingExisting {
            return localization.localizedString(for: "photos.edit.title")
        }
        guard drafts.count > 1 else {
            return localization.localizedString(for: "photos.new.titleOne")
        }
        return String(format: localization.localizedString(for: "photos.new.titleMany"), page + 1, drafts.count)
    }

    var body: some View {

        NavigationStack {

            TabView(selection: $page) {
                ForEach(drafts.indices, id: \.self) { index in
                    draftPage(index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: drafts.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .background(colors.background)
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localizedString(for: "common.cancel")) {
                        dismiss()
                    }
                    .accessibilityIdentifier("photos.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.localizedString(for: isEditingExisting ? "common.save" : "photos.new.add")) {
                        // Кілька нових фото — спитати, як додати: одним дописом чи окремо
                        if !isEditingExisting && drafts.count > 1 {
                            askHowToAdd = true
                        } else {
                            onDone(drafts, false)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("photos.add")
                }
            }
        }
        // Випадковий свайп униз не губить вибрані фото й підписи
        .interactiveDismissDisabled()
        .confirmationDialog(
            String(format: localization.localizedString(for: "photos.howToAdd.title"), drafts.count),
            isPresented: $askHowToAdd,
            titleVisibility: .visible
        ) {
            Button(localization.localizedString(for: "photos.howToAdd.post")) {
                onDone(drafts, true)
                dismiss()
            }
            .accessibilityIdentifier("photos.addAsPost")
            Button(localization.localizedString(for: "photos.howToAdd.separate")) {
                onDone(drafts, false)
                dismiss()
            }
            .accessibilityIdentifier("photos.addSeparately")
            Button(localization.localizedString(for: "common.cancel"), role: .cancel) {}
        } message: {
            Text(localization.localizedString(for: "photos.howToAdd.message"))
        }
    }

    private func draftPage(_ index: Int) -> some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 14) {

                // Рамка 4:5, як пост в Instagram: високе чи широке фото обрізається по краях,
                // а позначки й підпис завжди видно під ним
                Color.clear
                    .aspectRatio(4 / 5, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Image(uiImage: drafts[index].image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .cornerRadius(12)
                    .overlay(alignment: .topLeading) {
                        if let stage = drafts[index].stage {
                            ClientPhotoStageBadge(stage: stage)
                                .padding(10)
                        }
                    }

                if showsStages || drafts[index].stage != nil {
                    HStack(spacing: 8) {
                        ForEach(ClientPhotoStage.allCases, id: \.self) { stage in
                            stageChip(stage, index: index)
                        }
                    }
                }

                TextField(
                    localization.localizedString(for: "clients.photo.addCaption"),
                    text: $drafts[index].caption,
                    axis: .vertical
                )
                .lineLimit(1...4)
                .foregroundColor(colors.textPrimary)
                .padding(12)
                .background(colors.card)
                .cornerRadius(12)
                .accessibilityIdentifier("photos.caption")
                .onChange(of: drafts[index].caption) { _, text in
                    if text.count > ClientPhotoService.captionLimit {
                        drafts[index].caption = String(text.prefix(ClientPhotoService.captionLimit))
                    }
                }
            }
            .padding()
            .padding(.bottom, drafts.count > 1 ? 30 : 0)
        }
    }

    // Повторний дотик знімає позначку
    private func stageChip(_ stage: ClientPhotoStage, index: Int) -> some View {
        let selected = drafts[index].stage == stage
        return Button {
            drafts[index].stage = selected ? nil : stage
        } label: {
            Text(localization.localizedString(for: stage.localizationKey))
                .font(.subheadline.weight(.medium))
                .foregroundColor(selected ? .white : colors.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(selected ? colors.buttonPrimary : colors.card))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("photos.stage.\(stage.rawValue)")
    }
}


// Позначка «До / Після» — однакова на мініатюрі, у стрічці й у редакторі
struct ClientPhotoStageBadge: View {

    let stage: ClientPhotoStage
    var compact = false

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        Text(localization.localizedString(for: stage.localizationKey))
            .font((compact ? Font.caption2 : Font.caption).weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, compact ? 7 : 9)
            .padding(.vertical, compact ? 3 : 4)
            .background(
                Capsule().fill(
                    stage == .after
                        ? theme.colors(for: theme.currentTheme).buttonPrimary
                        : Color.black.opacity(0.6)
                )
            )
    }
}
