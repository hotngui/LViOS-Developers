//
// Created by Joey Jarosz on 12/7/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct MyFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let size: String
}

struct DownloadView: View {
    @Environment(FileHandler.self) private var fileHandler
    
    let files = [MyFile(name: "Tiny.txt", size: "Small"),
                 MyFile(name: "Medium.data", size: "Medium"),
                 MyFile(name: "Take2.mov", size: "Large")]
    
    @State private var selection: MyFile?
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Files", selection: $selection) {
                    Text("")
                    ForEach(files) { file in
                        HStack {
                            Text(file.name)
                            Spacer()
                            Text(file.size)
                        }
                        .tag(file)
                    }
                }
                .pickerStyle(.inline)
                .disabled(fileHandler.isBusy)
                .padding([.leading, .trailing], 30)
                
                HStack {
                    Button("Download File") {
                        if let file = selection?.name {
                            if let url = URL(string: "https://www.hotngui.com/lvios/\(file)") {
                                fileHandler.downloadFile(from: url)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(fileHandler.isBusy || selection == nil)
                    
                    Button("Cancel Download") {
                        fileHandler.cancelDownload()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!fileHandler.isBusy)
                }
                
                VStack {
                    if let size = fileHandler.downloadSize {
                        Text("Downloaded Size")
                            .fontWeight(.bold)
                        Text(formatter.string(from: convert(size, from: .bytes, to: .megabytes)))
                    }
                }
                .padding(.top, 20)

                VStack {
                    if let error = fileHandler.error {
                        Text("Error")
                            .fontWeight(.bold)
                        Text(error)
                            .padding([.leading, .trailing], 20)
                    }
                }
                .padding(.top, 20)

                Spacer()
            }
            .padding()
            .overlay {
                if fileHandler.isBusy {
                    ProgressView()
                        .tint(.red)
                        .scaleEffect(x: 2, y: 2, anchor: .center)
                }
            }
            .navigationTitle("Download")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? "")
        }
    }
    
    // MARK: - Some number formatting niceness...
    
    private let formatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 3
        formatter.numberFormatter.minimumFractionDigits = 3
        return formatter
    }()

    private func convert(_ value: UInt64, from inUnit: UnitInformationStorage, to outUnit: UnitInformationStorage) -> Measurement<UnitInformationStorage> {
        return Measurement<UnitInformationStorage>(value: Double(value), unit: inUnit).converted(to: outUnit)
    }
}

#Preview {
    DownloadView()
        .environment(FileHandler(mockIsBusy: true, mockError: "This is an error message", mockDownloadSize: 20_000_000_000))
}
