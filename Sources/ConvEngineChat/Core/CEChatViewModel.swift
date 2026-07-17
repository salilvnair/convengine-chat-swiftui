import SwiftUI

/// Chat state machine: message list, typing state, send/stream/retry, feedback.
@MainActor
public final class CEChatViewModel: ObservableObject {
    @Published public private(set) var messages: [CEMessage] = []
    @Published public var input: String = ""
    @Published public private(set) var isTyping = false
    @Published var feedbackGiven: [UUID: CEFeedback.Verdict] = [:]

    private(set) var engine: CEChatEngine
    let config: CEConfig

    private var currentTask: Task<Void, Never>?

    public init(engine: CEChatEngine, config: CEConfig) {
        self.engine = engine
        self.config = config
    }

    /// Swap the engine after construction. Useful when the view model is created as a
    /// `@StateObject` (before the app's environment/dependencies are available) and the
    /// real engine is wired in `.onAppear`.
    public func rebindEngine(_ engine: CEChatEngine) {
        self.engine = engine
    }

    public var isEmpty: Bool { messages.isEmpty }

    // MARK: - Sending

    public func sendCurrentInput() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isTyping else { return }
        input = ""
        send(text)
    }

    public func send(_ text: String) {
        config.onMessage?(text)
        messages.append(CEMessage(role: .user, text: text))
        isTyping = true

        currentTask = Task { [weak self] in
            guard let self else { return }
            let history = self.messages

            // Streaming path (JS: SSE) — grow one assistant bubble chunk by chunk.
            if let stream = self.engine.streamReply(to: text, history: history) {
                var assistant = CEMessage(role: .assistant, text: "", state: .streaming)
                self.messages.append(assistant)
                do {
                    for try await chunk in stream {
                        assistant.text += chunk
                        self.replace(assistant)
                        if self.isTyping { self.isTyping = false }
                    }
                    assistant.state = .complete
                    self.replace(assistant)
                    self.config.onResponse?(assistant.text)
                } catch {
                    assistant.state = .failed(error.localizedDescription)
                    self.replace(assistant)
                }
                self.isTyping = false
                return
            }

            // One-shot path.
            do {
                let reply = try await self.engine.reply(to: text, history: history)
                self.messages.append(CEMessage(role: .assistant,
                                               text: reply.text,
                                               type: reply.type,
                                               meta: reply.meta))
                self.config.onResponse?(reply.text)
            } catch {
                self.messages.append(CEMessage(role: .assistant,
                                               text: "",
                                               state: .failed(error.localizedDescription)))
            }
            self.isTyping = false
        }
    }

    /// Retry the last user message after a failure.
    public func retryLast() {
        guard let lastUser = messages.last(where: { $0.role == .user }) else { return }
        // Drop the failed assistant bubble.
        if let failedIdx = messages.lastIndex(where: {
            if case .failed = $0.state { return true } else { return false }
        }) {
            messages.remove(at: failedIdx)
        }
        isTyping = true
        let text = lastUser.text
        // Remove the duplicate user bubble that `send` would add.
        messages.removeAll { $0.id == lastUser.id }
        send(text)
    }

    public func newChat() {
        currentTask?.cancel()
        messages.removeAll()
        feedbackGiven.removeAll()
        input = ""
        isTyping = false
    }

    // MARK: - Feedback

    func giveFeedback(_ verdict: CEFeedback.Verdict, for message: CEMessage) {
        feedbackGiven[message.id] = verdict
        config.onFeedback?(CEFeedback(messageId: message.id,
                                      verdict: verdict,
                                      messageText: message.text))
    }

    // MARK: - Renderers

    func renderer(for message: CEMessage) -> CERendererProvider? {
        config.renderers
            .filter { $0.matches(message) }
            .max(by: { $0.priority < $1.priority })
    }

    var actions: CEActions { CEActions(viewModel: self) }

    // MARK: - Helpers

    private func replace(_ message: CEMessage) {
        if let idx = messages.firstIndex(where: { $0.id == message.id }) {
            messages[idx] = message
        }
    }
}
