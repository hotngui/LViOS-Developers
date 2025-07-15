//
// Created by Joey Jarosz on 7/12/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    private let chuckGenerator = ChunkGenerator.shared
    @State private var isBusy = false
    
    var body: some View {
        VStack(spacing: 40) {
            Button("Divide by 0") {
                doSomeBasicMath()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Bad Access of an Optional") {
                processDataArray()
            }
            .buttonStyle(.borderedProminent)

            Button("Bad Kernel Access") {
                demonstrateKernInvalidAddress()
            }
            .buttonStyle(.borderedProminent)

            GroupBox(label: Text("Memory")) {
                HStack {
                    chuckGenerator.allocatedMemoryFormatted()
                        .disabled(isBusy)
                    
                    Button("Culprit") {
                        isBusy.toggle()
                        
                        Task {
                            await chuckGenerator.generate(numberOfChunks: 100, sizeOfChunksInBytes: 1024 * 1024)
                            isBusy = false
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Victim") {
                        isBusy.toggle()
                        
                        Task {
                            await chuckGenerator.generate(numberOfChunks: 1, sizeOfChunksInBytes: 1024 * 1024)
                            isBusy = false
                        }
                    }
                    .buttonStyle(.borderedProminent)

                }
            }
        }
        .padding()
    }
    
    private func doSomeBasicMath() {
        // Make the calculation complex enough to avoid compiler optimization
        let currentTime = Date().timeIntervalSince1970
        let timeComponent = Int(currentTime.truncatingRemainder(dividingBy: 1000))
        
        let a = 42
        let b = timeComponent % 7
        let c = (a * 3) - 126  // This will be 0
        let d = b + c - b      // This will also be 0
        
        // Add some more obfuscation
        var result = a + b
        result = result * d  // This makes result = 0
        
        // The divide by zero that won't be caught by compiler
        let _ = a / result
    }
    
    private func processDataArray() {
        // Appears to be managing a cache of user preferences with optimized access
        let userPreferences = [
            "theme": "dark",
            "language": "en",
            "notifications": "enabled",
            "autoSave": "true"
        ]
        
        // Create a processing context for batch operations
        let currentTime = Date().timeIntervalSince1970
        let batchSize = Int(currentTime) % 5 + 3 // Between 3-8 operations
        
        // Process preferences with what appears to be optimized pointer access
        var processingResults: [String] = []
        
        for i in 0..<batchSize {
            let keys = Array(userPreferences.keys)
            let keyIndex = i % keys.count
            let selectedKey = keys[keyIndex]
            
            if let value = userPreferences[selectedKey] {
                let processedValue = "processed_\(value)_\(i)"
                processingResults.append(processedValue)
            }
        }
        
        // Now we'll try to optimize by working with raw memory management
        // This appears to be creating a fast lookup structure
        var rawPointer: UnsafeMutablePointer<String>? = nil
        
        // Allocate memory for our "optimized" structure
        if !processingResults.isEmpty {
            rawPointer = UnsafeMutablePointer<String>.allocate(capacity: processingResults.count)
            
            // Copy data to our optimized structure
            for (index, result) in processingResults.enumerated() {
                (rawPointer! + index).initialize(to: result)
            }
        }
        
        // Simulate some processing that might conditionally deallocate
        let shouldOptimize = Int(currentTime) % 2 == 0
        if shouldOptimize {
            // Oops - we're deallocating the memory here in some cases
            rawPointer?.deallocate()
            rawPointer = nil
        }
        
        // But then we always try to access it regardless
        // This looks like a logic error where we forgot to check if pointer is still valid
        if let pointer = rawPointer {
            // This path is safe
            let firstValue = pointer.pointee
            print("First value: \(firstValue)")
        } else {
            // This is the dangerous path - we're creating a null pointer dereference
            // This simulates a common bug where null checking fails
            let nullPointer = UnsafeMutablePointer<String>(bitPattern: 0)
            let crashValue = nullPointer!.pointee // This will cause SIGSEGV
            print("Crash value: \(crashValue)")
        }
    }
    
    private func demonstrateKernInvalidAddress() {
        // Appears to be implementing a memory-mapped I/O system
        // This looks like code that's trying to interface with hardware registers
        
        // Generate a dynamic but invalid memory address based on current time
        let currentTime = Date().timeIntervalSince1970
        let timeComponent = UInt64(currentTime * 1000000) // Use microseconds for more variation
        
        // This appears to be calculating a hardware register address
        // But there's a bug in the address calculation that creates invalid addresses
        let baseAddress: UInt64 = 0x7FFF_FFFF_0000_0000 // High memory address
        let invalidOffset = timeComponent % 0x1000_0000 // Large random offset
        let hardwareRegisterAddress = baseAddress + invalidOffset
        
        // Create a pointer to what we think is a hardware register
        // This looks like legitimate memory-mapped I/O code
        let registerPointer = UnsafeMutablePointer<UInt32>(bitPattern: UInt(hardwareRegisterAddress))
        
        // Try to read from the "hardware register"
        // This will access a completely invalid memory address
        if let pointer = registerPointer {
            // This will definitely cause KERN_INVALID_ADDRESS
            let registerValue = pointer.pointee
            print("Hardware register value: \(registerValue)")
            
            // Try to write to it too for good measure
            pointer.pointee = 0xDEADBEEF
        } else {
            // Fallback - create another invalid address
            let alternateAddress: UInt64 = 0xFFFF_FFFF_FFFF_0000 + (timeComponent % 0x1000)
            let alternatePointer = UnsafeMutablePointer<UInt32>(bitPattern: UInt(alternateAddress))!
            
            // This will also cause KERN_INVALID_ADDRESS
            let value = alternatePointer.pointee
            print("Alternate value: \(value)")
        }
    }
}

#Preview {
    ContentView()
}
