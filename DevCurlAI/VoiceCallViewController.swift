import UIKit

public protocol VoiceCallDelegate: AnyObject {
    func voiceCallDidFinish(newMessages: [Message])
}

public class VoiceCallViewController: UIViewController {

    public weak var delegate: VoiceCallDelegate?
    public var activeAgent: AgentProfile = AgentProfile.available[0]
    
    private var sessionMessages: [Message] = []
    private var currentTranscript: String = ""
    private var isMuted: Bool = false
    private var silenceTimer: Timer?

    // UI Elements
    private let agentIconLabel = UILabel()
    private let agentNameLabel = UILabel()
    private let statusLabel = UILabel()
    private let transcriptLabel = UILabel()
    private let orbContainerView = UIView()
    private let orbLayer = CAShapeLayer()
    private let pulseLayer = CAShapeLayer()

    private let controlsStack = UIStackView()
    private let muteButton = UIButton(type: .system)
    private let endCallButton = UIButton(type: .system)
    private let sendVoiceButton = UIButton(type: .system)

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0)

        setupUI()
        setupVoiceManager()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCallSession()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        silenceTimer?.invalidate()
        VoiceManager.shared.stopListening()
        VoiceManager.shared.stopSpeaking()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Agent Icon
        agentIconLabel.text = activeAgent.icon
        agentIconLabel.font = UIFont.systemFont(ofSize: 48)
        agentIconLabel.textAlignment = .center
        agentIconLabel.translatesAutoresizingMaskIntoConstraints = false

        // Agent Name
        agentNameLabel.text = activeAgent.name
        agentNameLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        agentNameLabel.textColor = .white
        agentNameLabel.textAlignment = .center
        agentNameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Status Label
        statusLabel.text = "Menghubungkan ke Hermes..."
        statusLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = UIColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 1.0)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // Orb Container
        orbContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(orbContainerView)

        // Transcript Label
        transcriptLabel.text = "Silakan mulai berbicara..."
        transcriptLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        transcriptLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        transcriptLabel.textAlignment = .center
        transcriptLabel.numberOfLines = 6
        transcriptLabel.translatesAutoresizingMaskIntoConstraints = false

        // Controls
        muteButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        muteButton.tintColor = .white
        muteButton.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        muteButton.layer.cornerRadius = 30
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)

        endCallButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
        endCallButton.tintColor = .white
        endCallButton.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        endCallButton.layer.cornerRadius = 35
        endCallButton.addTarget(self, action: #selector(endCall), for: .touchUpInside)

        sendVoiceButton.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        sendVoiceButton.tintColor = .white
        sendVoiceButton.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        sendVoiceButton.layer.cornerRadius = 30
        sendVoiceButton.addTarget(self, action: #selector(commitVoiceInput), for: .touchUpInside)

        controlsStack.axis = .horizontal
        controlsStack.alignment = .center
        controlsStack.distribution = .equalCentering
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        controlsStack.addArrangedSubview(muteButton)
        controlsStack.addArrangedSubview(endCallButton)
        controlsStack.addArrangedSubview(sendVoiceButton)

        view.addSubview(agentIconLabel)
        view.addSubview(agentNameLabel)
        view.addSubview(statusLabel)
        view.addSubview(transcriptLabel)
        view.addSubview(controlsStack)

        NSLayoutConstraint.activate([
            agentIconLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            agentIconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            agentNameLabel.topAnchor.constraint(equalTo: agentIconLabel.bottomAnchor, constant: 8),
            agentNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: agentNameLabel.bottomAnchor, constant: 6),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            orbContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            orbContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            orbContainerView.widthAnchor.constraint(equalToConstant: 180),
            orbContainerView.heightAnchor.constraint(equalToConstant: 180),

            transcriptLabel.topAnchor.constraint(equalTo: orbContainerView.bottomAnchor, constant: 30),
            transcriptLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            transcriptLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            muteButton.widthAnchor.constraint(equalToConstant: 60),
            muteButton.heightAnchor.constraint(equalToConstant: 60),

            endCallButton.widthAnchor.constraint(equalToConstant: 70),
            endCallButton.heightAnchor.constraint(equalToConstant: 70),

            sendVoiceButton.widthAnchor.constraint(equalToConstant: 60),
            sendVoiceButton.heightAnchor.constraint(equalToConstant: 60),

            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            controlsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])

        setupOrbLayers()
    }

    private func setupOrbLayers() {
        let center = CGPoint(x: 90, y: 90)
        let radius: CGFloat = 65

        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)

        pulseLayer.path = path.cgPath
        pulseLayer.fillColor = UIColor(red: 0.0, green: 0.8, blue: 0.9, alpha: 0.15).cgColor
        orbContainerView.layer.addSublayer(pulseLayer)

        orbLayer.path = path.cgPath
        orbLayer.fillColor = UIColor(red: 0.0, green: 0.5, blue: 0.9, alpha: 0.8).cgColor
        orbContainerView.layer.addSublayer(orbLayer)
    }

    // MARK: - Voice Setup & Events
    private func setupVoiceManager() {
        VoiceManager.shared.onTranscript = { [weak self] transcript, isFinal in
            guard let self = self else { return }
            self.currentTranscript = transcript
            self.transcriptLabel.text = "\"\(transcript)\""

            // Reset silence timer on new speech
            self.silenceTimer?.invalidate()
            self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                // After 2.0s of silence, auto send
                self?.commitVoiceInput()
            }
        }

        VoiceManager.shared.onStateChange = { [weak self] state in
            guard let self = self else { return }
            self.updateUIForState(state)
        }

        VoiceManager.shared.onError = { [weak self] errorText in
            guard let self = self else { return }
            self.statusLabel.text = "⚠️ \(errorText)"
            self.statusLabel.textColor = .systemRed
        }

        VoiceManager.shared.onSpeechFinished = { [weak self] in
            guard let self = self else { return }
            // After Hermes finishes speaking, listen again automatically
            if !self.isMuted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startListening()
                }
            }
        }
    }

    private func updateUIForState(_ state: VoiceState) {
        switch state {
        case .idle:
            statusLabel.text = "Menunggu instruksi..."
            statusLabel.textColor = UIColor(white: 0.7, alpha: 1.0)
            stopOrbAnimation()
        case .listening:
            statusLabel.text = "🟢 Mendengarkan..."
            statusLabel.textColor = UIColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1.0)
            orbLayer.fillColor = UIColor(red: 0.1, green: 0.8, blue: 0.5, alpha: 0.8).cgColor
            startOrbAnimation(scale: 1.25, duration: 1.0)
        case .processing:
            statusLabel.text = "🟡 Hermes mengeksekusi instruksi..."
            statusLabel.textColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
            orbLayer.fillColor = UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 0.8).cgColor
            startOrbAnimation(scale: 1.15, duration: 0.6)
        case .speaking:
            statusLabel.text = "🔵 Hermes Berbicara..."
            statusLabel.textColor = UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
            orbLayer.fillColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 0.85).cgColor
            startOrbAnimation(scale: 1.35, duration: 1.2)
        }
    }

    private func startOrbAnimation(scale: CGFloat, duration: Double) {
        pulseLayer.removeAllAnimations()
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.toValue = scale
        pulseAnimation.duration = duration
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseLayer.add(pulseAnimation, forKey: "pulse")
    }

    private func stopOrbAnimation() {
        pulseLayer.removeAllAnimations()
    }

    // MARK: - Call Lifecycle
    private func startCallSession() {
        VoiceManager.shared.requestPermissions { [weak self] granted in
            guard let self = self else { return }
            if granted {
                let greeting = "Halo Pak cURLdev! Saya \(self.activeAgent.name). Ada yang bisa saya bantu atau kerjakan sekarang?"
                self.transcriptLabel.text = greeting
                VoiceManager.shared.speak(text: greeting)
            } else {
                self.statusLabel.text = "Izin mikrofon/speech belum diberikan."
                self.statusLabel.textColor = .systemRed
            }
        }
    }

    private func startListening() {
        currentTranscript = ""
        VoiceManager.shared.startListening()
    }

    @objc private func commitVoiceInput() {
        silenceTimer?.invalidate()
        let text = currentTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        VoiceManager.shared.stopListening()
        VoiceManager.shared.setProcessing()

        let userMsg = Message(sender: "Pak cURLdev", content: text, isUser: true)
        sessionMessages.append(userMsg)

        sendToHermes(userPrompt: text)
    }

    private func sendToHermes(userPrompt: String) {
        let settings = AppSettings.shared
        guard let url = URL(string: settings.serverUrl) else {
            statusLabel.text = "URL Server tidak valid"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !settings.apiKey.isEmpty {
            request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 60.0

        // OpenAI chat completions standard payload
        let payload: [String: Any] = [
            "model": settings.model,
            "messages": [
                [
                    "role": "system",
                    "content": "Anda adalah \(activeAgent.name) (\(activeAgent.role)) dari ekosistem Hermes multi-agent. Pengguna sedang berbicara dengan Anda via Voice Call iOS Native. Berikan jawaban yang ramah, langsung pada inti, dan ringkas agar nyaman didengarkan lewat suara."
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            statusLabel.text = "Gagal memproses data suara"
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.statusLabel.text = "Koneksi gagal: \(error.localizedDescription)"
                    VoiceManager.shared.speak(text: "Maaf Pak cURLdev, koneksi ke server Hermes terputus: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    self.statusLabel.text = "Data kosong dari server"
                    return
                }

                var replyText = ""

                // 1. Try parse OpenAI format: choices[0].message.content
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let messageObj = firstChoice["message"] as? [String: Any],
                   let content = messageObj["content"] as? String {
                    replyText = content
                }
                // 2. Try parse custom JSON: "reply"
                else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let directReply = json["reply"] as? String {
                    replyText = directReply
                } else if let rawString = String(data: data, encoding: .utf8) {
                    replyText = rawString
                }

                let cleanReply = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.transcriptLabel.text = cleanReply

                let agentMsg = Message(sender: "\(self.activeAgent.icon) \(self.activeAgent.name)", content: cleanReply, isUser: false)
                self.sessionMessages.append(agentMsg)

                // Speak back the response
                VoiceManager.shared.speak(text: cleanReply)
            }
        }.resume()
    }

    @objc private func toggleMute() {
        isMuted.toggle()
        if isMuted {
            muteButton.setImage(UIImage(systemName: "mic.slash.fill"), for: .normal)
            muteButton.backgroundColor = .systemGray
            VoiceManager.shared.stopListening()
            statusLabel.text = "Mikrofon Dinonaktifkan"
        } else {
            muteButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            muteButton.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            startListening()
        }
    }

    @objc private func endCall() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        VoiceManager.shared.stopSpeaking()
        VoiceManager.shared.stopListening()

        delegate?.voiceCallDidFinish(newMessages: sessionMessages)
        dismiss(animated: true)
    }
}
