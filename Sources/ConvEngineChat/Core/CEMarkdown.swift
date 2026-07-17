import SwiftUI

/// Lightweight block-level Markdown renderer — the SwiftUI twin of dui2's MarkdownView.
/// Renders headings, bullet/numbered lists, fenced code blocks, blockquotes, horizontal
/// rules, and inline **bold** / *italic* / `code` / [links]. Colorful + theme-aware.
///
/// It's deliberately dependency-free: block parsing is done by hand; inline formatting
/// reuses `AttributedString(markdown:)`.
struct CEMarkdown: View {
    let text: String
    let theme: CETheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(CEMarkdownParser.parse(text).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: CEMarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let content):
            inline(content)
                .font(headingFont(level))
                .foregroundColor(.primary)
                .padding(.top, level <= 2 ? 2 : 0)

        case .paragraph(let content):
            inline(content)
                .font(theme.messageFont)
                .foregroundColor(theme.bubbleAgentText)
                .fixedSize(horizontal: false, vertical: true)

        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle().fill(theme.accent).frame(width: 5, height: 5)
                            .padding(.top, 6)
                        inline(item).font(theme.messageFont)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(idx + 1).")
                            .font(theme.messageFont.weight(.semibold))
                            .foregroundColor(theme.accent)
                        inline(item).font(theme.messageFont)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .codeBlock(let code, let lang):
            VStack(alignment: .leading, spacing: 0) {
                if let lang, !lang.isEmpty {
                    Text(lang.uppercased())
                        .font(.system(size: 9, weight: .heavy)).kerning(0.5)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10).padding(.top, 6)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(10)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.accent.opacity(0.2), lineWidth: 0.5))

        case .quote(let content):
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2).fill(theme.accent).frame(width: 3)
                inline(content).font(theme.messageFont.italic())
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)

        case .rule:
            Divider().padding(.vertical, 2)
        }
    }

    /// Inline formatting via AttributedString markdown (bold/italic/code/links).
    private func inline(_ s: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: s,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            var styled = attributed
            // Tint inline code + links with the accent.
            for run in styled.runs {
                if run.inlinePresentationIntent?.contains(.code) == true {
                    styled[run.range].foregroundColor = theme.accent
                }
                if run.link != nil {
                    styled[run.range].foregroundColor = theme.accent
                    styled[run.range].underlineStyle = .single
                }
            }
            return Text(styled)
        }
        return Text(s)
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1:  return .system(size: 20, weight: .heavy)
        case 2:  return .system(size: 17, weight: .bold)
        default: return .system(size: 15, weight: .bold)
        }
    }
}

// MARK: - Block model + parser

enum CEMarkdownBlock {
    case heading(level: Int, content: String)
    case paragraph(String)
    case bulletList([String])
    case numberedList([String])
    case codeBlock(code: String, lang: String?)
    case quote(String)
    case rule
}

enum CEMarkdownParser {
    static func parse(_ text: String) -> [CEMarkdownBlock] {
        var blocks: [CEMarkdownBlock] = []
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")

        var i = 0
        var paragraph: [String] = []

        func flushParagraph() {
            let joined = paragraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if !joined.isEmpty { blocks.append(.paragraph(joined)) }
            paragraph.removeAll()
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Fenced code block
            if trimmed.hasPrefix("```") {
                flushParagraph()
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i]); i += 1
                }
                blocks.append(.codeBlock(code: code.joined(separator: "\n"), lang: lang.isEmpty ? nil : lang))
                i += 1
                continue
            }

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph(); blocks.append(.rule); i += 1; continue
            }

            // Heading
            if let hash = trimmed.range(of: #"^#{1,6}\s"#, options: .regularExpression) {
                flushParagraph()
                let level = trimmed.distance(from: trimmed.startIndex, to: hash.upperBound) - 1
                let content = String(trimmed[hash.upperBound...])
                blocks.append(.heading(level: min(level, 6), content: content))
                i += 1; continue
            }

            // Blockquote
            if trimmed.hasPrefix(">") {
                flushParagraph()
                var quote: [String] = []
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    quote.append(String(lines[i].trimmingCharacters(in: .whitespaces).dropFirst()).trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                blocks.append(.quote(quote.joined(separator: " ")))
                continue
            }

            // Bullet list
            if trimmed.range(of: #"^[-*+]\s"#, options: .regularExpression) != nil {
                flushParagraph()
                var items: [String] = []
                while i < lines.count,
                      let r = lines[i].trimmingCharacters(in: .whitespaces).range(of: #"^[-*+]\s"#, options: .regularExpression) {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    items.append(String(t[r.upperBound...]))
                    i += 1
                }
                blocks.append(.bulletList(items))
                continue
            }

            // Numbered list
            if trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                flushParagraph()
                var items: [String] = []
                while i < lines.count,
                      let r = lines[i].trimmingCharacters(in: .whitespaces).range(of: #"^\d+\.\s"#, options: .regularExpression) {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    items.append(String(t[r.upperBound...]))
                    i += 1
                }
                blocks.append(.numberedList(items))
                continue
            }

            // Blank line → paragraph break
            if trimmed.isEmpty {
                flushParagraph(); i += 1; continue
            }

            paragraph.append(trimmed)
            i += 1
        }
        flushParagraph()
        return blocks
    }
}
