import SwiftUI

/// The first screen: which app this is, the current intensity, and the button that opens (and times) the dashboard.
struct StartScreen: View {
    let variant: AppVariant
    let intensity: Intensity
    let isReady: Bool
    let open: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text(variant.title)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            Text(variant.explanation)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("\(Text(intensity.title)) · \(intensity.transactionCount) transactions")
                .font(.subheadline)
            if !isReady {
                ProgressView("Generating \(intensity.transactionCount) transactions…")
            }
            Button("Open Dashboard", systemImage: "chart.bar.doc.horizontal", action: open)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isReady)
            Spacer()
        }
        .padding()
        .navigationTitle("Start")
    }
}
