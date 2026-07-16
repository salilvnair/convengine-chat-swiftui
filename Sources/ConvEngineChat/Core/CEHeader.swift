import SwiftUI

/// Chat header: title with pulsing status dot + "new chat" button (JS: ChatHeader).
struct CEHeader: View {
    @ObservedObject var viewModel: CEChatViewModel
    let config: CEConfig
    let theme: CETheme

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 10) {
            CEAvatar(systemImage: config.avatarSystemImage, theme: theme, size: 30)

            HStack(spacing: 6) {
                Text(config.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .lineLimit(1)
                if config.showHeaderDot {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulse ? 1.25 : 0.9)
                        .opacity(pulse ? 0.7 : 1)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                pulse = true
                            }
                        }
                }
            }

            Spacer()

            if config.showNewChat, !viewModel.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.4)) { viewModel.newChat() }
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.accent)
                        .frame(width: 32, height: 32)
                        .background(theme.accent.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.5)
        }
    }
}
