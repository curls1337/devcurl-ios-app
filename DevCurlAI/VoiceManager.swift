import Foundation
import AVFoundation
import Speech

public enum VoiceState {
    case idle
    case listening
    case processing
    case speaking
}

public class VoiceManager: NSObject, AVSpeechSynthesizerDelegate {
    public static let shared = VoiceManager()

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID")) ?? SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()

    public var onTranscript: ((String, Bool) -> Void)?
    public var onStateChange: ((VoiceState) -> Void)?
    public var onError: ((String) -> Void)?
    public var onSpeechFinished: (() -> Void)?

    public private(set) var currentState: VoiceState = .idle {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onStateChange?(self.currentState)
            }
        }
    }

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Permission Request
    public func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            completion(granted)
                        }
                    }
                default:
                    completion(false)
                }
            }
        }
    }

    // MARK: - Speech Recognition (Listening)
    public func startListening() {
        stopSpeaking()

        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            onError?("Gagal mengonfigurasi Audio Session: \(error.localizedDescription)")
            currentState = .idle
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            onError?("Tidak dapat menginisialisasi audio request.")
            currentState = .idle
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            var isFinal = false

            if let result = result {
                let transcription = result.bestTranscription.formattedString
                isFinal = result.isFinal
                DispatchQueue.main.async {
                    self.onTranscript?(transcription, isFinal)
                }
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            currentState = .listening
        } catch {
            onError?("Gagal menjalankan audio engine: \(error.localizedDescription)")
            currentState = .idle
        }
    }

    public func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        if currentState == .listening {
            currentState = .idle
        }
    }

    public func setProcessing() {
        currentState = .processing
    }

    // MARK: - Text to Speech (Speaking)
    public func speak(text: String) {
        stopListening()
        stopSpeaking()

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            currentState = .idle
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("AudioSession playback error: \(error)")
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0

        if let idVoice = AVSpeechSynthesisVoice(language: "id-ID") {
            utterance.voice = idVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        currentState = .speaking
        synthesizer.speak(utterance)
    }

    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if currentState == .speaking {
            currentState = .idle
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentState = .idle
            self.onSpeechFinished?()
        }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentState = .idle
        }
    }
}
