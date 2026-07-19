import SwiftUI

/// User bubble — accent gradient, asymmetric corner (tail effect).
struct CEUserBubble: View {
    let message: CEMessage
    let theme: CETheme

    var body: some View {
        HStack {
            Spacer(minLength: 48)
            Text(message.text)
                .font(theme.messageFont)
                .foregroundColor(theme.bubbleUserText)
                .textSelection(.enabled)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    LinearGradient(colors: theme.resolvedGradient,
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(CEBubbleShape(radius: theme.bubbleCornerRadius, tail: .trailing))
                .shadow(color: theme.accent.opacity(0.25), radius: 6, y: 3)
                .ceMessageActions(message.text)
        }
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity))
    }
}

/// Assistant bubble — surface color, markdown text, avatar dot, streaming cursor.
struct CEAssistantBubble: View {
    let message: CEMessage
    let theme: CETheme
    let avatarSystemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CEAvatar(systemImage: avatarSystemImage, theme: theme, size: 26)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                // Rich markdown rendering (MDViewer-style) — headings, lists, code, quotes.
                CEMarkdown(text: message.text, theme: theme)
                    .textSelection(.enabled)
                if case .streaming = message.state {
                    CEStreamingCursor(theme: theme)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(theme.bubbleAgentBg)
            .clipShape(CEBubbleShape(radius: theme.bubbleCornerRadius, tail: .leading))
            .overlay(
                CEBubbleShape(radius: theme.bubbleCornerRadius, tail: .leading)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .ceMessageActions(message.text)

            Spacer(minLength: 40)
        }
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity))
    }
}

/// Failed bubble — error text + retry.
struct CEFailedBubble: View {
    let error: String
    let theme: CETheme
    let onRetry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(.orange)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 8) {
                Text(error.isEmpty ? "Something went wrong." : error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button(action: onRetry) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.orange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            Spacer(minLength: 40)
        }
    }
}

// MARK: - Long-press message actions

extension View {
    /// iMessage-style long-press menu on a chat bubble: Copy the whole message + Share.
    /// Works on both plain-text (user) and Markdown-rendered (assistant) bubbles, where
    /// per-character `.textSelection` isn't always honored.
    func ceMessageActions(_ text: String) -> some View {
        contextMenu {
            Button {
                CEPasteboard.copy(text)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            #if canImport(UIKit)
            ShareLink(item: text) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            #endif
        }
    }
}

/// Cross-platform clipboard write (package also compiles on macOS).
enum CEPasteboard {
    static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Rounded-rect bubble with one squared-off corner as the "tail".
struct CEBubbleShape: Shape {
    enum Tail { case leading, trailing }
    let radius: CGFloat
    let tail: Tail

    func path(in rect: CGRect) -> Path {
        let small: CGFloat = 6
        let corners: (tl: CGFloat, tr: CGFloat, bl: CGFloat, br: CGFloat) = tail == .trailing
            ? (radius, radius, radius, small)
            : (radius, radius, small, radius)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + corners.tl, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - corners.tr, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - corners.tr, y: rect.minY + corners.tr),
                 radius: corners.tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - corners.br))
        p.addArc(center: CGPoint(x: rect.maxX - corners.br, y: rect.maxY - corners.br),
                 radius: corners.br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + corners.bl, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + corners.bl, y: rect.maxY - corners.bl),
                 radius: corners.bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + corners.tl))
        p.addArc(center: CGPoint(x: rect.minX + corners.tl, y: rect.minY + corners.tl),
                 radius: corners.tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// Gradient-ring avatar (landing hero + per-message).
struct CEAvatar: View {
    let systemImage: String
    let theme: CETheme
    var size: CGFloat = 26

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: theme.resolvedGradient,
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: systemImage)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Blinking block cursor shown while streaming.
struct CEStreamingCursor: View {
    let theme: CETheme
    @State private var visible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(theme.accent)
            .frame(width: 7, height: 14)
            .opacity(visible ? 1 : 0.15)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever()) { visible.toggle() }
            }
    }
}

/// Three staggered bouncing dots (JS: ChatTypingIndicator).
struct CETypingIndicator: View {
    let theme: CETheme
    @State private var phase = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CEAvatar(systemImage: "sparkles", theme: theme, size: 26)
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary.opacity(0.55))
                        .frame(width: 7, height: 7)
                        .offset(y: phase ? -4 : 2)
                        .animation(.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15), value: phase)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(theme.bubbleAgentBg)
            .clipShape(CEBubbleShape(radius: theme.bubbleCornerRadius, tail: .leading))
            Spacer()
        }
        .onAppear { phase = true }
        .transition(.opacity)
    }
}

/// 👍👎 row under assistant messages (JS: ChatFeedbackRow).
struct CEFeedbackRow: View {
    let message: CEMessage
    let theme: CETheme
    @ObservedObject var viewModel: CEChatViewModel

    var body: some View {
        let given = viewModel.feedbackGiven[message.id]
        HStack(spacing: 8) {
            Spacer().frame(width: 26)   // align under bubble, past avatar
            button(.up, systemName: given == .up ? "hand.thumbsup.fill" : "hand.thumbsup",
                   active: given == .up)
            button(.down, systemName: given == .down ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                   active: given == .down)
            Spacer()
        }
        .padding(.top, 2)
    }

    @State private var hoveredUp = false
    @State private var hoveredDown = false
    @State private var pressedUp = false
    @State private var pressedDown = false

    private func button(_ verdict: CEFeedback.Verdict, systemName: String, active: Bool) -> some View {
        let hovered = verdict == .up ? hoveredUp : hoveredDown
        let pressed = verdict == .up ? pressedUp : pressedDown
        // Genie zoom: pressed (touch) > hovered (pointer) > active (chosen) > rest.
        let scale: CGFloat = pressed ? 1.4 : (active ? 1.2 : (hovered ? 1.3 : 1))
        return Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(active ? theme.accent : (hovered ? theme.accent.opacity(0.85) : .secondary.opacity(0.65)))
            .frame(width: 34, height: 30)                 // generous touch target
            .background(
                Circle().fill(theme.accent.opacity((hovered || pressed) ? 0.12 : 0))
                    .frame(width: 30, height: 30)
            )
            .scaleEffect(scale)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: scale)
            .onHover { h in
                if verdict == .up { hoveredUp = h } else { hoveredDown = h }
            }
            // A touch-friendly press that visibly zooms on tap-down, then registers on release.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard viewModel.feedbackGiven[message.id] == nil else { return }
                        if verdict == .up { pressedUp = true } else { pressedDown = true }
                    }
                    .onEnded { _ in
                        if verdict == .up { pressedUp = false } else { pressedDown = false }
                        guard viewModel.feedbackGiven[message.id] == nil else { return }
                        viewModel.giveFeedback(verdict, for: message)
                    }
            )
            .allowsHitTesting(viewModel.feedbackGiven[message.id] == nil || active)
    }
}
