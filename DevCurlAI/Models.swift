import Foundation

public struct Message: Codable {
    public let id: String
    public let sender: String
    public let content: String
    public let isUser: Bool
    public let timestamp: Date

    public init(id: String = UUID().uuidString, sender: String, content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.sender = sender
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

public struct AgentProfile {
    public let id: String
    public let name: String
    public let role: String
    public let icon: String

    public static let available: [AgentProfile] = [
        AgentProfile(id: "hermes-agent", name: "Hermes Orchestrator", role: "Sutradara & Automation Controller", icon: "🧠"),
        AgentProfile(id: "ubuntu-admin", name: "Ubuntu Admin", role: "Root & Server Controller", icon: "🐧"),
        AgentProfile(id: "video-producer", name: "Video Producer", role: "Naskah & Hook Video Remotion", icon: "🎬"),
        AgentProfile(id: "marketing-strategist", name: "Marketing Strategist", role: "Strategi Konten & Viralitas", icon: "📈"),
        AgentProfile(id: "product-manager", name: "Product Manager", role: "PRD & Backlog MVP", icon: "📦"),
        AgentProfile(id: "ui-ux-designer", name: "UI/UX Designer", role: "Liquid Glass & Ergonomi", icon: "🎨"),
        AgentProfile(id: "frontend-developer", name: "Frontend Developer", role: "Swift iOS & React", icon: "💻"),
        AgentProfile(id: "backend-developer", name: "Backend Developer", role: "APIs & SQLite Database", icon: "⚙️"),
        AgentProfile(id: "solution-architect", name: "Solution Architect", role: "System & Security", icon: "🏗️"),
        AgentProfile(id: "qa-security", name: "QA & Security", role: "Testing & OWASP Audit", icon: "🛡️"),
        AgentProfile(id: "all", name: "Semua Agen", role: "Roundtable Collaboration", icon: "👥")
    ]
}

public class AppSettings {
    public static let shared = AppSettings()
    
    private let kServerUrl = "nik_ai_server_url_v2"
    private let kApiKey = "nik_ai_api_key_v2"
    private let kModel = "nik_ai_model_v2"
    private let kAutoVoice = "nik_ai_auto_voice_v2"
    
    public var serverUrl: String {
        get {
            let saved = UserDefaults.standard.string(forKey: kServerUrl)
            if let saved = saved, !saved.contains("192.168") && !saved.contains("8080") && !saved.isEmpty {
                return saved
            }
            return "https://nik.5nod.com/v1/chat/completions"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kServerUrl)
        }
    }
    
    public var apiKey: String {
        get {
            return UserDefaults.standard.string(forKey: kApiKey) ?? "f86a19673527f4925d94012214514f34d0b86b33553052793c141279fd87effa"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kApiKey)
        }
    }
    
    public var model: String {
        get {
            return UserDefaults.standard.string(forKey: kModel) ?? "hermes-agent"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kModel)
        }
    }
    
    public var autoVoice: Bool {
        get {
            if UserDefaults.standard.object(forKey: kAutoVoice) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: kAutoVoice)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kAutoVoice)
        }
    }
}
