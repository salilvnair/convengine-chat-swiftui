import SwiftUI

/// The message composer — a tall, Claude-style box: the text input sits on
/// top and grows with content, with the accessory (e.g. mic) and send button
/// on their own row underneath.
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
        RoundedRectangle(cornerRadius: config.composerShape == .round ? 28 : 16,
                         style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Apple's own native multi-line-growing text input (iOS 16+).
            // No .onSubmit here on purpose — attaching one hijacks the Return
            // key into "send" instead of "insert a newline", which defeats
            // axis: .vertical's whole point. Ditto Claude's iOS app: Return
            // grows the composer, only the button below actually sends.
            // minHeight (rather than a greedy Spacer below) is what makes
            // this a tall box: it reserves the empty input area while still
            // letting the whole composer hug its content, so it grows with
            // the text instead of swallowing the entire screen.
            TextField(config.placeholder, text: $viewModel.input, axis: .vertical)
                .lineLimit(1...8)
                .font(theme.messageFont)
                .focused($focused)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)

            HStack(spacing: 10) {
                if let accessory = config.composerLeadingAccessory {
                    accessory
                }

                Spacer(minLength: 0)

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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(theme.composerBg)
        .clipShape(shape)
        .overlay(shape.stroke(Color.primary.opacity(0.07), lineWidth: 0.5))
        .contentShape(shape)
        // Tapping anywhere in the box focuses the field, not just the one
        // text line — the empty area below it is part of the input surface.
        .onTapGesture { focused = true }
        .onAppear { if isFocusedOnAppear { focused = true } }
    }
}
