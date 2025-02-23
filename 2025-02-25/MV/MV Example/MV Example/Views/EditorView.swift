import SwiftUI

struct EditorView: View {
    private(set) var items: [MyData]
    
    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink {
                    DetailView(item: item)
                } label: {
                    VStack(alignment: .leading) {
                        Text("\(item.lastName), \(item.firstName)")
                            .font(.title3)
                            .bold()
                        
                        HStack {
                            Text("Is Active: ")
                            Toggle("", isOn: Binding(
                                get: { item.isActive },
                                set: { item.isActive = $0 }
                            ))
                            .labelsHidden()
                        }
                        
                    }
                }
            }
            .navigationTitle("Person Editor")
        }
    }
}

#Preview {
    EditorView(items: MyData.sampleData)
}
