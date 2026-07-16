import SwiftUI
import SwiftData

struct ServicesListView: View {
    
    @Environment(\.modelContext) private var context
    @Query private var services: [Service]
    
    @State private var showCreate = false
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
                ForEach(services) { service in
                    
                    VStack(alignment: .leading) {
                        Text(service.name)
                            .font(.headline)
                        
                        Text(priceText(service))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Services")
            .toolbar {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateServiceView()
            }
        }
    }
    
    private func delete(indexSet: IndexSet) {
        for index in indexSet {
            context.delete(services[index])
        }
    }
    
    private func priceText(_ service: Service) -> String {
        
        switch service.pricingType {
        case .fixed:
            return "\(service.price ?? 0) €"
        case .variable:
            return "Variable price"
        }
    }
}