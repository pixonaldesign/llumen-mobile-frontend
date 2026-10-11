import SwiftUI

enum BriefingMode: String, CaseIterable, Identifiable {
    case latest, all
    var id: String { rawValue }
    var title: String {
        switch self {
        case .latest: "Latest"
        case .all: "All"
        }
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case briefings, board, profile
    var id: String { rawValue }
    var title: String {
        switch self {
        case .briefings: "Briefings"
        case .board: "Board"
        case .profile: "Profile"
        }
    }
    var symbol: String {
        switch self {
        case .briefings: "doc.text"
        case .board: "square.grid.2x2"
        case .profile: "person"
        }
    }
    var symbolSelected: String {
        switch self {
        case .briefings: "doc.text.fill"
        case .board: "square.grid.2x2.fill"
        case .profile: "person.fill"
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
    enum Role { case user, assistant, thinking }
}

@Observable
final class AppModel {
    var signedIn = true
    var tab: AppTab = .briefings
    var briefingMode: BriefingMode = .latest
    var feedStart = 0
    var story: StoryRoute?
    var focus: BoardFocus?
    var showChat = false
    var showFilters = false
    var showPicker = false
    var showPasswordHelp = false
    var editingBoard = false
    var statusIsExpired = false
    var workspaceFilter = "All"
    var chatTitle = "New chat"
    var renamingChat = false
    var draft = ""
    var attachedBriefing: String?
    var lines: [ChatLine] = []
    var findingMode: FindingAuroraMode = .off
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
        case "latest":
            tab = .briefings
            briefingMode = .latest
        case "feedchart":
            tab = .briefings
            briefingMode = .latest
            feedStart = 2
        case "all":
            tab = .briefings
            briefingMode = .all
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
    }
}
