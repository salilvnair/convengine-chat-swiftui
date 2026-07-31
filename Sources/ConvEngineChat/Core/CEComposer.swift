import SwiftUI

/// Reports the natural (unclamped) height of the invisible measuring Text
/// in CEComposer, so the visible TextEditor can grow to match it.
private struct CEComposerHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// The message composer — pill or rect, multiline, animated send button,
/// optional leading accessory (e.g. a mic button).
struct CEComposer: View {
    @ObservedObject var viewModel: CEChatViewModel
    let config: CEConfig
    let theme: CETheme
    var isFocusedOnAppear: Bool = false

    @FocusState private var focused: Bool
    @State private var measuredHeight: CGFloat = 0

    // ~1 line and ~5 lines at the message font — TextEditor has no line-limit
    // API of its own, so growth is driven by measuring text height instead.
    private let minHeight: CGFloat = 22
    private let maxHeight: CGFloat = 120

    private var canSend: Bool {
        !viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !viewModel.isTyping
    }

    private var shape: some InsettableShape {
        RoundedRectangle(cornerRadius: config.composerShape == .round ? 26 : 14,
                         style: .continuous)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if let accessory = config.composerLeadingAccessory {
                accessory
            }

            ZStack(alignment: .topLeading) {
                // Invisible twin — measures the natural height for the
                // current text so the TextEditor can grow to match (clamped
                // between minHeight/maxHeight). TextEditor itself can't
                // report its own intrinsic content size.
                Text(viewModel.input.isEmpty ? " " : viewModel.input)
                    .font(theme.messageFont)
                    .foregroundColor(.clear)
                    .padding(.vertical, 8)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: CEComposerHeightKey.self, value: geo.size.height)
                        }
                    )
                    .allowsHitTesting(false)

                if viewModel.input.isEmpty {
                    Text(config.placeholder)
                        .font(theme.messageFont)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                // TextEditor, unlike TextField(axis: .vertical), NEVER treats
                // Return as "submit" — Return always inserts a newline here,
                // guaranteed. Ditto Claude's iOS app: Return grows the
                // composer, only the button below actually sends.
                TextEditor(text: $viewModel.input)
                    .font(theme.messageFont)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, -5)   // cancel TextEditor's built-in inset to line up with the placeholder/measuring text
                    .padding(.vertical, 0)
            }
            .frame(height: min(max(measuredHeight, minHeight), maxHeight))
            .onPreferenceChange(CEComposerHeightKey.self) { measuredHeight = $0 }

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
