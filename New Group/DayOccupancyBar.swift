
import SwiftUI

struct DayOccupancyBar: View {
    
    let segments: [DayOccupancySegment]
    
    let hasEarly: Bool
    let hasLate: Bool
    
    @EnvironmentObject var theme: ThemeManager
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    var body: some View {
        
        HStack(spacing: 1) {
            
            // EARLY
            
            if hasEarly {
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 4, height: 4)
            }
            
            // MAIN TIMELINE
            
            HStack(spacing: 1) {
                
                ForEach(
                    Array(segments.enumerated()),
                    id: \.offset
                ) { _, segment in
                    
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color(for: segment))
                        .frame(height: 4)
                }
            }
            
            // LATE
            
            if hasLate {
                
                Circle()
                    .fill(Color.purple)
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    private func color(
        for segment: DayOccupancySegment
    ) -> Color {
        
        switch segment {
            
        case .empty:
            return colors.cardSecondary
            
        case .occupied:
            return colors.accent
            
        case .early:
            return .orange
            
        case .late:
            return .purple
        }
    }
}
