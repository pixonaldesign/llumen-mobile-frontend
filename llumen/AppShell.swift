import SwiftUI

struct AppShell: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        LlumenBackground {
            ZStack(alignment: .top) {
                ZStack(alignment: .bottom) {
                    Group {
                        switch model.tab {
                            case .briefings: BriefingsScreen()
                            case .board: BoardScreen()
                            case .profile: ProfileScreen()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    FindingAuroraOverlay(mode: model.findingMode)
                        .animation(Theme.motion, value: model.findingMode)

                    LlumenTabBar()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                // Above the aurora canvas so the glass pill matches in toast and alert.
                if model.tab == .briefings, model.briefingMode == .latest {
                    BriefingModeSwitcher()
                        .padding(.top, 8)
                }
            }
        }
        .fullScreenCover(item: $model.story) { route in
            StoryPlayer(route: route)
        }
        .fullScreenCover(item: $model.focus) { focus in
            FocusScreen(focus: focus)
        }
        .sheet(isPresented: $model.showChat) {
            ChatSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.background)
        }
    }
}

struct LlumenTabBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        withAnimation(Theme.motion) { model.tab = tab }
                    } label: {
                        Image(systemName: model.tab == tab ? tab.symbolSelected : tab.symbol)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(model.tab == tab ? Theme.primary : Theme.textTertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(model.tab == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal, 22)
            .frame(height: 58)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular, in: Capsule())

            LlumenAskButton(cue: model.findingMode) {
                withAnimation(Theme.motion) {
                    switch model.findingMode {
                    case .off: model.findingMode = .chip
                    case .chip: model.findingMode = .alert
                    case .alert: model.findingMode = .off
                    }
                }
            }
        }
    }
}
