import SwiftUI

/// The scrolling message thread with auto-scroll, feedback rows, and custom renderers.
struct CEThread: View {
    @ObservedObject var viewModel: CEChatViewModel
    let config: CEConfig
    let theme: CETheme

    private static let bottomAnchor = "ce-bottom"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.messages) { message in
                        messageView(message)
                            .id(message.id)
                    }
                    if viewModel.isTyping {
                        CETypingIndicator(theme: theme)
                    }
                    Color.clear.frame(height: 1).id(Self.bottomAnchor)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.messages.last?.text) { _ in
                // Streaming growth — keep pinned to bottom.
                proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
            }
            .onChange(of: viewModel.isTyping) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func messageView(_ message: CEMessage) -> some View {
        switch message.role {
        case .user:
            CEUserBubble(message: message, theme: theme)

        case .assistant:
            if case .failed(let error) = message.state {
                CEFailedBubble(error: error, theme: theme) {
                    viewModel.retryLast()
                }
            } else if let custom = viewModel.renderer(for: message) {
                HStack(alignment: .top, spacing: 8) {
                    CEAvatar(systemImage: config.avatarSystemImage, theme: theme, size: 26)
                    custom.makeView(for: message, actions: viewModel.actions)
                    Spacer(minLength: 40)
                }
            } else {
                CEAssistantMessageRow(message: message, theme: theme, config: config,
                                      viewModel: viewModel)
            }

        case .system:
            EmptyView()
        }
    }

    private var lastCompletedAssistantId: UUID? {
        viewModel.messages.last(where: { $0.role == .assistant && $0.state == .complete })?.id
    }
}

/// Assistant bubble + feedback row.
///
/// The feedback row is always present (touch devices can't hover), but rests dim/compact and
/// brightens + lifts when the bubble is hovered (pointer devices) or when it's the latest reply.
/// Each thumb has a spring press-scale (touch) AND a hover zoom (pointer) — the genie effect.
private struct CEAssistantMessageRow: View {
    let message: CEMessage
    let theme: CETheme
    let config: CEConfig
    @ObservedObject var viewModel: CEChatViewModel

    @State private var hovering = false

    private var isLast: Bool {
        viewModel.messages.last(where: { $0.role == .assistant && $0.state == .complete })?.id == message.id
    }
    /// Active = latest message or currently hovered → full opacity. Otherwise a quiet resting state.
    private var active: Bool { hovering || isLast }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            CEAssistantBubble(message: message, theme: theme,
                              avatarSystemImage: config.avatarSystemImage)
                .scaleEffect(hovering ? 1.012 : 1.0, anchor: .leading)

            if config.showFeedback && message.state == .complete {
                CEFeedbackRow(message: message, theme: theme, viewModel: viewModel)
                    .opacity(active ? 1 : 0.45)
                    .scaleEffect(active ? 1 : 0.92, anchor: .leading)
            }
        }
        .onHover { h in hovering = h }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hovering)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: active)
    }
}
