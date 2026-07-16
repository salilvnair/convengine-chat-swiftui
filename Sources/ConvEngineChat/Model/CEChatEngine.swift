import Foundation

/// The transport seam. The host app implements this to connect ANY backend —
/// an LLM API, a ConvEngine server, or a local model. Mirrors the JS library's
/// apiHost abstraction but protocol-first so iOS apps aren't tied to REST.
public protocol CEChatEngine {
    /// One-shot reply. Called when `streamReply` returns nil.
    func reply(to text: String, history: [CEMessage]) async throws -> CEReply

    /// Optional streaming reply (JS: SSE/STOMP transport). Return a stream of text
    /// chunks and the bubble grows as they arrive. Default: nil → one-shot `reply`.
    func streamReply(to text: String, history: [CEMessage]) -> AsyncThrowingStream<String, Error>?
}

public extension CEChatEngine {
    func streamReply(to text: String, history: [CEMessage]) -> AsyncThrowingStream<String, Error>? { nil }
}

/// Ready-made engine for a ConvEngine backend (parity with the JS library's REST mode).
/// POSTs `{ conversationId?, message, inputParams }` to `{apiHost}/api/convengine/chat`
/// and expects `{ reply: string, type?: string }`.
public struct ConvEngineRestEngine: CEChatEngine {
    public let apiHost: String
    public var conversationId: String?
    public var inputParams: [String: String]
    public var endpointPath: String

    public init(apiHost: String,
                conversationId: String? = nil,
                inputParams: [String: String] = [:],
                endpointPath: String = "/api/convengine/chat") {
        self.apiHost = apiHost
        self.conversationId = conversationId
        self.inputParams = inputParams
        self.endpointPath = endpointPath
    }

    public func reply(to text: String, history: [CEMessage]) async throws -> CEReply {
        guard let url = URL(string: apiHost + endpointPath) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["message": text]
        if let conversationId { body["conversationId"] = conversationId }
        if !inputParams.isEmpty { body["inputParams"] = inputParams }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        let replyText = (json["reply"] as? String)
            ?? (json["message"] as? String)
            ?? (json["text"] as? String)
            ?? ""
        return CEReply(text: replyText, type: json["type"] as? String)
    }
}
