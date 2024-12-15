//
// Created by Joey Jarosz on 12/13/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct UploadView: View {
    @Environment(FileHandler.self) private var fileHandler
    
    private let formatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 3
        formatter.numberFormatter.minimumFractionDigits = 3
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Upload File") {
                    fileHandler.uploadFile(to: URL(string: "https://www.hotngui.com/lvios/")!)
                }
                .disabled(fileHandler.isBusy)
                
                if let size = fileHandler.downloadSize {
                    Text("Downloaded Size: \(formatter.string(from: convert(size, from: .bytes, to: .megabytes)))")
                }
                
                if let error = fileHandler.error {
                    Text("Error: \(error)")
                }
            }
            .overlay {
                if fileHandler.isBusy {
                    ProgressView()
                        .tint(.red)
                        .scaleEffect(x: 4, y: 4, anchor: .center)
                }
            }
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? "")
        }
    }
    
    private func convert(_ value: UInt64, from inUnit: UnitInformationStorage, to outUnit: UnitInformationStorage) -> Measurement<UnitInformationStorage> {
        return Measurement<UnitInformationStorage>(value: Double(value), unit: inUnit).converted(to: outUnit)
    }
}

#Preview {
    UploadView()
        .environment(FileHandler())
}
