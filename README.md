# convengine-chat-swiftui

> The SwiftUI twin of [`@salilvnair/convengine-chat`](https://github.com/salilvnair/convengine-chat) —
> a drop-in, beautiful chat surface for any iOS app. Landing hero with glowing avatar,
> suggestion chips, gradient bubbles, streaming cursor, typing dots, feedback row,
> custom renderers, full theming. Zero dependencies.

## Installation

### Swift Package Manager (Xcode)
`File → Add Package Dependencies…` → `https://github.com/salilvnair/convengine-chat-swiftui`

### XcodeGen (project.yml)
```yaml
packages:
  ConvEngineChat:
    url: https://github.com/salilvnair/convengine-chat-swiftui
    from: "1.0.0"
targets:
  MyApp:
    dependencies:
      - package: ConvEngineChat
        product: ConvEngineChat
```

Local development (before publishing):
```yaml
packages:
  ConvEngineChat:
    path: ../../salilvnair/convengine-chat-swiftui
```

## Quick Start

```swift
import ConvEngineChat

// 1. Implement the engine — connect ANY backend.
struct MyEngine: CEChatEngine {
    func reply(to text: String, history: [CEMessage]) async throws -> CEReply {
        CEReply(text: try await myLLM.complete(text))
    }
}

// 2. Configure + present.
struct ChatScreen: View {
    var body: some View {
        var config = CEConfig()
        config.title = "My Assistant"
        config.subtitle = "Ask me anything."
        config.chips = [
            CEChip("What can you do?"),
            CEChip("Summarize my day")
        ]
        return ConvEngineChatView(engine: MyEngine(), config: config)
    }
}
```

## Streaming

Return an `AsyncThrowingStream` and the assistant bubble grows chunk-by-chunk
with a blinking cursor (JS parity: SSE transport):

```swift
struct StreamingEngine: CEChatEngine {
    func reply(to text: String, history: [CEMessage]) async throws -> CEReply {
        CEReply(text: "")   // unused when streamReply is provided
    }
    func streamReply(to text: String, history: [CEMessage]) -> AsyncThrowingStream<String, Error>? {
        AsyncThrowingStream { continuation in
            Task {
                for try await chunk in myLLM.stream(text) { continuation.yield(chunk) }
                continuation.finish()
            }
        }
    }
}
```

## ConvEngine backend (REST parity)

```swift
ConvEngineChatView(
    engine: ConvEngineRestEngine(apiHost: "http://localhost:8080",
                                 inputParams: ["userId": "xxxx"])
)
```

## Theming (JS: `--ce-*` tokens)

```swift
var theme = CETheme()
theme.accent = .pink
theme.accentGradient = [.pink, .orange]
theme.bubbleCornerRadius = 20
theme.messageFont = .body

ConvEngineChatView(engine: engine, config: config, theme: theme)
```

| Token | JS equivalent |
|---|---|
| `accent` / `accentGradient` | `color-accent`, `bubbleUserBg` |
| `bubbleUserText` | `bubbleUserText` |
| `bubbleAgentBg` / `bubbleAgentText` | `bubbleAgentBg` / `bubbleAgentText` |
| `panelBg` | `panelBg` |
| `composerBg` | `composerBg` |
| `messageFont` / `titleFont` | `font-family` |

## Config flags (JS parity)

| Swift | JS |
|---|---|
| `title`, `subtitle`, `placeholder` | same |
| `showHeader`, `showHeaderDot`, `showNewChat` | `showHeaderDot`, `showNewChat` |
| `showFeedback` | `showFeedback` |
| `showLandingAvatar`, `showLandingSubtitle` | same |
| `composerShape: .round/.rect` | `composerShape` |
| `chips: [CEChip]` | landing chips |
| `onMessage`, `onResponse`, `onFeedback` | same |
| `renderers: [CERendererProvider]` | `renderers` |
| `composerLeadingAccessory` | — (iOS extra: inject a mic button etc.) |

## Custom renderers (JS: `renderers`)

```swift
config.renderers = [
    CERenderer(key: "PayCard", priority: 200,
               match: { $0.type == "PayCard" }) { message, actions in
        Button("Pay \(message.meta["amount"] ?? "")") {
            actions.submit("Pay it")
        }
        .buttonStyle(.borderedProminent)
    }
]
```

## Presentation modes

The JS panel/sidepanel/fullscreen map to standard SwiftUI presentation:

```swift
.sheet(isPresented: $show) { ConvEngineChatView(...) }                  // panel
.fullScreenCover(isPresented: $show) { ConvEngineChatView(...) }       // fullscreen
NavigationStack { ConvEngineChatView(...) }                             // pushed
```

## License

MIT © Salil V Nair
