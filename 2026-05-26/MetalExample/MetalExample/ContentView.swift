import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Triangle", systemImage: "triangle.fill") {
                NavigationStack { TriangleView() }
            }
            Tab("Shaders", systemImage: "sparkles") {
                NavigationStack { ShaderGalleryView() }
            }
            Tab("Filter", systemImage: "wand.and.stars") {
                NavigationStack { ImageFilterView() }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(MetalContext())
}
