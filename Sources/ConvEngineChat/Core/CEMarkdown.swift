import SwiftUI
import MarkdownUI

/// Rich Markdown renderer for chat bubbles, backed by
/// [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui).
///
/// This gives us full GitHub-Flavored Markdown for free — headings, lists, task
/// lists, fenced code with syntax-ish styling, blockquotes, thematic breaks,
/// images, links, strikethrough, and (the thing that started this) **tables** —
/// rather than a hand-rolled block parser. We only map `CETheme`'s design tokens
/// onto a `MarkdownUI.Theme` so the rendering matches the surrounding chat UI.
///
/// Public so hosts can reuse the exact same styled renderer for AI text outside the
/// chat (advisor cards, explanations, narratives) — `CEMarkdown(text:theme:)`.
public struct CEMarkdown: View {
    let text: String
    let theme: CETheme

    public init(text: String, theme: CETheme = .default) {
        self.text = text
        self.theme = theme
    }

    public var body: some View {
        Markdown(text)
            .markdownTheme(markdownTheme)
            .markdownTextStyle {
                ForegroundColor(theme.bubbleAgentText)
            }
            .markdownBlockStyle(\.table) { configuration in
                configuration.label
                    .markdownTableBorderStyle(.init(color: theme.accent.opacity(0.25)))
                    .markdownTableBackgroundStyle(
                        .alternatingRows(Color.clear, theme.accent.opacity(0.05))
                    )
                    .markdownMargin(top: 6, bottom: 6)
            }
    }

    // MARK: - CETheme → MarkdownUI.Theme

    private var markdownTheme: MarkdownUI.Theme {
        Theme()
            .text {
                ForegroundColor(theme.bubbleAgentText)
            }
            // Colorful pop: **bold** keywords render in the accent — the "cool" look.
            .strong {
                FontWeight(.bold)
                ForegroundColor(theme.accent)
            }
            .emphasis {
                FontStyle(.italic)
                ForegroundColor(theme.accent.opacity(0.85))
            }
            .link {
                ForegroundColor(theme.accent)
                UnderlineStyle(.single)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.92))
                ForegroundColor(theme.accent)
                BackgroundColor(theme.accent.opacity(0.10))
            }
            .codeBlock { configuration in
                ScrollView(.horizontal, showsIndicators: false) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.system(.caption, design: .monospaced))
                        .padding(10)
                }
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.accent.opacity(0.2), lineWidth: 0.5)
                )
                .markdownMargin(top: 6, bottom: 6)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownMargin(top: 8, bottom: 4)
                    .markdownTextStyle { FontSize(.em(1.4)); FontWeight(.heavy); ForegroundColor(theme.accent) }
            }
            .heading2 { configuration in
                configuration.label
                    .markdownMargin(top: 6, bottom: 4)
                    .markdownTextStyle { FontSize(.em(1.2)); FontWeight(.bold); ForegroundColor(theme.accent) }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownMargin(top: 4, bottom: 2)
                    .markdownTextStyle { FontSize(.em(1.05)); FontWeight(.bold); ForegroundColor(theme.accent) }
            }
            .blockquote { configuration in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accent)
                        .frame(width: 3)
                    configuration.label
                        .markdownTextStyle { FontStyle(.italic); ForegroundColor(.secondary) }
                }
                .fixedSize(horizontal: false, vertical: true)
                .markdownMargin(top: 4, bottom: 4)
            }
            .tableCell { configuration in
                configuration.label
                    .markdownTextStyle {
                        if configuration.row == 0 { FontWeight(.semibold) }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
            }
    }
}
