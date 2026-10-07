import SwiftUI

struct ChatSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @FocusState private var composerFocused: Bool

    private let prompts = [
        "What is this briefing about?",
        "What should we watch next?",
        "Compare with last month",
    ]

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spaceLG) {
                    if model.lines.isEmpty {
                        Text("Ask about a briefing, a widget, or the board.")
                            .font(LumenFont.font(16))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.top, Theme.spaceLG)
                        ForEach(Array(prompts.enumerated()), id: \.element) { index, prompt in
                            Button {
                                send(prompt)
                            } label: {
                                OnceShimmerText(text: prompt, delay: 0.12 + Double(index) * 0.28)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        ForEach(model.lines) { line in
                            lineView(line)
                        }
                    }
                }
                .padding(Theme.spaceXL)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            composer
        }
        .background(Theme.background)
        .font(LumenFont.font(14))
    }

    private var header: some View {
        @Bindable var model = model
        return HStack(alignment: .center, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if model.renamingChat {
                    TextField("Chat name", text: $model.chatTitle)
                        .font(LumenFont.font(17, .medium))
                        .textFieldStyle(.plain)
                        .foregroundStyle(Theme.text)
                        .onSubmit { model.renamingChat = false }
                } else {
                    Text(model.chatTitle)
                        .font(LumenFont.font(17, .medium))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                }
                Button {
                    model.renamingChat.toggle()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rename chat")
            }
            Spacer(minLength: 12)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close chat")
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    @ViewBuilder private func lineView(_ line: ChatLine) -> some View {
        switch line.role {
        case .user:
            Text(line.text)
                .font(LumenFont.font(15))
                .foregroundStyle(Theme.text)
                .padding(Theme.spaceLG)
                .background(Theme.primary.opacity(0.22), in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                .frame(maxWidth: .infinity, alignment: .trailing)
        case .thinking:
            HStack(spacing: 8) {
                if line.text == "Thinking" {
                    ProgressView().controlSize(.small).tint(Theme.primary)
                }
                Text(line.text)
                    .font(LumenFont.font(13))
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .assistant:
            Text(line.text)
                .font(LumenFont.font(15))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: Theme.spaceMD) {
            if let attached = model.attachedBriefing {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                    Text(attached)
                        .lineLimit(1)
                    Button {
                        model.attachedBriefing = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove attached briefing")
                }
                .font(LumenFont.font(12, .medium))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(Theme.primary.opacity(0.2), in: Capsule())
            }
            HStack(spacing: Theme.spaceMD) {
                TextField("Ask about this briefing", text: Bindable(model).draft)
                    .focused($composerFocused)
                    .font(LumenFont.font(15))
                    .foregroundStyle(Theme.text)
                Button {
                    let text = model.draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    model.draft = ""
                    send(text)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(width: 32, height: 32)
                        .background(Theme.primary, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Send")
            }
        }
        .padding(Theme.spaceLG)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusPanel, style: .continuous))
        .padding(.horizontal, Theme.spaceLG)
        .padding(.bottom, Theme.spaceMD)
    }

    private struct OnceShimmerText: View {
        var text: String
        var delay: Double
        @State private var band: CGFloat = -0.4

        var body: some View {
            Text(text)
                .font(LumenFont.font(16, .medium))
                .foregroundStyle(Theme.text.opacity(0.82))
                .overlay {
                    GeometryReader { geo in
                        let width = geo.size.width
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * 0.42)
                        .offset(x: band)
                    }
                    .mask(
                        Text(text)
                            .font(LumenFont.font(16, .medium))
                    )
                }
                .onAppear {
                    band = -160
                    withAnimation(.easeInOut(duration: 0.9).delay(delay)) {
                        band = 420
                    }
                }
        }
    }

    private func send(_ text: String) {
        model.lines.append(ChatLine(role: .user, text: text))
        model.lines.append(ChatLine(role: .thinking, text: "Thinking"))
        let thinkingID = model.lines.last?.id
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            model.lines.removeAll { $0.id == thinkingID }
            model.lines.append(ChatLine(role: .assistant, text: "This briefing flags a local late-night slowdown on route X23. It is one incident in the sample, not the current speed on that route."))
        }
    }
}
