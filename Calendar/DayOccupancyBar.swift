
import SwiftUI

struct DayOccupancyBar: View {
    
    let appointments: [Appointment]
    
    let day: Date
    
    @EnvironmentObject var theme: ThemeManager
    
    private let startHour = 8
    private let endHour = 20
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            if hasEarly {
                
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
                    .padding(.horizontal, 1)
            }
            
            GeometryReader { geo in
                
                ZStack(alignment: .leading) {
                    
                    Capsule()
                        .fill(colors.cardSecondary)
                        .frame(height: 8)
                    
                    ForEach(activeAppointments) { appt in
                        
                        Capsule()
                            .fill(color(for: appt))
                            .frame(
                                width: width(
                                    for: appt,
                                    totalWidth: geo.size.width
                                ),
                                height: 6
                            )
                            .offset(
                                x: offset(
                                    for: appt,
                                    totalWidth: geo.size.width
                                )
                            )
                    }
                }
            }
            .frame(height: 10)
            
            if hasLate {
                
                Circle()
                    .fill(.red)
                    .frame(width: 5, height: 5)
            }
        }
        .frame(height: 10)
    }
}
private extension DayOccupancyBar {

    var activeAppointments: [Appointment] {
        
        appointments.filter {
            
            $0.status != .cancelled &&
            $0.status != .archived &&
            
            Calendar.current.isDate(
                $0.startDate,
                inSameDayAs: day
            )
        }
    }

    func color(for appt: Appointment) -> Color {
        
        switch appt.status {
            
        case .active:
            return colors.accent
            
        case .completed:
            return .green
            
        case .cancelled:
            return .clear
            
        case .archived:
            return .clear
        }
    }

    
    var hasEarly: Bool {
        
        activeAppointments.contains {
            
            Calendar.current.component(
                .hour,
                from: $0.startDate
            ) < startHour
        }
    }
    
    var hasLate: Bool {
        
        activeAppointments.contains {
            
            Calendar.current.component(
                .hour,
                from: $0.endDate
            ) > endHour
        }
    }
    
    func offset(
        for appt: Appointment,
        totalWidth: CGFloat
    ) -> CGFloat {
        
        let calendar = Calendar.current
        
        let start =
        calendar.component(
            .hour,
            from: appt.startDate
        ) * 60
        +
        calendar.component(
            .minute,
            from: appt.startDate
        )
        
        let normalized =
        max(startHour * 60, start)
        
        let progress =
        CGFloat(normalized - startHour * 60)
        /
        CGFloat((endHour - startHour) * 60)
        
        return progress * totalWidth
    }
    
    func width(
        for appt: Appointment,
        totalWidth: CGFloat
    ) -> CGFloat {
        
        let duration =
        CGFloat(appt.duration)
        
        let fullDay =
        CGFloat((endHour - startHour) * 60)
        
        return max(
            6,
            (duration / fullDay) * totalWidth
        )
    }

}
