import SwiftUI

/// Actions handed to custom renderers (JS: `actions.submit`).
@MainActor
public struct CEActions {
    let viewModel: CEChatViewModel

    /// Submit a message programmatically — shows `displayText` as the user bubble
    /// and sends it through the engine.
    public func submit(_ displayText: String) {
        viewModel.send(displayText)
    }
}

/// Custom renderer provider — the SwiftUI twin of the JS `renderers` array.
/// Highest `priority` wins; built-in markdown renderer runs at priority 0.
public protocol CERendererProvider {
    var key: String { get }
    var priority: Int { get }
    /// Return true to claim this message.
    func matches(_ message: CEMessage) -> Bool
    /// Build the view for a claimed message.
    @MainActor func makeView(for message: CEMessage, actions: CEActions) -> AnyView
}

/// Type-erased convenience implementation:
///
/// ```swift
/// CERenderer(key: "PayCard", priority: 200,
///            match: { $0.type == "PayCard" }) { message, actions in
///     Button("Pay \(message.meta["amount"] ?? "")") {
///         actions.submit("Pay it")
///     }
/// }
/// ```
public struct CERenderer: CERendererProvider {
    public let key: String
    public let priority: Int
    private let matcher: (CEMessage) -> Bool
    private let builder: @MainActor (CEMessage, CEActions) -> AnyView

    public init<V: View>(key: String,
                         priority: Int = 100,
                         match: @escaping (CEMessage) -> Bool,
                         @ViewBuilder content: @MainActor @escaping (CEMessage, CEActions) -> V) {
        self.key = key
        self.priority = priority
        self.matcher = match
        self.builder = { message, actions in AnyView(content(message, actions)) }
    }

    public func matches(_ message: CEMessage) -> Bool { matcher(message) }

    @MainActor
    public func makeView(for message: CEMessage, actions: CEActions) -> AnyView {
        builder(message, actions)
    }
}
