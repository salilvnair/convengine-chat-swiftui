import XCTest
import SwiftUI
@testable import ConvEngineChat

private struct EchoEngine: CEChatEngine {
    func reply(to text: String, history: [CEMessage]) async throws -> CEReply {
        CEReply(text: "echo: \(text)")
    }
}

private struct StreamEngine: CEChatEngine {
    func reply(to text: String, history: [CEMessage]) async throws -> CEReply {
        CEReply(text: "unused")
    }
    func streamReply(to text: String, history: [CEMessage]) -> AsyncThrowingStream<String, Error>? {
        AsyncThrowingStream { continuation in
            continuation.yield("a")
            continuation.yield("b")
            continuation.finish()
        }
    }
}

private struct FailEngine: CEChatEngine {
    struct Boom: Error {}
    func reply(to text: String, history: [CEMessage]) async throws -> CEReply { throw Boom() }
}

@MainActor
final class ConvEngineChatTests: XCTestCase {

    func testSendAppendsUserAndAssistant() async throws {
        let vm = CEChatViewModel(engine: EchoEngine(), config: CEConfig())
        vm.send("hi")
        try await waitUntil { !vm.isTyping }
        XCTAssertEqual(vm.messages.count, 2)
        XCTAssertEqual(vm.messages[0].role, .user)
        XCTAssertEqual(vm.messages[1].text, "echo: hi")
    }

    func testStreamingAccumulates() async throws {
        let vm = CEChatViewModel(engine: StreamEngine(), config: CEConfig())
        vm.send("go")
        try await waitUntil { !vm.isTyping && vm.messages.count == 2 }
        XCTAssertEqual(vm.messages[1].text, "ab")
        XCTAssertEqual(vm.messages[1].state, .complete)
    }

    func testFailureProducesFailedState() async throws {
        let vm = CEChatViewModel(engine: FailEngine(), config: CEConfig())
        vm.send("boom")
        try await waitUntil { !vm.isTyping }
        guard case .failed = vm.messages.last?.state else {
            return XCTFail("expected failed state")
        }
    }

    func testNewChatClears() async throws {
        let vm = CEChatViewModel(engine: EchoEngine(), config: CEConfig())
        vm.send("hi")
        try await waitUntil { !vm.isTyping }
        vm.newChat()
        XCTAssertTrue(vm.messages.isEmpty)
        XCTAssertTrue(vm.isEmpty)
    }

    func testRendererPriorityWins() {
        var config = CEConfig()
        config.renderers = [
            CERenderer(key: "low", priority: 10, match: { $0.type == "X" }) { _, _ in Text("low") },
            CERenderer(key: "high", priority: 200, match: { $0.type == "X" }) { _, _ in Text("high") }
        ]
        let vm = CEChatViewModel(engine: EchoEngine(), config: config)
        let msg = CEMessage(role: .assistant, text: "t", type: "X")
        XCTAssertEqual(vm.renderer(for: msg)?.key, "high")
    }

    private func waitUntil(timeout: TimeInterval = 3,
                           _ predicate: @escaping () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !predicate() {
            if Date() > deadline { throw XCTSkip("timeout") }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}
