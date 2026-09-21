//
// Created by Joey Jarosz on 9/20/26.
//

import SwiftUI

/// The settings screen: photo count, image size, and cache type controls, plus the cache
/// actions and the entry point into the photo viewer.
struct MainView: View {
    @Environment(AppSettings.self) private var settings

    @State private var isWorking = false
    @State private var isViewerPresented = false
    @State private var isStatsPresented = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                photoCountSection(count: $settings.photoCount)
                imageSizeSection(selection: $settings.imageSize)
                requestModeSection(selection: $settings.requestMode)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .safeAreaInset(edge: .bottom) {
                actionButtons
            }
            .disabled(isWorking)
            .overlay {
                if isWorking {
                    progressOverlay
                }
            }
            .navigationTitle("Image Cache Exerciser (AsyncImage)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $isViewerPresented) {
            PhotoViewer(paths: settings.imagePaths)
        }
        .sheet(isPresented: $isStatsPresented) {
            StatsView(data: Cache.default.dumpStats(photoCount: settings.photoCount,
                                                    imageSize: settings.imageSize.rawValue,
                                                    requestMode: settings.requestMode))
        }
    }

    // MARK: - Sections

    private func photoCountSection(count: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Photo Count (\(count.wrappedValue))")
                .font(.caption)

            HStack {
                Text("1")
                    .font(.caption2)

                Slider(value: Binding(get: { Double(count.wrappedValue) },
                                      set: { count.wrappedValue = Int($0) }),
                       in: 1...Double(settings.maxPhotoCount),
                       step: 1)

                Text("\(settings.maxPhotoCount)")
                    .font(.caption2)
            }
        }
    }

    private func imageSizeSection(selection: Binding<AppSettings.ImageSize>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Image Size")
                .font(.caption)

            Picker("Image Size", selection: selection) {
                ForEach(AppSettings.ImageSize.allCases, id: \.self) { size in
                    Text(size.rawValue)
                        .tag(size)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func requestModeSection(selection: Binding<ImageRequestMode>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Request Mode")
                .font(.caption)

            Picker("Request Mode", selection: selection) {
                ForEach(ImageRequestMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(selection.wrappedValue.explanation)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Buttons and Overlay

    private var actionButtons: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Clear Cache", action: clearCache)
                Spacer()
                Button("Preload Cache", action: preloadCache)
                Spacer()
                Button("Dump Stats") { isStatsPresented = true }
            }
            .font(.caption)

            Button("Open Viewer") { isViewerPresented = true }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding()
    }

    private var progressOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.6)
                .ignoresSafeArea()

            ProgressView()
                .controlSize(.large)
                .tint(.green)
        }
    }

    // MARK: - Actions

    private func clearCache() {
        perform {
            await Cache.default.clear()
        }
    }

    private func preloadCache() {
        perform {
            await Cache.default.preload(with: settings.imagePaths)
        }
    }

    /// Runs an async chunk of work while showing the full-screen progress overlay.
    private func perform(_ work: @escaping () async -> Void) {
        Task {
            isWorking = true
            await work()
            isWorking = false
        }
    }
}

#Preview {
    MainView()
        .environment(AppSettings())
}
