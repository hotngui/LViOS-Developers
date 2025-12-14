//
// SpeechRecognitionService.swift
// Created by Joey Jarosz on 12/14/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Service for handling speech recognition with proper permission management
@MainActor
final class SpeechRecognitionService: ObservableObject {

    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var recognizedText = ""

    // MARK: - Private Properties

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Authorization

    /// Requests necessary permissions for speech recognition and microphone access
    /// - Returns: True if permissions are granted, false otherwise
    func requestPermissions() async -> Bool {
        // Request speech recognition authorization
        let speechAuthStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                continuation.resume(returning: authStatus)
            }
        }

        guard speechAuthStatus == .authorized else {
            return false
        }

        // Request microphone permission
        let micAuthStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return micAuthStatus
    }

    /// Check if speech recognition is available and authorized
    var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: - Recording Control

    /// Starts recording and recognizing speech
    /// - Throws: SpeechRecognitionError if recording cannot start
    func startRecording() throws {
        // Cancel any ongoing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Reset recognized text
        recognizedText = ""

        // Create a new recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest

        // Configure recognition request
        recognitionRequest.shouldReportPartialResults = true

        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Get the input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Prepare and start the audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false

            if let result = result {
                Task { @MainActor in
                    self.recognizedText = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil

                Task { @MainActor in
                    self.isRecording = false
                }
            }
        }

        isRecording = true
    }

    /// Stops recording and finalizes speech recognition
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
}

// MARK: - Speech Recognition Errors

enum SpeechRecognitionError: LocalizedError {
    case recognizerUnavailable
    case audioEngineError
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognition is not available. Please try again later."
        case .audioEngineError:
            return "Unable to access microphone. Please check your settings."
        case .permissionDenied:
            return "Microphone permission is required for voice input. Please enable it in Settings."
        }
    }
}
