import SwiftUI

enum BriefingMode: String, CaseIterable, Identifiable {
    case all, alerts, updates
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "All"
        case .alerts: "Alerts"
        case .updates: "Updates"
        }
    }
    /// All plays as the full-screen reel. Alerts and Updates are grids.
    var isReel: Bool { self == .all }
}

enum AppTab: String, CaseIterable, Identifiable {
    case briefings, board, profile
    var id: String { rawValue }
    var title: String {
        switch self {
        case .briefings: "Briefings"
        case .board: "Monitor"
        case .profile: "Profile"
        }
    }
    var icon: Phosphor {
        switch self {
        case .briefings: .asterisk
        case .board: .squaresFour
        case .profile: .user
        }
    }
}

struct StoryRoute: Identifiable, Equatable {
    var id: String
    var title: String
}

enum BoardFocus: Identifiable, Equatable {
    case map(String)
    case chart(String)
    var id: String {
        switch self {
        case .map(let id), .chart(let id): id
        }
    }
}

struct ChatLine: Identifiable, Equatable {
    var id = UUID()
    var role: Role
    var text: String
    /// Words of `text` shown so far while the agent is still speaking. Nil once the reply is complete.
    var revealed: Int? = nil
    enum Role { case user, assistant, thinking }

    var isPending: Bool {
        (role == .thinking && text == "Thinking") || revealed != nil
    }
}

struct Conversation: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var lines: [ChatLine] = []
    var attachedBriefing: String?
    var renamed = false
    var updatedAt = Date()
}

@Observable
final class AppModel {
    var signedIn = true
    var tab: AppTab = .briefings
    var briefingMode: BriefingMode = .all
    var feedStart = 0
    var story: StoryRoute?
    var focus: BoardFocus?
    var showChat = false
    var showFilters = false
    var showPicker = false
    var showPasswordHelp = false
    var showWorkspaceSwitch = false
    var editingBoard = false
    var statusIsExpired = false
    var workspaceFilter = "All"
    var chatTitle = "New chat"
    var chatRenamed = false
    var renamingChat = false
    var draft = ""
    var attachedBriefing: String?
    var lines: [ChatLine] = []
    var conversations: [Conversation] = []
    var activeChatID: UUID?
    /// Toast is `.chip`. Aurora is `.alert`. Ask does not change this.
    var findingMode: FindingAuroraMode = .off
    /// What the preview controls last asked for. The rim plays before `findingMode` catches up.
    var findingRequest: FindingAuroraMode = .off
    var rimCue: FindingAuroraMode = .off
    var rimToken = 0
    var findingIndex = 0
    var workspaceAddress = "https://staging.llumen.io"
    var email = "admin@llumen.io"
    var password = ""

    init() {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-LlumenScreen"), args.indices.contains(index + 1) else { return }
        switch args[index + 1] {
        case "story":
            story = StoryRoute(id: "speeds", title: "Average speeds at 11 km/h")
        case "latest", "all":
            tab = .briefings
            briefingMode = .all
        case "feedchart":
            tab = .briefings
            briefingMode = .all
            feedStart = 2
        case "alerts":
            tab = .briefings
            briefingMode = .alerts
        case "updates":
            tab = .briefings
            briefingMode = .updates
        case "board":
            tab = .board
        case "edit":
            tab = .board
            editingBoard = true
        case "map":
            tab = .board
            focus = .map("coast")
        case "chart":
            tab = .board
            focus = .chart("housing")
        case "chip":
            tab = .briefings
            findingMode = .chip
        case "alert":
            tab = .briefings
            findingMode = .alert
        case "ask":
            showChat = true
            chatTitle = "Coastal Heat Stress Advisory"
            attachedBriefing = "Coastal Heat Stress Advisory"
        case "chat":
            showChat = true
            attachedBriefing = "Average speeds at 11 km/h"
            chatTitle = "Explain attached briefing"
            lines = [
                ChatLine(role: .user, text: "Explain what this briefing is about"),
                ChatLine(role: .thinking, text: "Thought for 9 seconds"),
                ChatLine(role: .assistant, text: "This briefing flags a local late-night slowdown on route X23. It is one incident in 2018–2019, not the current speed on that route."),
            ]
        case "profile":
            tab = .profile
        case "signin":
            signedIn = false
        default:
            break
        }
        findingRequest = findingMode
        captureLaunchChat()
    }

    func dismissFinding() {
        rimToken += 1
        rimCue = .off
        findingRequest = .off
        withAnimation(Theme.motion) { findingMode = .off }
    }

    /// Blue rim, then the toast. Red rim, then the aurora. Off clears either one.
    func presentFinding(_ mode: FindingAuroraMode) {
        guard mode != .off else {
            dismissFinding()
            return
        }
        findingRequest = mode
        rimCue = mode
        rimToken += 1
        let token = rimToken
        withAnimation(Theme.motion) { findingMode = .off }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(750))
            guard rimToken == token else { return }
            withAnimation(Theme.motion) { findingMode = mode }
        }
    }

    func openAgent() {
        if activeChatID == nil {
            beginChat()
        }
        showChat = true
    }

    var isReplying: Bool { lines.contains(where: \.isPending) }

    /// Tell me more asks on the user's behalf, so the sheet opens with the agent already answering.
    func askAbout(briefing title: String, finding: String? = nil) {
        beginChat(attached: title)
        let pending = beginReply(to: "Tell me more about this briefing")
        chatTitle = title
        syncActiveChat()
        showChat = true
        streamReply(
            chatID: pending.chatID,
            thinkingID: pending.thinkingID,
            text: briefingReply(title: title, finding: finding)
        )
    }

    private func briefingReply(title: String, finding: String?) -> String {
        let lead = finding.map { $0.hasSuffix(".") ? $0 : "\($0)." }
            ?? "\(title) is the latest reading from the stations behind this briefing."
        return """
        \(lead)

        The movement is local to the areas named in the briefing rather than a network-wide shift, and it follows the pattern of the past few weeks instead of starting a new one.

        I would keep it on the monitor, compare it with the same hours last week, and only escalate if it holds into the next reporting window. I can break it down by district, pull up the underlying chart, or draft a note for your team.
        """
    }

    func beginChat(attached: String? = nil) {
        if let id = activeChatID,
           let current = conversations.first(where: { $0.id == id }),
           current.lines.isEmpty, !current.renamed, current.title == "New chat" {
            attachedBriefing = attached
            chatTitle = "New chat"
            lines = []
            chatRenamed = false
            renamingChat = false
            draft = ""
            syncActiveChat()
            return
        }
        syncActiveChat()
        let chat = Conversation(title: "New chat", attachedBriefing: attached)
        conversations.insert(chat, at: 0)
        apply(chat)
    }

    func openChat(_ id: UUID) {
        guard let chat = conversations.first(where: { $0.id == id }) else { return }
        syncActiveChat()
        apply(chat)
    }

    func deleteChat(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        guard activeChatID == id else { return }
        if let next = conversations.first {
            apply(next)
        } else {
            activeChatID = nil
            chatTitle = "New chat"
            lines = []
            attachedBriefing = nil
            chatRenamed = false
            renamingChat = false
            draft = ""
        }
    }

    func commitTitle() {
        let trimmed = chatTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        chatTitle = trimmed.isEmpty ? "New chat" : trimmed
        chatRenamed = true
        renamingChat = false
        if activeChatID == nil {
            let chat = Conversation(title: chatTitle, lines: lines, attachedBriefing: attachedBriefing, renamed: true)
            conversations.insert(chat, at: 0)
            activeChatID = chat.id
        } else {
            syncActiveChat()
        }
    }

    func beginReply(to text: String) -> (chatID: UUID, thinkingID: UUID) {
        if activeChatID == nil {
            beginChat(attached: attachedBriefing)
        }
        let firstQuery = !lines.contains { $0.role == .user }
        if firstQuery && !chatRenamed {
            chatTitle = topicTitle(from: text)
        }
        lines.append(ChatLine(role: .user, text: text))
        let thinking = ChatLine(role: .thinking, text: "Thinking")
        lines.append(thinking)
        noteActivity()
        return (activeChatID!, thinking.id)
    }

    /// Thinks for a beat, then reveals the reply word by word, pausing on punctuation and paragraph breaks.
    func streamReply(chatID: UUID, thinkingID: UUID, text: String) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            let words = text.split(separator: " ", omittingEmptySubsequences: false)
            let reply = ChatLine(role: .assistant, text: text, revealed: 0)
            editLines(in: chatID) { lines in
                lines.removeAll { $0.id == thinkingID }
                lines.append(reply)
            }
            for (index, word) in words.enumerated() {
                editLines(in: chatID, sync: false) { lines in
                    guard let line = lines.firstIndex(where: { $0.id == reply.id }) else { return }
                    lines[line].revealed = index + 1
                }
                let pause: Int
                if word.contains("\n") {
                    pause = 260
                } else if word.hasSuffix(".") || word.hasSuffix(",") {
                    pause = 120
                } else {
                    pause = 42
                }
                try? await Task.sleep(for: .milliseconds(pause))
            }
            editLines(in: chatID) { lines in
                guard let line = lines.firstIndex(where: { $0.id == reply.id }) else { return }
                lines[line].revealed = nil
            }
            if activeChatID == chatID { noteActivity() }
        }
    }

    /// Word-by-word reveals skip `sync`; the active chat is copied into `conversations` when the reply settles or the chat is switched.
    private func editLines(in chatID: UUID, sync: Bool = true, _ edit: (inout [ChatLine]) -> Void) {
        if activeChatID == chatID {
            edit(&lines)
            if sync { syncActiveChat() }
        } else if let index = conversations.firstIndex(where: { $0.id == chatID }) {
            edit(&conversations[index].lines)
        }
    }

    func topicTitle(from query: String) -> String {
        let collapsed = query.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let limit = 48
        let clipped: String
        if collapsed.count <= limit {
            clipped = collapsed
        } else {
            let head = collapsed.prefix(limit)
            if let space = head.lastIndex(of: " "), head.distance(from: head.startIndex, to: space) > 16 {
                clipped = String(head[..<space])
            } else {
                clipped = String(head).trimmingCharacters(in: .whitespaces)
            }
        }
        guard let first = clipped.first else { return "New chat" }
        return first.uppercased() + clipped.dropFirst()
    }

    private func apply(_ chat: Conversation) {
        activeChatID = chat.id
        chatTitle = chat.title
        lines = chat.lines
        attachedBriefing = chat.attachedBriefing
        chatRenamed = chat.renamed
        renamingChat = false
        draft = ""
    }

    private func syncActiveChat() {
        guard let id = activeChatID, let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].title = chatTitle
        conversations[index].lines = lines
        conversations[index].attachedBriefing = attachedBriefing
        conversations[index].renamed = chatRenamed
        conversations[index].updatedAt = .now
    }

    private func noteActivity() {
        syncActiveChat()
        guard let id = activeChatID, let index = conversations.firstIndex(where: { $0.id == id }), index != 0 else { return }
        let chat = conversations.remove(at: index)
        conversations.insert(chat, at: 0)
    }

    private func captureLaunchChat() {
        let hasChat = showChat || !lines.isEmpty || attachedBriefing != nil || chatTitle != "New chat"
        guard hasChat else { return }
        let chat = Conversation(
            title: chatTitle,
            lines: lines,
            attachedBriefing: attachedBriefing,
            renamed: chatTitle != "New chat"
        )
        conversations = [chat]
        activeChatID = chat.id
        chatRenamed = chat.renamed
    }
}
