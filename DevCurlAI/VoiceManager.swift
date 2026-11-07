import Foundation
import AVFoundation
import Speech

public enum VoiceState {
    case standbyWakeWord   // Standby listening for "Hai Nik"
    case activeListening   // Actively recording user's command
    case processing        // Sending to Hermes & executing
    case speaking          // Nik is speaking response
}

public class VoiceManager: NSObject, AVSpeechSynthesizerDelegate {
    public static let shared = VoiceManager()

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID")) ?? SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()

    public var onTranscript: ((String, Bool) -> Void)?
    public var onWakeWordDetected: (() -> Void)?
    public var onAudioLevel: ((Float) -> Void)?
    public var onStateChange: ((VoiceState) -> Void)?
    public var onError: ((String) -> Void)?
    public var onSpeechFinished: (() -> Void)?

    public private(set) var currentState: VoiceState = .standbyWakeWord {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onStateChange?(self.currentState)
            }
        }
    }

    private let wakeWords = ["hai nik", "hei nik", "hey nik", "halo nik", "nik", "hai nic", "halo nic"]
    private var restartTimer: Timer?

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

    // MARK: - Standby Wake-Word Listening
    public func startWakeWordStandby() {
        stopSpeaking()
        currentState = .standbyWakeWord
        startAudioEngine()
    }

    // MARK: - Active Listening
    public func startActiveListening() {
        stopSpeaking()
        currentState = .activeListening
        startAudioEngine()
    }

    private func startAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            onError?("Gagal inisialisasi audio session: \(error.localizedDescription)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString.lowercased()
                let isFinal = result.isFinal

                if self.currentState == .standbyWakeWord {
                    // Check for wake word
                    for trigger in self.wakeWords {
                        if text.contains(trigger) {
                            // Wake word triggered!
                            DispatchQueue.main.async {
                                self.onWakeWordDetected?()
                            }
                            return
                        }
                    }
                } else if self.currentState == .activeListening {
                    DispatchQueue.main.async {
                        self.onTranscript?(result.bestTranscription.formattedString, isFinal)
                    }
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                // If in standby, auto-restart to keep listening
                if self.currentState == .standbyWakeWord {
                    self.restartStandbyAfterDelay()
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate RMS audio level for visual pulsating
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = UInt(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<Int(frameLength) {
                sum += channelData[i] * channelData[i]
            }
            let rms = sqrt(sum / Float(frameLength))
            let level = min(max(rms * 10.0, 0.0), 1.0)
            DispatchQueue.main.async {
                self?.onAudioLevel?(level)
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            onError?("Gagal audio engine: \(error.localizedDescription)")
        }
    }

    private func restartStandbyAfterDelay() {
        restartTimer?.invalidate()
        restartTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self, self.currentState == .standbyWakeWord else { return }
            self.startWakeWordStandby()
        }
    }

    public func stopListening() {
        restartTimer?.invalidate()
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }

    public func setProcessing() {
        stopListening()
        currentState = .processing
    }

    // MARK: - Text to Speech
    public func speak(text: String) {
        stopListening()
        stopSpeaking()

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            startWakeWordStandby()
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("AudioSession playback: \(error)")
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.51
        utterance.pitchMultiplier = 1.05

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
    }

    // MARK: - AVSpeechSynthesizerDelegate
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onSpeechFinished?()
            // After speaking finishes, return to standby wake word detection
            self.startWakeWordStandby()
        }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.startWakeWordStandby()
        }
    }
}
