import SwiftUI

/// The first-open hero screen: glowing avatar, title, subtitle, suggestion chips,
/// centered composer (JS: ChatLanding + LandingChips).
struct CELanding: View {
    @ObservedObject var viewModel: CEChatViewModel
    let config: CEConfig
    let theme: CETheme

    @State private var glow = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if config.showLandingAvatar {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: theme.resolvedGradient,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 84, height: 84)
                        .blur(radius: glow ? 26 : 18)
                        .opacity(0.45)
                        .scaleEffect(glow ? 1.12 : 0.95)
                    CEAvatar(systemImage: config.avatarSystemImage, theme: theme, size: 72)
                        .shadow(color: theme.accent.opacity(0.35), radius: 14, y: 6)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                        glow = true
                    }
                }
                .padding(.bottom, 20)
            }

            Text(config.title)
                .font(theme.titleFont)
                .multilineTextAlignment(.center)

            if config.showLandingSubtitle {
                Text(config.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .padding(.horizontal, 32)
            }

            if !config.chips.isEmpty {
                chipsFlow
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
            }

            Spacer()

            CEComposer(viewModel: viewModel, config: config, theme: theme)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }

    private var chipsFlow: some View {
        VStack(spacing: 8) {
            ForEach(config.chips) { chip in
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        viewModel.send(chip.message)
                    }
                } label: {
                    Text(chip.label)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .background(theme.bubbleAgentBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(theme.accent.opacity(0.18), lineWidth: 0.75)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
