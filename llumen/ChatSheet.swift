import AVFoundation
import Speech
import SwiftUI
import UIKit

struct ChatSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @FocusState private var composerFocused: Bool
    @State private var pane: Pane = .thread
    @State private var chatQuery = ""
    @State private var dictating = false
    @State private var dictation = ChatDictation()
    @State private var attachments: [ComposerAttachment] = []

    private enum Pane { case thread, list }

    /// The placeholder sits inside the composer’s outer and inner padding.
    private var composerTextInset: CGFloat { Theme.spaceLG + Theme.spaceLG }

    private let prompts = [
        "What is this briefing about?",
        "What should we watch next?",
        "Compare with last month",
    ]

    private var visibleChats: [Conversation] {
        let query = chatQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return model.conversations }
        return model.conversations.filter { $0.title.localizedStandardContains(query) }
    }

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            if pane == .list {
                conversationList
            } else {
                header
                Group {
                    if model.lines.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: Theme.space3XL) {
                                ForEach(model.lines) { line in
                                    ChatLineRow(line: line)
                                        .equatable()
                                }
                            }
                            .padding(.horizontal, Theme.spaceXL)
                            .padding(.vertical, Theme.space2XL)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                if model.lines.isEmpty, model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    suggestedPrompts
                }
                composer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background {
            ZStack {
                Theme.background
                ThinkingMesh(active: model.isReplying)
            }
            .ignoresSafeArea()
        }
        .font(LumenFont.font(14))
    }

    private var header: some View {
        @Bindable var model = model
        return HStack(alignment: .center, spacing: 8) {
            Button {
                pane = .list
            } label: {
                PhosphorIcon(.list, size: 18)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Conversations")
            if model.renamingChat {
                TextField("Chat name", text: $model.chatTitle)
                    .font(LumenFont.font(17, .medium))
                    .textFieldStyle(.plain)
                    .foregroundStyle(Theme.text)
                    .onSubmit { model.commitTitle() }
            } else {
                Text(model.chatTitle)
                    .font(LumenFont.font(17, .medium))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
            }
            Button {
                if model.renamingChat {
                    model.commitTitle()
                } else {
                    model.renamingChat = true
                }
            } label: {
                PhosphorIcon(.pencilSimple, size: 15)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rename chat")
            Spacer(minLength: 8)
            closeButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 36)
        .padding(.bottom, 8)
    }

    private var conversationList: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    pane = .thread
                } label: {
                    PhosphorIcon(.caretLeft, size: 16)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to chat")
                Text("Chats")
                    .font(LumenFont.font(17, .medium))
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                closeButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 36)
            .padding(.bottom, 8)

            if model.conversations.isEmpty && chatQuery.isEmpty {
                Text("Conversations you start show up here.")
                    .font(LumenFont.font(16))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(Theme.spaceXL)
            } else {
                List {
                    ForEach(visibleChats) { chat in
                        Button {
                            model.openChat(chat.id)
                            pane = .thread
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(chat.title)
                                    .font(LumenFont.font(16, .medium))
                                    .foregroundStyle(Theme.text)
                                    .lineLimit(1)
                                Text(age(chat.updatedAt))
                                    .font(LumenFont.font(13))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                model.deleteChat(chat.id)
                            } label: {
                                Text("Delete")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            HStack {
                Spacer(minLength: 0)
                Button {
                    model.beginChat()
                    pane = .thread
                } label: {
                    HStack(spacing: 6) {
                        PhosphorIcon(.plus, size: 14)
                        Text("New chat")
                            .font(LumenFont.font(15, .medium))
                    }
                    .foregroundStyle(Color.black.opacity(0.9))
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .blueGlass()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New chat")
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            HStack(spacing: 8) {
                PhosphorIcon(.magnifyingGlass, size: 16)
                    .foregroundStyle(Theme.textTertiary)
                TextField("Search", text: $chatQuery)
                    .font(LumenFont.font(16))
                    .foregroundStyle(Theme.text)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .glassEffect(.regular, in: Capsule())
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, Theme.spaceMD)
        }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            PhosphorIcon(.x, size: 13)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 32, height: 32)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close chat")
    }

    private static let ageFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private func age(_ date: Date) -> String {
        Self.ageFormatter.localizedString(for: date, relativeTo: .now)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            LlumenOrb()
                .frame(width: 36, height: 36)
            Text("What should we look at?")
                .font(LumenFont.font(22, .medium))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.space4XL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var suggestedPrompts: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(prompts.enumerated()), id: \.element) { index, prompt in
                Button {
                    model.draft = prompt
                    composerFocused = true
                } label: {
                    SuggestedPrompt(text: prompt, index: index)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, composerTextInset)
        .padding(.bottom, Theme.spaceSM)
    }

    private var composer: some View {
        @Bindable var model = model
        let trimmed = model.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(alignment: .leading, spacing: Theme.spaceMD) {
            if model.attachedBriefing != nil || !attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let attached = model.attachedBriefing {
                            attachmentChip(name: attached, badge: "Briefing") {
                                model.attachedBriefing = nil
                            }
                        }
                        ForEach(attachments) { item in
                            attachmentChip(name: item.name, badge: item.badge) {
                                attachments.removeAll { $0.id == item.id }
                            }
                        }
                    }
                }
            }
            TextField(model.lines.isEmpty ? "Ask Llumen" : "Reply to Llumen", text: $model.draft, axis: .vertical)
                .focused($composerFocused)
                .font(LumenFont.font(16))
                .foregroundStyle(Theme.text)
                .lineLimit(1...5)
            HStack(spacing: 8) {
                addMenu
                Spacer(minLength: 0)
                micButton
                sendButton(trimmed: trimmed)
            }
        }
        .padding(Theme.spaceLG)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, Theme.spaceLG)
        .padding(.bottom, Theme.spaceMD)
    }

    private var addMenu: some View {
        Menu {
            Section("Context") {
                ForEach(ComposerCatalog.groups) { group in
                    Menu {
                        ForEach(group.items) { item in
                            Button(item.name) {
                                attach(name: item.name, badge: group.title)
                            }
                        }
                    } label: {
                        PhosphorMenuLabel(title: group.title, icon: group.icon)
                    }
                }
            }
            Section("Files") {
                ForEach(ComposerCatalog.files) { file in
                    Button {
                        attach(name: file.name, badge: file.badge)
                    } label: {
                        PhosphorMenuLabel(title: "\(file.badge) · \(file.name)", icon: .paperclip)
                    }
                }
            }
        } label: {
            PhosphorIcon(.plus, size: 16)
                .foregroundStyle(Theme.text)
                .frame(width: 32, height: 32)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .menuOrder(.fixed)
        .buttonStyle(.plain)
        .accessibilityLabel("Add context or file")
    }

    private var micButton: some View {
        Button {
            dictation.toggle(
                draft: model.draft,
                update: { model.draft = $0 },
                setListening: { dictating = $0 }
            )
        } label: {
            PhosphorIcon(.microphone, size: 16)
                .foregroundStyle(dictating ? Color.black.opacity(0.9) : Theme.text)
                .frame(width: 32, height: 32)
                .glassEffect(
                    dictating ? .regular.tint(Theme.primary).interactive() : .regular.interactive(),
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dictating ? "Stop dictation" : "Dictate")
    }

    private func sendButton(trimmed: String) -> some View {
        Button {
            guard !trimmed.isEmpty else { return }
            dictation.stop { dictating = $0 }
            model.draft = ""
            send(trimmed)
        } label: {
            PhosphorIcon(.arrowUp, size: 15)
                .foregroundStyle(Color.black.opacity(0.9))
                .frame(width: 32, height: 32)
                .blueGlassCircle()
                .opacity(trimmed.isEmpty ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(trimmed.isEmpty)
        .accessibilityLabel("Send")
    }

    private func attachmentChip(name: String, badge: String, remove: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(badge)
                    .font(LumenFont.font(10, .medium))
                    .foregroundStyle(Theme.textTertiary)
                Text(name)
                    .font(LumenFont.font(13, .medium))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
            }
            Button(action: remove) {
                PhosphorIcon(.x, size: 11)
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(name)")
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .frame(height: 44)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func attach(name: String, badge: String) {
        guard !attachments.contains(where: { $0.name == name && $0.badge == badge }) else { return }
        attachments.append(ComposerAttachment(name: name, badge: badge))
    }

    private func send(_ text: String) {
        let pending = model.beginReply(to: text)
        model.streamReply(
            chatID: pending.chatID,
            thinkingID: pending.thinkingID,
            text: """
                Coastal air quality is at 42 AQI, which is in the good range for the stations along this corridor. The year climbed through late spring, peaked near 61 in June, and has eased back through the autumn.

                Three districts still brush the sensitive-group line on still nights, mostly where the sea breeze drops after midnight. The overnight rise of about 18% is local, not a citywide deterioration, and it fades once the morning wind returns.

                I would keep those coastal stations on the monitor, compare them with last week’s night hours, and only escalate if a district stays above the threshold into the next morning.
                """
        )
    }
}

private struct ChatLineRow: View, Equatable {
    let line: ChatLine

    var body: some View {
        switch line.role {
        case .user:
            Text(line.text)
                .font(LumenFont.font(16))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: 280, alignment: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        case .thinking:
            HStack(spacing: 8) {
                if line.text == "Thinking" {
                    ProgressView().controlSize(.small).tint(Theme.textTertiary)
                }
                Text(line.text)
                    .font(LumenFont.font(15))
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .assistant:
            VStack(alignment: .leading, spacing: 10) {
                Text(spokenText)
                    .font(LumenFont.font(16))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(line.text)
                Button {
                    UIPasteboard.general.string = line.text
                } label: {
                    PhosphorIcon(.copy, size: 16)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Copy reply")
                .opacity(line.revealed == nil ? 1 : 0)
                .allowsHitTesting(line.revealed == nil)
            }
        }
    }

    /// Unrevealed words stay laid out but clear, so lines never reflow. The newest three words are still fading in.
    private var spokenText: AttributedString {
        guard let revealed = line.revealed else { return AttributedString(line.text) }
        let words = line.text.split(separator: " ", omittingEmptySubsequences: false)
        let count = words.count
        let fadeStart = min(max(revealed - 3, 0), count)
        let hiddenStart = min(max(revealed, 0), count)
        var result = AttributedString()
        func append(_ range: Range<Int>, alpha: Double) {
            guard !range.isEmpty else { return }
            var text = words[range].joined(separator: " ")
            if range.upperBound < count { text += " " }
            var piece = AttributedString(text)
            piece.foregroundColor = Theme.text.opacity(alpha)
            result += piece
        }
        append(0..<fadeStart, alpha: 1)
        for index in fadeStart..<hiddenStart {
            let alpha: Double = switch revealed - index {
            case 1: 0.25
            case 2: 0.55
            default: 0.8
            }
            append(index..<index + 1, alpha: alpha)
        }
        append(hiddenStart..<count, alpha: 0)
        return result
    }
}

private struct ComposerAttachment: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var badge: String
}

private struct ComposerChoice: Identifiable {
    var id: String
    var name: String
}

private struct ComposerGroup: Identifiable {
    var id: String
    var title: String
    var icon: Phosphor
    var items: [ComposerChoice]
}

private struct ComposerFile: Identifiable {
    var badge: String
    var name: String
    var id: String { badge }
}

/// Context categories and sample files from the Lumen assistant composer.
private enum ComposerCatalog {
    static let groups: [ComposerGroup] = [
        .init(id: "database", title: "Database", icon: .database, items: [
            .init(id: "db-aq-stations", name: "Air Quality Stations"),
            .init(id: "db-population", name: "Population Census"),
            .init(id: "db-land-use", name: "Land-use Inventory"),
            .init(id: "db-traffic", name: "Traffic Sensors Network"),
            .init(id: "db-emissions", name: "Industrial Emissions Registry"),
        ]),
        .init(id: "slides", title: "Slides", icon: .presentation, items: [
            .init(id: "sl-q1-exec", name: "Q1 Executive Deck"),
            .init(id: "sl-aqi-corridor", name: "AQI Corridor Review"),
            .init(id: "sl-marina-ops", name: "Marina Ops Briefing Slides"),
            .init(id: "sl-exposure", name: "Exposure Priority Pack"),
            .init(id: "sl-stakeholder", name: "Weekly Stakeholder Sync"),
        ]),
        .init(id: "briefings", title: "Briefings", icon: .clipboardText, items: [
            .init(id: "br-q1-kpi", name: "Q1 KPI briefing"),
            .init(id: "br-exec-aqi", name: "Executive AQI assessment"),
            .init(id: "br-exposure-memo", name: "Exposure priority memo"),
            .init(id: "br-port-dwell", name: "Port dwell-time digest"),
            .init(id: "br-incident", name: "Incident response summary"),
        ]),
        .init(id: "assets", title: "Assets", icon: .images, items: [
            .init(id: "as-aqi-map", name: "Abu Dhabi AQI map"),
            .init(id: "as-traffic-index", name: "Store traffic index"),
            .init(id: "as-heat-chart", name: "High heat districts chart"),
            .init(id: "as-station-csv", name: "Station export CSV"),
            .init(id: "as-corridor-photos", name: "Corridor photo set"),
        ]),
    ]

    static let files: [ComposerFile] = [
        .init(badge: "DLL", name: "appverifUI.dll"),
        .init(badge: "PNG", name: "abu-dhabi-aqi.png"),
        .init(badge: "CSV", name: "station-export.csv"),
        .init(badge: "PDF", name: "ops-notes.pdf"),
    ]
}

@MainActor
final class ChatDictation {
    private let recognizer = SFSpeechRecognizer()
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var base = ""
    private var tapped = false
    private var listening = false

    func toggle(draft: String, update: @escaping (String) -> Void, setListening: @escaping (Bool) -> Void) {
        if listening {
            stop(setListening: setListening)
        } else {
            begin(from: draft, update: update, setListening: setListening)
        }
    }

    func stop(setListening: @escaping (Bool) -> Void) {
        guard listening || tapped || engine.isRunning else {
            setListening(false)
            return
        }
        if tapped {
            engine.inputNode.removeTap(onBus: 0)
            tapped = false
        }
        engine.stop()
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        listening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        setListening(false)
    }

    private func begin(from draft: String, update: @escaping (String) -> Void, setListening: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                guard status == .authorized else { return }
                AVAudioApplication.requestRecordPermission { granted in
                    Task { @MainActor in
                        guard granted else { return }
                        self.startEngine(from: draft, update: update, setListening: setListening)
                    }
                }
            }
        }
    }

    private func startEngine(from draft: String, update: @escaping (String) -> Void, setListening: @escaping (Bool) -> Void) {
        stop(setListening: { _ in })
        base = draft
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
                request?.append(buffer)
            }
            tapped = true
            engine.prepare()
            try engine.start()
        } catch {
            stop(setListening: setListening)
            return
        }
        listening = true
        setListening(true)
        let prefix = base
        task = recognizer?.recognitionTask(with: request) { result, error in
            if let spoken = result?.bestTranscription.formattedString {
                let gap = prefix.isEmpty || prefix.hasSuffix(" ") ? "" : " "
                let next = prefix + gap + spoken
                Task { @MainActor in update(next) }
            }
            if error != nil {
                Task { @MainActor in
                    self.stop(setListening: setListening)
                }
            }
        }
    }
}

/// Each prompt rises in on its own beat, then a light band crosses the words.
private struct SuggestedPrompt: View {
    var text: String
    var index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var band: CGFloat = -0.8

    var body: some View {
        Text(text)
            .font(LumenFont.font(16, .medium))
            .foregroundStyle(Theme.text.opacity(0.86))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.95), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.38)
                    .offset(x: band * geo.size.width)
                }
                .mask(
                    Text(text)
                        .font(LumenFont.font(16, .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                )
                .allowsHitTesting(false)
            }
            .opacity(reduceMotion || shown ? 1 : 0)
            .offset(y: reduceMotion || shown ? 0 : 16)
            .onAppear {
                guard !reduceMotion else { return }
                let reveal = 0.12 + Double(index) * 0.16
                withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.46).delay(reveal)) {
                    shown = true
                }
            }
            .task {
                guard !reduceMotion else { return }
                let reveal = 0.12 + Double(index) * 0.16
                try? await Task.sleep(for: .seconds(reveal + 0.5))
                guard !Task.isCancelled else { return }
                for pass in 0..<2 {
                    if pass > 0 {
                        band = -0.8
                        try? await Task.sleep(for: .milliseconds(90))
                    }
                    withAnimation(.easeInOut(duration: 0.95)) {
                        band = 1.45
                    }
                    try? await Task.sleep(for: .milliseconds(1100))
                }
            }
    }
}
