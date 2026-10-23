import UIKit

public class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {

    private var messages: [Message] = []
    private var activeAgent: AgentProfile = AgentProfile.available[0] // Default: Ubuntu Admin
    private var isSending = false

    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let inputTextView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let placeholderLabel = UILabel()
    private let typingIndicator = UIActivityIndicatorView(style: .medium)

    private var inputBottomConstraint: NSLayoutConstraint!
    private let serverUrl = URL(string: "http://192.168.18.200:8080/api/projects/discovery/chat")!

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
            content: "Halo Pak cURLdev! Saya \(activeAgent.name) (\(activeAgent.role)). Aplikasi native iOS ini berjalan 100% native Swift tanpa webview. Ada instruksi atau ide yang ingin didiskusikan?",
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

        // Right Bar Button: New Chat
        let newChatButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(startNewChat)
        )
        navigationItem.rightBarButtonItem = newChatButton
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

            inputTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
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

    // MARK: - Actions
    @objc private func startNewChat() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        messages.removeAll()
        let greeting = Message(
            sender: "\(activeAgent.icon) \(activeAgent.name)",
            content: "Percakapan baru dimulai bersama \(activeAgent.name). Silakan ajukan pertanyaan atau berikan instruksi teknis, Pak cURLdev!",
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

        // Prepare JSON payload
        let payload: [String: Any] = [
            "messages": messages.map { ["role": $0.isUser ? "user" : "assistant", "content": $0.content] },
            "active_agent": activeAgent.id,
            "speaker": "Pak cURLdev"
        ]

        var request = URLRequest(url: serverUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 25.0

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
                    self.showErrorResponse("Gagal terhubung ke server lokal (192.168.18.200): \(error.localizedDescription)")
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let reply = json["reply"] as? String else {
                    self.showErrorResponse("Format respon server tidak dikenali.")
                    return
                }

                let receiveGenerator = UINotificationFeedbackGenerator()
                receiveGenerator.notificationOccurred(.success)

                let agentMessage = Message(
                    sender: "\(self.activeAgent.icon) \(self.activeAgent.name)",
                    content: reply,
                    isUser: false
                )
                self.messages.append(agentMessage)
                self.tableView.reloadData()
                self.scrollToBottom()
            }
        }.resume()
    }

    private func showErrorResponse(_ errorText: String) {
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

    // MARK: - Table View Data Source
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as! MessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
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
