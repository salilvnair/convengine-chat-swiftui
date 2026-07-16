import Foundation

/// A single chat message. Mirrors the JS library's message shape:
/// role + text + optional semantic `type` (drives custom renderers) + string metadata.
public struct CEMessage: Identifiable, Equatable {
    public enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    public enum State: Equatable {
        case complete
        case streaming
        case failed(String)      // error description — renders a retry affordance
    }

    public let id: UUID
    public let role: Role
    public var text: String
    /// Semantic type for renderer matching (JS: `effectiveType`). `nil` → default renderer.
    public var type: String?
    /// Arbitrary string metadata attached by the engine (JS: payload).
    public var meta: [String: String]
    public var state: State
    public let sentAt: Date

    public init(id: UUID = UUID(),
                role: Role,
                text: String,
                type: String? = nil,
                meta: [String: String] = [:],
                state: State = .complete,
                sentAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.type = type
        self.meta = meta
        self.state = state
        self.sentAt = sentAt
    }
}

/// Engine reply: text plus optional renderer type + metadata.
public struct CEReply {
    public let text: String
    public let type: String?
    public let meta: [String: String]

    public init(text: String, type: String? = nil, meta: [String: String] = [:]) {
        self.text = text
        self.type = type
        self.meta = meta
    }
}

/// A landing-screen suggestion chip (JS: LandingChips).
public struct CEChip: Identifiable, Equatable {
    public let id: UUID
    public let label: String
    /// The message actually sent when tapped (defaults to the label).
    public let message: String

    public init(_ label: String, message: String? = nil) {
        self.id = UUID()
        self.label = label
        self.message = message ?? label
    }
}

/// Feedback emitted by the 👍👎 row (JS: onFeedback).
public struct CEFeedback {
    public enum Verdict { case up, down }
    public let messageId: UUID
    public let verdict: Verdict
    public let messageText: String
}
