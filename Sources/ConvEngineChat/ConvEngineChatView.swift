import SwiftUI

/// The main chat surface — the SwiftUI twin of `<ConvEngineChat mode="fullscreen">`.
///
/// ```swift
/// struct MyEngine: CEChatEngine {
///     func reply(to text: String, history: [CEMessage]) async throws -> CEReply {
///         CEReply(text: try await myLLM.complete(text))
///     }
/// }
///
/// var config = CEConfig()
/// config.title = "Ask KreditKard"
/// config.chips = [CEChip("How much do I owe?")]
///
/// ConvEngineChatView(engine: MyEngine(), config: config)
/// ```
///
/// Fills its container; present it in a sheet, a NavigationStack, or full screen —
/// the iOS equivalents of the JS library's panel/sidepanel/fullscreen modes.
public struct ConvEngineChatView: View {
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

    /// Access the view model from outside (e.g. to inject a message programmatically).
    public func viewModelReference() -> CEChatViewModel { viewModel }
}
