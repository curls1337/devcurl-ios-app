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
        AgentProfile(id: "ubuntu-admin", name: "Ubuntu Admin", role: "Root & Server Controller", icon: "🐧"),
        AgentProfile(id: "product-manager", name: "Product Manager", role: "PRD & Backlog MVP", icon: "📦"),
        AgentProfile(id: "ui-ux-designer", name: "UI/UX Designer", role: "Liquid Glass & Ergonomi", icon: "🎨"),
        AgentProfile(id: "frontend-developer", name: "Frontend Developer", role: "Swift iOS & React", icon: "💻"),
        AgentProfile(id: "backend-developer", name: "Backend Developer", role: "APIs & SQLite Database", icon: "⚙️"),
        AgentProfile(id: "solution-architect", name: "Solution Architect", role: "System & Security", icon: "🏗️"),
        AgentProfile(id: "qa-security", name: "QA & Security", role: "Testing & OWASP Audit", icon: "🛡️"),
        AgentProfile(id: "all", name: "Semua Agen", role: "Roundtable Collaboration", icon: "👥")
    ]
}
