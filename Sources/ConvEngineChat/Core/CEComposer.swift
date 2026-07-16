import SwiftUI

/// The message composer — pill or rect, multiline, animated send button,
/// optional leading accessory (e.g. a mic button).
struct CEComposer: View {
    @ObservedObject var viewModel: CEChatViewModel
    let config: CEConfig
    let theme: CETheme
    var isFocusedOnAppear: Bool = false

    @FocusState private var focused: Bool

    private var canSend: Bool {
        !viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !viewModel.isTyping
    }

    private var shape: some InsettableShape {
        RoundedRectangle(cornerRadius: config.composerShape == .round ? 26 : 14,
                         style: .continuous)
    }

    var body: some View {
        HStack(spacing: 10) {
            if let accessory = config.composerLeadingAccessory {
                accessory
            }

            TextField(config.placeholder, text: $viewModel.input, axis: .vertical)
                .lineLimit(1...5)
                .font(theme.messageFont)
                .focused($focused)
                .onSubmit { viewModel.sendCurrentInput() }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.sendCurrentInput()
                }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Group {
                            if canSend {
                                LinearGradient(colors: theme.resolvedGradient,
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            } else {
                                Color.secondary.opacity(0.35)
                            }
                        }
                    )
                    .clipShape(Circle())
                    .scaleEffect(canSend ? 1 : 0.92)
                    .animation(.spring(response: 0.3), value: canSend)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(theme.composerBg)
        .clipShape(shape)
        .overlay(shape.stroke(Color.primary.opacity(0.07), lineWidth: 0.5))
        .onAppear { if isFocusedOnAppear { focused = true } }
    }
}
