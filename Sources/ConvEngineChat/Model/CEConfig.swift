import SwiftUI

/// Configuration bag — the SwiftUI twin of the JS library's `config` prop.
/// Everything has a sensible default; override only what you need.
public struct CEConfig {

    public enum ComposerShape { case round, rect }

    // ── Text & labels ────────────────────────────────────────────────
    public var title: String = "ConvEngine Assistant"
    public var subtitle: String = "Ask me anything — I'll do my best to help."
    public var placeholder: String = "Ask anything…"

    // ── Visibility flags ─────────────────────────────────────────────
    public var showHeader: Bool = true
    public var showHeaderDot: Bool = true
    public var showNewChat: Bool = true
    public var showFeedback: Bool = true
    public var showLandingAvatar: Bool = true
    public var showLandingSubtitle: Bool = true

    // ── Appearance ───────────────────────────────────────────────────
    public var composerShape: ComposerShape = .round
    /// SF Symbol for the landing hero + assistant avatar.
    public var avatarSystemImage: String = "sparkles"

    // ── Landing chips ────────────────────────────────────────────────
    public var chips: [CEChip] = []

    // ── Composer accessory (e.g. a mic button) ───────────────────────
    public var composerLeadingAccessory: AnyView? = nil

    // ── Lifecycle callbacks (JS: onMessage / onResponse / onFeedback) ─
    public var onMessage: ((String) -> Void)? = nil
    public var onResponse: ((String) -> Void)? = nil
    public var onFeedback: ((CEFeedback) -> Void)? = nil

    // ── Custom renderers (JS: renderers) ─────────────────────────────
    public var renderers: [CERendererProvider] = []

    public init() {}
}
