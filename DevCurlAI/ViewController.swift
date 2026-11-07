import UIKit

public class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, VoiceCallDelegate {

    private var messages: [Message] = []
    private var activeAgent: AgentProfile = AgentProfile.available[0]
    private var isSending = false
    private var isRecordingDictation = false

    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let inputTextView = UITextView()
    private let micButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private let placeholderLabel = UILabel()
    private let typingIndicator = UIActivityIndicatorView(style: .medium)

    private var inputBottomConstraint: NSLayoutConstraint!

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupNavigationBar()
        setupTableView()
        setupInputBar()
        setupKeyboardObservers()

        // Welcome Greeting
        let initialGreeting = Message(
            sender: "\(activeAgent.icon) \(activeAgent.name)",
            content: "Halo Pak cURLdev! Saya \(activeAgent.name) (\(activeAgent.role)). Aplikasi native iOS ini terhubung ke Hermes dengan mode teks & Voice Call interaktif. Ada instruksi atau otomatisasi yang ingin dijalankan?",
            isUser: false
        )
        messages.append(initialGreeting)
        tableView.reloadData()
    }

    // MARK: - Navigation Bar Setup
    private func setupNavigationBar() {
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        navigationController?.navigationBar.isTranslucent = true

        updateNavigationTitle()

        // Left Bar Button: Agent Switcher
        let agentButton = UIBarButtonItem(
            title: "\(activeAgent.icon) Agen",
            style: .plain,
            target: self,
            action: #selector(showAgentPicker)
        )
        navigationItem.leftBarButtonItem = agentButton

        // Right Bar Buttons: Settings, New Chat, Voice Call
        let voiceCallButton = UIBarButtonItem(
            image: UIImage(systemName: "waveform.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(openVoiceCall)
        )
        voiceCallButton.tintColor = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)

        let newChatButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(startNewChat)
        )

        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )

        navigationItem.rightBarButtonItems = [settingsButton, newChatButton, voiceCallButton]
    }

    private func updateNavigationTitle() {
        let titleView = UIView()
        let titleLabel = UILabel()
        titleLabel.text = "DevCurl AI"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "\(activeAgent.icon) \(activeAgent.name)"
        subtitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        subtitleLabel.textColor = UIColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 1.0)
        subtitleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false

        titleView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: titleView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: titleView.centerYAnchor)
        ])

        navigationItem.titleView = stack
    }

    // MARK: - Table View Setup
    private func setupTableView() {
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
        tableView.keyboardDismissMode = .interactive
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
    }

    // MARK: - Input Bar Setup
    private func setupInputBar() {
        inputContainerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 0.95)
        inputContainerView.layer.borderColor = UIColor(white: 0.2, alpha: 1.0).cgColor
        inputContainerView.layer.borderWidth = 0.5
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainerView)

        // Mic Button (Dictation)
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = UIColor(white: 0.7, alpha: 1.0)
        micButton.translatesAutoresizingMaskIntoConstraints = false
        micButton.addTarget(self, action: #selector(toggleDictation), for: .touchUpInside)
        inputContainerView.addSubview(micButton)

        // Text View
        inputTextView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        inputTextView.textColor = .white
        inputTextView.font = UIFont.systemFont(ofSize: 16)
        inputTextView.layer.cornerRadius = 18
        inputTextView.layer.masksToBounds = true
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        inputTextView.delegate = self
        inputTextView.isScrollEnabled = false
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(inputTextView)

        // Placeholder
        placeholderLabel.text = "Kirim pesan ke \(activeAgent.name)..."
        placeholderLabel.textColor = UIColor(white: 0.5, alpha: 1.0)
        placeholderLabel.font = UIFont.systemFont(ofSize: 16)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.addSubview(placeholderLabel)

        // Send Button
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        sendButton.contentVerticalAlignment = .fill
        sendButton.contentHorizontalAlignment = .fill
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        inputContainerView.addSubview(sendButton)

        // Typing Indicator
        typingIndicator.color = UIColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 1.0)
        typingIndicator.hidesWhenStopped = true
        typingIndicator.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(typingIndicator)

        inputBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),

            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint,

            micButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 10),
            micButton.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 32),
            micButton.heightAnchor.constraint(equalToConstant: 32),

            inputTextView.leadingAnchor.constraint(equalTo: micButton.trailingAnchor, constant: 8),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            placeholderLabel.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 14),

            sendButton.leadingAnchor.constraint(equalTo: inputTextView.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 34),
            sendButton.heightAnchor.constraint(equalToConstant: 34),

            typingIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            typingIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor)
        ])
    }

    // MARK: - Voice Call Action
    @objc private func openVoiceCall() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let callVC = VoiceCallViewController()
        callVC.activeAgent = self.activeAgent
        callVC.delegate = self
        callVC.modalPresentationStyle = .fullScreen
        present(callVC, animated: true)
    }

    public func voiceCallDidFinish(newMessages: [Message]) {
        for msg in newMessages {
            messages.append(msg)
        }
        tableView.reloadData()
        scrollToBottom()
    }

    // MARK: - Dictation Toggle
    @objc private func toggleDictation() {
        if isRecordingDictation {
            VoiceManager.shared.stopListening()
            micButton.tintColor = UIColor(white: 0.7, alpha: 1.0)
            isRecordingDictation = false
        } else {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            VoiceManager.shared.requestPermissions { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.isRecordingDictation = true
                    self.micButton.tintColor = .systemRed

                    VoiceManager.shared.onTranscript = { [weak self] transcript, isFinal in
                        guard let self = self else { return }
                        self.inputTextView.text = transcript
                        self.placeholderLabel.isHidden = !transcript.isEmpty
                        if isFinal {
                            self.toggleDictation()
                        }
                    }

                    VoiceManager.shared.startListening()
                } else {
                    let alert = UIAlertController(title: "Izin Dibutuhkan", message: "Mohon aktifkan izin mikrofon & speech recognition di Pengaturan iOS.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Settings Action
    @objc private func openSettings() {
        let alert = UIAlertController(
            title: "Pengaturan Koneksi Hermes",
            message: "Konfigurasikan endpoint API server Hermes Anda:",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "URL Endpoint Server"
            textField.text = AppSettings.shared.serverUrl
            textField.autocapitalizationType = .none
            textField.keyboardType = .URL
        }

        alert.addTextField { textField in
            textField.placeholder = "API Token (Kosongkan jika lokal)"
            textField.text = AppSettings.shared.apiKey
            textField.isSecureTextEntry = true
        }

        alert.addTextField { textField in
            textField.placeholder = "Model ID (hermes-agent)"
            textField.text = AppSettings.shared.model
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "Simpan", style: .default) { _ in
            if let newUrl = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), !newUrl.isEmpty {
                AppSettings.shared.serverUrl = newUrl
            }
            if let newKey = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                AppSettings.shared.apiKey = newKey
            }
            if let newModel = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines), !newModel.isEmpty {
                AppSettings.shared.model = newModel
            }

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        })

        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Actions
    @objc private func startNewChat() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        messages.removeAll()
        let greeting = Message(
            sender: "\(activeAgent.icon) \(activeAgent.name)",
            content: "Percakapan baru dimulai bersama \(activeAgent.name). Silakan ajukan pertanyaan atau berikan instruksi otomatisasi, Pak cURLdev!",
            isUser: false
        )
        messages.append(greeting)
        tableView.reloadData()
    }

    @objc private func showAgentPicker() {
        let alert = UIAlertController(
            title: "Pilih Agen Spesialis Hermes",
            message: "Arahkan pembicaraan langsung ke salah satu divisi berikut:",
            preferredStyle: .actionSheet
        )

        for agent in AgentProfile.available {
            let action = UIAlertAction(title: "\(agent.icon) \(agent.name) — \(agent.role)", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.activeAgent = agent
                self.navigationItem.leftBarButtonItem?.title = "\(agent.icon) Agen"
                self.placeholderLabel.text = "Kirim pesan ke \(agent.name)..."
                self.updateNavigationTitle()

                let switchNotice = Message(
                    sender: "👥 Sistem Multi-Agent",
                    content: "Beralih ke \(agent.icon) \(agent.name) (\(agent.role)). Silakan mulai berdiskusi langsung.",
                    isUser: false
                )
                self.messages.append(switchNotice)
                self.tableView.reloadData()
                self.scrollToBottom()
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func sendMessage() {
        guard let text = inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty, !isSending else {
            return
        }

        if isRecordingDictation {
            toggleDictation()
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        let userMessage = Message(sender: "Pak cURLdev", content: text, isUser: true)
        messages.append(userMessage)
        tableView.reloadData()
        scrollToBottom()

        inputTextView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isHidden = true
        typingIndicator.startAnimating()
        isSending = true

        let settings = AppSettings.shared
        guard let url = URL(string: settings.serverUrl) else {
            showErrorResponse("URL Server di Pengaturan tidak valid.")
            return
        }

        // Standard OpenAI-compatible /v1/chat/completions payload
        let payload: [String: Any] = [
            "model": settings.model,
            "messages": [
                [
                    "role": "system",
                    "content": "Anda adalah \(activeAgent.name) (\(activeAgent.role)) dari ekosistem Hermes multi-agent. Tanggapi instruksi Pak cURLdev dengan profesional, ringkas, dan fokus pada eksekusi solusi teknis nyata."
                ],
                [
                    "role": "user",
                    "content": text
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !settings.apiKey.isEmpty {
            request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 60.0

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            showErrorResponse("Gagal serialisasi data JSON.")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSending = false
                self.typingIndicator.stopAnimating()
                self.sendButton.isHidden = false

                if let error = error {
                    self.showErrorResponse("Gagal terhubung ke Hermes: \(error.localizedDescription)\nPeriksa kembali URL Server di ikon Gerigi Pengaturan.")
                    return
                }

                guard let data = data else {
                    self.showErrorResponse("Data kosong dari server.")
                    return
                }

                var replyText = ""

                // 1. OpenAI Chat Completion format
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let messageObj = firstChoice["message"] as? [String: Any],
                   let content = messageObj["content"] as? String {
                    replyText = content
                }
                // 2. Custom "reply" key
                else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let directReply = json["reply"] as? String {
                    replyText = directReply
                } else if let rawString = String(data: data, encoding: .utf8) {
                    replyText = rawString
                }

                let cleanReply = replyText.trimmingCharacters(in: .whitespacesAndNewlines)

                let receiveGenerator = UINotificationFeedbackGenerator()
                receiveGenerator.notificationOccurred(.success)

                let agentMessage = Message(
                    sender: "\(self.activeAgent.icon) \(self.activeAgent.name)",
                    content: cleanReply,
                    isUser: false
                )
                self.messages.append(agentMessage)
                self.tableView.reloadData()
                self.scrollToBottom()

                if settings.autoVoice {
                    VoiceManager.shared.speak(text: cleanReply)
                }
            }
        }.resume()
    }

    private func showErrorResponse(_ errorText: String) {
        isSending = false
        typingIndicator.stopAnimating()
        sendButton.isHidden = false

        let errorMsg = Message(sender: "⚠️ System Error", content: errorText, isUser: false)
        messages.append(errorMsg)
        tableView.reloadData()
        scrollToBottom()
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    // MARK: - Text View Delegate
    public func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    // MARK: - Table View Data Source & Delegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as! MessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let msg = messages[indexPath.row]
        VoiceManager.shared.speak(text: msg.content)
    }

    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            inputBottomConstraint.constant = -keyboardFrame.height + view.safeAreaInsets.bottom
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            scrollToBottom()
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        inputBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
