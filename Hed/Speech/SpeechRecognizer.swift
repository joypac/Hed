import Foundation
import Speech
import AVFoundation

// ---------------------------------------------------------------------------
// MARK: - SpeechRecognizer
// ---------------------------------------------------------------------------

/// Wraps `SFSpeechRecognizer` + `AVAudioEngine` to provide live transcription.
///
/// Usage:
/// ```swift
/// @StateObject private var speech = SpeechRecognizer()
/// speech.requestAuthorization { granted in ... }
/// speech.startRecording()
/// // observe speech.transcript
/// speech.stopRecording()
/// ```
///
/// Requires in Info.plist:
///   • NSMicrophoneUsageDescription
///   • NSSpeechRecognitionUsageDescription
final class SpeechRecognizer: ObservableObject {

    @Published var transcript:    String  = ""
    @Published var isRecording:   Bool    = false
    @Published var errorMessage:  String? = nil

    // `SFSpeechRecognizer` uses the device locale; falls back gracefully if unavailable.
    private let recognizer = SFSpeechRecognizer(locale: .current)
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask:    SFSpeechRecognitionTask?

    /// Whether the hardware and OS support speech recognition right now.
    var isAvailable: Bool { recognizer?.isAvailable == true }

    // MARK: - Authorisation

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    // MARK: - Recording

    func startRecording() {
        guard !isRecording else { return }

        // Cancel any leftover task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session for recording
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Unable to activate the microphone. Check Settings > Privacy & Security > Microphone."
            }
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true

        // Start recognition task
        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }

        // Tap the microphone input
        let inputNode = audioEngine.inputNode
        let format    = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async { self.isRecording = true }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Could not start audio recording. Please try again."
            }
        }
    }

    func stopRecording() {
        guard audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask    = nil
        DispatchQueue.main.async { self.isRecording = false }
    }
}
