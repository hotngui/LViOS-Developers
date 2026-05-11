import SwiftUI

struct ShaderDemoView: View {
    let demo: ShaderDemo

    var body: some View {
        VStack {
            Text(demo.title).font(.title).bold()
            Text(demo.summary)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TimelineView(.animation) { context in
                let t = Float(context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 1_000))
                ShaderCanvas(kind: demo.kind, time: t)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 16))
            .padding()

            Spacer()
        }
    }
}
