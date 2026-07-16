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
                VStack(alignment: .leading, spacing: 0) {
                    CEAssistantBubble(message: message, theme: theme,
                                      avatarSystemImage: config.avatarSystemImage)
                    if config.showFeedback, message.state == .complete,
                       message.id == lastCompletedAssistantId {
                        CEFeedbackRow(message: message, theme: theme, viewModel: viewModel)
                    }
                }
            }

        case .system:
            EmptyView()
        }
    }

    private var lastCompletedAssistantId: UUID? {
        viewModel.messages.last(where: { $0.role == .assistant && $0.state == .complete })?.id
    }
}
