import SwiftUI

/// Design tokens — the SwiftUI twin of the JS library's `--ce-*` CSS custom properties.
/// Every color falls back to a semantic system color, so light/dark just work.
public struct CETheme {

    // ── Accent ───────────────────────────────────────────────────────
    public var accent: Color = .indigo
    /// User bubble + send button gradient. Defaults to accent → accent-dimmed.
    public var accentGradient: [Color]? = nil

    // ── Bubbles ──────────────────────────────────────────────────────
    public var bubbleUserText: Color = .white
    public var bubbleAgentBg: Color = Color(uiColorSecondarySystemBackground)
    public var bubbleAgentText: Color = .primary
    public var bubbleCornerRadius: CGFloat = 18

    // ── Surfaces ─────────────────────────────────────────────────────
    public var panelBg: Color = Color(uiColorSystemBackground)
    public var composerBg: Color = Color(uiColorSecondarySystemBackground)

    // ── Typography ───────────────────────────────────────────────────
    public var messageFont: Font = .subheadline
    public var titleFont: Font = .system(size: 24, weight: .heavy, design: .rounded)

    public init() {}

    var resolvedGradient: [Color] {
        accentGradient ?? [accent, accent.opacity(0.75)]
    }

    public static let `default` = CETheme()
}

// Cross-platform semantic colors (package also compiles on macOS).
#if canImport(UIKit)
import UIKit
let uiColorSystemBackground = UIColor.systemBackground
let uiColorSecondarySystemBackground = UIColor.secondarySystemBackground
#else
import AppKit
let uiColorSystemBackground = NSColor.windowBackgroundColor
let uiColorSecondarySystemBackground = NSColor.controlBackgroundColor
#endif
