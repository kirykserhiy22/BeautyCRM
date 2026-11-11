//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI
import SwiftData

struct ClientProfileView: View {

    // MARK: - ENV

    @EnvironmentObject var theme: ThemeManager

    // MARK: - DATA

    let client: Client

    // MARK: - UI

    @State private var showEdit = false
    @State private var showBooking = false

    // MARK: - THEME

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // MARK: - BODY

    var body: some View {

        ScrollView {
            

            VStack(spacing: 20) {

                ClientHeaderSection(
                    client: client
                )

                ClientContactSection(
                    client: client
                )

                Button {
                    showBooking = true
                } label: {
                    AuthButtonLabel(
                        title: "clients.book",
                        background: colors.buttonPrimary,
                        foreground: .white
                    )
                }
                .accessibilityIdentifier("client.book")

                ClientAnalyticsSection(
                    client: client
                )

                if let notes = client.notes,
                   !notes.trimmingCharacters(
                        in: .whitespacesAndNewlines
                   ).isEmpty {

                    ClientNotesSection(
                        notes: notes
                    )
                }

                ClientPhotoGridSection(
                    client: client
                )
            }
            .padding()
        }
        .background(colors.background)
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {

                    showEdit = true

                } label: {

                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showBooking) {

            AppointmentFormView(preselectedClientID: client.id)
        }
        .sheet(isPresented: $showEdit) {

            ClientFormView(
                mode: .edit(client)
            )
        }
    }
}
