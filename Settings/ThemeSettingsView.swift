//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 13.05.26.
//

import SwiftUI

struct ThemeSettingsView: View {
    
    @EnvironmentObject var theme: ThemeManager
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    var body: some View {
        
        ScrollView {
            
            VStack(
                alignment: .leading,
                spacing: 20
            ) {
                
                Text("Appearance")
                    .font(.largeTitle.bold())
                    .foregroundColor(colors.textPrimary)
                
                Text("Choose app theme")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                
                VStack(spacing: 14) {
                    
                    ForEach(
                        AppTheme.allCases,
                        id: \.self
                    ) { themeCase in
                        
                        ThemePreviewCard(
                            themeCase: themeCase,
                            isSelected:
                                theme.currentTheme == themeCase
                        ) {
                            
                            withAnimation(.easeInOut) {

                                theme.setTheme(themeCase)


                               
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(colors.background)
    }
}

// MARK: - PREVIEW CARD

struct ThemePreviewCard: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    let themeCase: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    private var colors: ThemeColors {
        themeManager.colors(for: themeCase)
    }
    
    var body: some View {
        
        Button {
            
            onTap()
            
        } label: {
            
            VStack(
                alignment: .leading,
                spacing: 16
            ) {
                
                // HEADER
                
                HStack {
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        
                        Image(
                            systemName:
                                "checkmark.circle.fill"
                        )
                        .foregroundColor(colors.accent)
                    }
                }
                
                // PREVIEW
                
                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colors.card)
                        .frame(height: 70)
                        .overlay(
                            VStack(
                                alignment: .leading,
                                spacing: 8
                            ) {
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(colors.textPrimary)
                                    .frame(width: 90, height: 10)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(colors.textSecondary)
                                    .frame(width: 140, height: 8)
                                
                                HStack(spacing: 8) {
                                    
                                    Circle()
                                        .fill(colors.accent)
                                        .frame(width: 12)
                                    
                                    Circle()
                                        .fill(colors.success)
                                        .frame(width: 12)
                                    
                                    Circle()
                                        .fill(colors.danger)
                                        .frame(width: 12)
                                }
                            }
                            .padding()
                        )
                    
                    HStack(spacing: 10) {
                        
                        colorDot(colors.background)
                        colorDot(colors.card)
                        colorDot(colors.accent)
                        colorDot(colors.textPrimary)
                    }
                }
            }
            .padding()
            .background(colors.cardSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected
                        ? colors.accent
                        : colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(20)
            .shadow(
                color: colors.shadow,
                radius: 6,
                y: 3
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - HELPERS
    
    private func colorDot(
        _ color: Color
    ) -> some View {
        
        Circle()
            .fill(color)
            .frame(width: 18)
            .overlay(
                Circle()
                    .stroke(
                        colors.border,
                        lineWidth: 1
                    )
            )
    }
    
    private var title: String {
        
        switch themeCase {
            
        case .classic:
            return "Classic"
            
        case .graphite:
            return "Graphite"
            
        case .pearlivory:
            return "Pearl Ivory"
        }
    }
}
