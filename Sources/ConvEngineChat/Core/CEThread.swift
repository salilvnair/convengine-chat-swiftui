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

/// Assistant bubble + feedback row that reveals on hover (pointer devices) or tap (touch),
/// with a soft scale-in animation. The last message shows feedback by default.
private struct CEAssistantMessageRow: View {
    let message: CEMessage
    let theme: CETheme
    let config: CEConfig
    @ObservedObject var viewModel: CEChatViewModel

    @State private var hovering = false
    @State private var tapped = false

    private var isLast: Bool {
        viewModel.messages.last(where: { $0.role == .assistant && $0.state == .complete })?.id == message.id
    }
    private var showFeedback: Bool {
        config.showFeedback && message.state == .complete && (hovering || tapped || isLast)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            CEAssistantBubble(message: message, theme: theme,
                              avatarSystemImage: config.avatarSystemImage)
                // Genie-style subtle zoom on hover.
                .scaleEffect(hovering ? 1.015 : 1.0, anchor: .leading)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hovering)
                .onTapGesture { withAnimation(.spring(response: 0.3)) { tapped.toggle() } }

            if showFeedback {
                CEFeedbackRow(message: message, theme: theme, viewModel: viewModel)
                    .transition(.scale(scale: 0.6, anchor: .leading).combined(with: .opacity))
            }
        }
        .onHover { h in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { hovering = h }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showFeedback)
    }
}
