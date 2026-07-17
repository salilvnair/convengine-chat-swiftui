import SwiftUI

/// The main chat surface — the SwiftUI twin of `<ConvEngineChat mode="fullscreen">`.
///
/// Two ways to use it:
///
/// **Simple (library owns the state):**
/// ```swift
/// ConvEngineChatView(engine: MyEngine(), config: config)
/// ```
///
/// **Host-owned state** (when you need to read/write the chat from outside — e.g. a mic
/// button that types into the composer). Own the view model as a `@StateObject` and pass it in:
/// ```swift
/// @StateObject private var chat = CEChatViewModel(engine: MyEngine(), config: config)
/// // …
/// ConvEngineChatView(viewModel: chat, config: config)
/// // elsewhere: chat.input = transcript   // mic writes here
/// ```
///
/// Fills its container; present it in a sheet, a NavigationStack, or full screen —
/// the iOS equivalents of the JS library's panel/sidepanel/fullscreen modes.
public struct ConvEngineChatView: View {
    @ObservedObject private var viewModel: CEChatViewModel
    private let config: CEConfig
    private let theme: CETheme

    /// Host-owned initializer. The caller creates + owns the `CEChatViewModel`
    /// (typically as a `@StateObject`), so it can read/write the chat from outside.
    public init(viewModel: CEChatViewModel,
                config: CEConfig = CEConfig(),
                theme: CETheme = .default) {
        self.viewModel = viewModel
        self.config = config
        self.theme = theme
    }

    public var body: some View {
        VStack(spacing: 0) {
            if config.showHeader {
                CEHeader(viewModel: viewModel, config: config, theme: theme)
            }

            if viewModel.isEmpty {
                CELanding(viewModel: viewModel, config: config, theme: theme)
                    .transition(.opacity)
            } else {
                CEThread(viewModel: viewModel, config: config, theme: theme)
                CEComposer(viewModel: viewModel, config: config, theme: theme)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .background(theme.panelBg.ignoresSafeArea())
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.isEmpty)
    }
}

/// Convenience wrapper that creates + owns the `CEChatViewModel` internally.
/// Use this when you don't need outside access to the chat state.
public struct ConvEngineChat: View {
    @StateObject private var viewModel: CEChatViewModel
    private let config: CEConfig
    private let theme: CETheme

    public init(engine: CEChatEngine,
                config: CEConfig = CEConfig(),
                theme: CETheme = .default) {
        _viewModel = StateObject(wrappedValue: CEChatViewModel(engine: engine, config: config))
        self.config = config
        self.theme = theme
    }

    public var body: some View {
        ConvEngineChatView(viewModel: viewModel, config: config, theme: theme)
    }
}
