import SwiftUI

struct DetailView: View {
    @Bindable var item: MyData
    
    var body: some View {
        Form {
            VStack(alignment: .leading) {
                Text("\(item.lastName), \(item.firstName)")
                    .font(.title3)
                    .bold()
                
                Toggle("Is Active:", isOn: $item.isActive)
            }
        }
        .navigationTitle("Details")
    }
}

#Preview {
    NavigationStack {
        DetailView(item: MyData.sampleData[0])
    }
} 
