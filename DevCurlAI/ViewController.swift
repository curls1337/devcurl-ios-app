import UIKit
import AudioToolbox
import AVFoundation

public class ViewController: UIViewController {

    // UI Elements
    private let topPillView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let statusDot = UIView()
    private let serverStatusLabel = UILabel()
    private let settingsButton = UIButton(type: .system)

    private let orbContainerView = UIView()
    private let haloLayer = CAGradientLayer()
    private let rippleLayer = CAShapeLayer()
    private let coreLayer = CAGradientLayer()

    private let statusLabel = UILabel()
    private let hintLabel = UILabel()

    private let transcriptCard = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let transcriptIcon = UIImageView(image: UIImage(systemName: "waveform"))
    private let transcriptTextLabel = UILabel()

    private var currentTranscript: String = ""
    private var silenceTimer: Timer?

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupUI()
        setupOrb()
        setupVoiceCallbacks()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestPermissionsAndStart()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        silenceTimer?.invalidate()
        VoiceManager.shared.stopListening()
        VoiceManager.shared.stopSpeaking()
    }

    // MARK: - Setup UI
    private func setupUI() {
        // 1. Top Status Pill
        topPillView.layer.cornerRadius = 18
        topPillView.layer.masksToBounds = true
        topPillView.layer.borderColor = UIColor(white: 0.25, alpha: 0.6).cgColor
        topPillView.layer.borderWidth = 0.5
        topPillView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topPillView)

        statusDot.backgroundColor = UIColor(red: 0.2, green: 0.85, blue: 0.4, alpha: 1.0)
        statusDot.layer.cornerRadius = 4
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        topPillView.contentView.addSubview(statusDot)

        serverStatusLabel.text = "nik.5nod.com  •  Nik AI"
        serverStatusLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        serverStatusLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        serverStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        topPillView.contentView.addSubview(serverStatusLabel)

        // Settings Button
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.tintColor = UIColor(white: 0.5, alpha: 1.0)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        view.addSubview(settingsButton)

        // 2. Orb Container
        orbContainerView.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOrbTapped))
        orbContainerView.addGestureRecognizer(tapGesture)
        orbContainerView.isUserInteractionEnabled = true
        view.addSubview(orbContainerView)

        // 3. Status Labels
        statusLabel.text = "Katakan \"Hai Nik\""
        statusLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        hintLabel.text = "Atau sentuh bola untuk mulai bicara"
        hintLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        hintLabel.textColor = UIColor(white: 0.5, alpha: 1.0)
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        // 4. Bottom Transcript Card
        transcriptCard.layer.cornerRadius = 24
        transcriptCard.layer.masksToBounds = true
        transcriptCard.layer.borderColor = UIColor(white: 0.2, alpha: 0.5).cgColor
        transcriptCard.layer.borderWidth = 0.5
        transcriptCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transcriptCard)

        transcriptIcon.tintColor = UIColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 1.0)
        transcriptIcon.translatesAutoresizingMaskIntoConstraints = false
        transcriptCard.contentView.addSubview(transcriptIcon)

        transcriptTextLabel.text = "Siap mendengarkan instruksi..."
        transcriptTextLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        transcriptTextLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        transcriptTextLabel.numberOfLines = 4
        transcriptTextLabel.translatesAutoresizingMaskIntoConstraints = false
        transcriptCard.contentView.addSubview(transcriptTextLabel)

        // Layout Constraints
        NSLayoutConstraint.activate([
            topPillView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            topPillView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topPillView.heightAnchor.constraint(equalToConstant: 36),

            statusDot.leadingAnchor.constraint(equalTo: topPillView.contentView.leadingAnchor, constant: 14),
            statusDot.centerYAnchor.constraint(equalTo: topPillView.contentView.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8),

            serverStatusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            serverStatusLabel.trailingAnchor.constraint(equalTo: topPillView.contentView.trailingAnchor, constant: -14),
            serverStatusLabel.centerYAnchor.constraint(equalTo: topPillView.contentView.centerYAnchor),

            settingsButton.centerYAnchor.constraint(equalTo: topPillView.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 36),
            settingsButton.heightAnchor.constraint(equalToConstant: 36),

            orbContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            orbContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            orbContainerView.widthAnchor.constraint(equalToConstant: 240),
            orbContainerView.heightAnchor.constraint(equalToConstant: 240),

            statusLabel.topAnchor.constraint(equalTo: orbContainerView.bottomAnchor, constant: 36),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            hintLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            transcriptCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            transcriptCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            transcriptCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            transcriptCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            transcriptIcon.leadingAnchor.constraint(equalTo: transcriptCard.contentView.leadingAnchor, constant: 16),
            transcriptIcon.topAnchor.constraint(equalTo: transcriptCard.contentView.topAnchor, constant: 16),
            transcriptIcon.widthAnchor.constraint(equalToConstant: 22),
            transcriptIcon.heightAnchor.constraint(equalToConstant: 22),

            transcriptTextLabel.leadingAnchor.constraint(equalTo: transcriptIcon.trailingAnchor, constant: 12),
            transcriptTextLabel.trailingAnchor.constraint(equalTo: transcriptCard.contentView.trailingAnchor, constant: -16),
            transcriptTextLabel.topAnchor.constraint(equalTo: transcriptCard.contentView.topAnchor, constant: 14),
            transcriptTextLabel.bottomAnchor.constraint(equalTo: transcriptCard.contentView.bottomAnchor, constant: -14)
        ])
    }

    // MARK: - Modern Siri / Advanced Voice Orb
    private func setupOrb() {
        let bounds = CGRect(x: 0, y: 0, width: 240, height: 240)

        // Outer Halo Layer
        haloLayer.frame = bounds
        haloLayer.type = .radial
        haloLayer.colors = [
            UIColor(red: 0.1, green: 0.5, blue: 1.0, alpha: 0.35).cgColor,
            UIColor.clear.cgColor
        ]
        haloLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        haloLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        orbContainerView.layer.addSublayer(haloLayer)

        // Dynamic Ripple Layer
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 120, y: 120), radius: 80, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        rippleLayer.path = circlePath.cgPath
        rippleLayer.fillColor = UIColor.clear.cgColor
        rippleLayer.strokeColor = UIColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 0.3).cgColor
        rippleLayer.lineWidth = 2.0
        orbContainerView.layer.addSublayer(rippleLayer)

        // Core Liquid Sphere
        coreLayer.frame = CGRect(x: 40, y: 40, width: 160, height: 160)
        coreLayer.cornerRadius = 80
        coreLayer.masksToBounds = true
        coreLayer.colors = [
            UIColor(red: 0.1, green: 0.8, blue: 0.9, alpha: 0.95).cgColor,
            UIColor(red: 0.3, green: 0.2, blue: 0.9, alpha: 0.9).cgColor,
            UIColor(red: 0.9, green: 0.2, blue: 0.6, alpha: 0.85).cgColor
        ]
        coreLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        coreLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        orbContainerView.layer.addSublayer(coreLayer)

        startStandbyBreathing()
    }

    private func startStandbyBreathing() {
        coreLayer.removeAllAnimations()
        let breath = CABasicAnimation(keyPath: "transform.scale")
        breath.fromValue = 0.94
        breath.toValue = 1.06
        breath.duration = 2.8
        breath.autoreverses = true
        breath.repeatCount = .infinity
        breath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        coreLayer.add(breath, forKey: "breath")

        let colorsAnim = CABasicAnimation(keyPath: "colors")
        colorsAnim.toValue = [
            UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 0.9).cgColor,
            UIColor(red: 0.1, green: 0.8, blue: 0.8, alpha: 0.9).cgColor,
            UIColor(red: 0.7, green: 0.2, blue: 0.8, alpha: 0.8).cgColor
        ]
        colorsAnim.duration = 4.0
        colorsAnim.autoreverses = true
        colorsAnim.repeatCount = .infinity
        colorsAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        coreLayer.add(colorsAnim, forKey: "colorsChange")
    }

    // MARK: - Voice Engine Callbacks
    private func setupVoiceCallbacks() {
        // Wake Word Detected ("Hai Nik")
        VoiceManager.shared.onWakeWordDetected = { [weak self] in
            guard let self = self else { return }
            self.triggerWakeWordActive()
        }

        // Live Audio Intensity (Ripples)
        VoiceManager.shared.onAudioLevel = { [weak self] level in
            guard let self = self else { return }
            if VoiceManager.shared.currentState == .activeListening {
                let scale = 1.0 + CGFloat(level) * 0.4
                UIView.animate(withDuration: 0.08) {
                    self.coreLayer.transform = CATransform3DMakeScale(scale, scale, 1.0)
                }
            }
        }

        // Live Transcript
        VoiceManager.shared.onTranscript = { [weak self] transcript, isFinal in
            guard let self = self else { return }
            self.currentTranscript = transcript
            self.transcriptTextLabel.text = "\"\(transcript)\""

            // Reset silence timer (1.8s silence = end of user prompt)
            self.silenceTimer?.invalidate()
            self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
                self?.commitVoiceQuery()
            }
        }

        // State Transition UI
        VoiceManager.shared.onStateChange = { [weak self] state in
            guard let self = self else { return }
            self.updateUIForState(state)
        }

        VoiceManager.shared.onError = { [weak self] err in
            guard let self = self else { return }
            self.statusLabel.text = "⚠️ Periksa Izin Audio"
            self.transcriptTextLabel.text = err
        }
    }

    private func updateUIForState(_ state: VoiceState) {
        switch state {
        case .standbyWakeWord:
            statusLabel.text = "Katakan \"Hai Nik\""
            hintLabel.text = "Atau sentuh bola untuk mulai bicara"
            transcriptIcon.image = UIImage(systemName: "waveform")
            transcriptIcon.tintColor = UIColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 1.0)
            startStandbyBreathing()

        case .activeListening:
            statusLabel.text = "🟢 Mendengarkan Anda..."
            hintLabel.text = "Bicara sekarang, hening 1.8 detik untuk kirim"
            transcriptIcon.image = UIImage(systemName: "mic.fill")
            transcriptIcon.tintColor = UIColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1.0)

        case .processing:
            statusLabel.text = "🟡 Nik sedang memproses..."
            hintLabel.text = "Menghubungkan ke Hermes Engine..."
            transcriptIcon.image = UIImage(systemName: "cpu")
            transcriptIcon.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)

            // Dynamic rotation animation while thinking
            let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
            rotate.toValue = CGFloat.pi * 2
            rotate.duration = 1.2
            rotate.repeatCount = .infinity
            coreLayer.add(rotate, forKey: "rotate")

        case .speaking:
            statusLabel.text = "🔵 Nik Berbicara..."
            hintLabel.text = "Sentuh bola untuk menyela/berhenti"
            transcriptIcon.image = UIImage(systemName: "speaker.wave.2.fill")
            transcriptIcon.tintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)

            coreLayer.removeAllAnimations()
            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 0.98
            pulse.toValue = 1.25
            pulse.duration = 0.8
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            coreLayer.add(pulse, forKey: "speakingPulse")
        }
    }

    // MARK: - Actions & Triggers
    @objc private func handleOrbTapped() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        if VoiceManager.shared.currentState == .speaking {
            VoiceManager.shared.stopSpeaking()
            VoiceManager.shared.startActiveListening()
            return
        }

        if VoiceManager.shared.currentState == .activeListening {
            commitVoiceQuery()
        } else {
            triggerWakeWordActive()
        }
    }

    private func triggerWakeWordActive() {
        // Haptic feedback & subtle chime
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        AudioServicesPlaySystemSound(1057) // Apple chime

        currentTranscript = ""
        transcriptTextLabel.text = "Mendengarkan suara Anda..."
        VoiceManager.shared.startActiveListening()
    }

    private func commitVoiceQuery() {
        silenceTimer?.invalidate()
        let query = currentTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            VoiceManager.shared.startWakeWordStandby()
            return
        }

        VoiceManager.shared.setProcessing()
        sendToHermes(userPrompt: query)
    }

    private func sendToHermes(userPrompt: String) {
        let settings = AppSettings.shared
        guard let url = URL(string: settings.serverUrl) else {
            transcriptTextLabel.text = "URL Server tidak valid."
            VoiceManager.shared.startWakeWordStandby()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !settings.apiKey.isEmpty {
            request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 60.0

        let systemInstruction = "Anda adalah Nik, AI Voice Assistant native pribadi Pak cURLdev berbasis Hermes Orchestrator. Berikan tanggapan dalam Bahasa Indonesia yang sangat alami, ramah, to-the-point, dan ringkas layaknya percakapan lisan langsung. Anda memiliki akses penuh ke server, WhatsApp, Telegram, video Remotion, dan semua otomatisasi."

        let payload: [String: Any] = [
            "model": settings.model,
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": userPrompt]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            VoiceManager.shared.startWakeWordStandby()
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    let errText = "Koneksi ke Nik server gagal: \(error.localizedDescription)"
                    self.transcriptTextLabel.text = errText
                    VoiceManager.shared.speak(text: "Maaf Pak cURLdev, koneksi ke server Hermes terganggu.")
                    return
                }

                guard let data = data else {
                    VoiceManager.shared.startWakeWordStandby()
                    return
                }

                var replyText = ""
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let messageObj = firstChoice["message"] as? [String: Any],
                   let content = messageObj["content"] as? String {
                    replyText = content
                } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let directReply = json["reply"] as? String {
                    replyText = directReply
                } else if let raw = String(data: data, encoding: .utf8) {
                    replyText = raw
                }

                let clean = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.transcriptTextLabel.text = clean

                // Haptic feedback for answer
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)

                // Speak reply back
                VoiceManager.shared.speak(text: clean)
            }
        }.resume()
    }

    private func requestPermissionsAndStart() {
        VoiceManager.shared.requestPermissions { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.transcriptTextLabel.text = "Siap. Katakan \"Hai Nik\" kapan saja..."
                VoiceManager.shared.startWakeWordStandby()
            } else {
                self.transcriptTextLabel.text = "Izin mikrofon belum aktif. Buka Pengaturan iOS."
            }
        }
    }

    // MARK: - Settings Action
    @objc private func openSettings() {
        let alert = UIAlertController(
            title: "Pengaturan Server Nik AI",
            message: "Endpoint saat ini: https://nik.5nod.com",
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.placeholder = "URL Endpoint Server"
            tf.text = AppSettings.shared.serverUrl
            tf.autocapitalizationType = .none
            tf.keyboardType = .URL
        }

        alert.addTextField { tf in
            tf.placeholder = "API Token"
            tf.text = AppSettings.shared.apiKey
            tf.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "Simpan", style: .default) { _ in
            if let u = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), !u.isEmpty {
                AppSettings.shared.serverUrl = u
            }
            if let k = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                AppSettings.shared.apiKey = k
            }
        })

        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(alert, animated: true)
    }
}
