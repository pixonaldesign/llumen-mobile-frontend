import SwiftUI
import UIKit

/// Shared link between the visible list and the floating tab bar.
final class BottomEdgeScroll {
    weak var scrollView: UIScrollView? {
        didSet {
            guard scrollView !== oldValue else { return }
            observers.forEach { $0(scrollView) }
        }
    }

    private var observers: [(UIScrollView?) -> Void] = []

    func observe(_ body: @escaping (UIScrollView?) -> Void) {
        observers.append(body)
        body(scrollView)
    }
}

private struct BottomEdgeScrollKey: EnvironmentKey {
    static let defaultValue = BottomEdgeScroll()
}

extension EnvironmentValues {
    var bottomEdgeScroll: BottomEdgeScroll {
        get { self[BottomEdgeScrollKey.self] }
        set { self[BottomEdgeScrollKey.self] = newValue }
    }
}

struct AppShell: View {
    @Environment(AppModel.self) private var model
    @State private var edgeScroll = BottomEdgeScroll()

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

                    ProgressiveBlur(maxRadius: 14)
                        .frame(height: 110)
                        .ignoresSafeArea(edges: .bottom)
                        .allowsHitTesting(false)

                    if model.tab != .board || !model.editingBoard {
                        LlumenTabBar()
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            .background { BottomEdgeInteraction(bridge: edgeScroll) }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Button { model.showPicker = true } label: {
                            Text("Add asset")
                                .font(LumenFont.font(15, .medium))
                                .foregroundStyle(Color.black.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .blueGlass()
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Theme.spaceXL)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(Theme.motion, value: model.editingBoard)

                // Above the aurora canvas so the glass pill matches in toast and alert.
                if model.tab == .briefings, model.briefingMode.isReel {
                    BriefingModeSwitcher(onMedia: true)
                        .padding(.top, 8)
                }
            }
        }
        .environment(\.bottomEdgeScroll, edgeScroll)
        .fullScreenCover(item: $model.story) { route in
            StoryPlayer(route: route)
        }
        .fullScreenCover(item: $model.focus) { focus in
            FocusScreen(focus: focus)
        }
        .sheet(isPresented: $model.showChat) {
            ChatSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.background)
                .presentationCornerRadius(28)
        }
    }
}

struct LlumenTabBar: View {
    @Environment(AppModel.self) private var model
    @Namespace private var tabHighlight

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                    let selected = model.tab == tab
                    Button {
                        withAnimation(Theme.motion) { model.tab = tab }
                    } label: {
                        PhosphorIcon(tab.icon, size: 24)
                            .foregroundStyle(selected ? Color.black.opacity(0.88) : Theme.chromeIdle)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background {
                                if selected {
                                    Capsule()
                                        .fill(Theme.primary)
                                        .matchedGeometryEffect(id: "tab", in: tabHighlight)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(5)
            .frame(height: 58)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular, in: Capsule())

            LlumenAskButton(cue: model.rimCue, token: model.rimToken) {
                model.openAgent()
            }
        }
    }
}

extension View {
    /// Opts this scroll view into the soft bottom edge blur and registers it with the tab bar.
    func floatingTabScrollEdge(active: Bool = true) -> some View {
        modifier(FloatingTabScrollEdge(active: active))
    }
}

private struct FloatingTabScrollEdge: ViewModifier {
    var active: Bool

    func body(content: Content) -> some View {
        content
            .scrollEdgeEffectStyle(active ? .soft : nil, for: .bottom)
            .background {
                if active {
                    BottomEdgeScrollSource()
                }
            }
    }
}

/// Finds the list behind this view and turns on its progressive bottom blur.
private struct BottomEdgeScrollSource: UIViewRepresentable {
    @Environment(\.bottomEdgeScroll) private var bridge

    func makeUIView(context: Context) -> ScrollEdgeSourceView {
        let view = ScrollEdgeSourceView()
        view.onScrollView = { bridge.scrollView = $0 }
        return view
    }

    func updateUIView(_ uiView: ScrollEdgeSourceView, context: Context) {
        uiView.onScrollView = { bridge.scrollView = $0 }
        uiView.report()
    }
}

private final class ScrollEdgeSourceView: UIView {
    var onScrollView: ((UIScrollView?) -> Void)?
    private weak var reported: UIScrollView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        report()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        report()
    }

    func report() {
        let scroll = nearestScrollView()
        guard scroll !== reported else { return }
        reported = scroll
        scroll?.bottomEdgeEffect.style = .soft
        scroll?.bottomEdgeEffect.isHidden = false
        onScrollView?(scroll)
    }

    private func nearestScrollView() -> UIScrollView? {
        var view: UIView? = self
        while let current = view {
            if let scroll = current as? UIScrollView { return scroll }
            if let scroll = current.superview?.subviews.compactMap({ $0 as? UIScrollView }).first {
                return scroll
            }
            view = current.superview
        }
        return nil
    }
}

/// Tells the list that this glass bar overlays its bottom edge, so the blur covers that band.
private struct BottomEdgeInteraction: UIViewRepresentable {
    var bridge: BottomEdgeScroll

    func makeUIView(context: Context) -> EdgeInteractionAnchor {
        let view = EdgeInteractionAnchor()
        view.attach(bridge)
        return view
    }

    func updateUIView(_ uiView: EdgeInteractionAnchor, context: Context) {
        uiView.attach(bridge)
    }
}

private final class EdgeInteractionAnchor: UIView {
    private let interaction = UIScrollEdgeElementContainerInteraction()
    private weak var installedOn: UIView?
    private var observing = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        interaction.edge = .bottom
    }

    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        install()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        install()
    }

    func attach(_ bridge: BottomEdgeScroll) {
        install()
        interaction.scrollView = bridge.scrollView
        interaction.edge = .bottom
        guard !observing else { return }
        observing = true
        bridge.observe { [weak self] scrollView in
            self?.interaction.scrollView = scrollView
            self?.interaction.edge = .bottom
        }
    }

    /// The anchor sits in the bar's background. Climb to the container that also holds the glass.
    private func install() {
        guard window != nil else { return }
        var container: UIView? = superview
        var candidate: UIView?
        while let current = container, current.bounds.height < 180, current.bounds.width > 80 {
            candidate = current
            container = current.superview
        }
        guard let candidate, installedOn !== candidate else { return }
        if let previous = installedOn {
            previous.interactions.removeAll { ($0 as AnyObject) === interaction }
        }
        candidate.addInteraction(interaction)
        installedOn = candidate
    }
}
