import SwiftUI

struct ShaderGalleryView: View {
    private let demos = ShaderDemo.all
    @State private var selection: ShaderDemo.ID

    init() {
        _selection = State(initialValue: ShaderDemo.all[0].id)
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(demos) { demo in
                ShaderDemoView(demo: demo)
                    .tag(demo.id)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .navigationTitle("Shader Gallery")
    }
}

#Preview {
    NavigationStack { ShaderGalleryView() }
}
