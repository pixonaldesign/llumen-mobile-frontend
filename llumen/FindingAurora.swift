import SwiftUI
import UIKit
import WebKit

enum FindingAuroraMode: Equatable {
    case off, chip, alert
}

struct FindingItem: Identifiable {
    var id: String
    var domain: String
    var title: String
    var before: String
    var highlight: String
    var after: String
    var storyId: String? = nil
}

enum FindingLibrary {
    /// Alert ramp from `findingAuroraSettings.ts`. The toast border uses the ocean stops instead.
    static let alertStops = [Color(hex: 0x4110C6), Color(hex: 0xFF2344), Color(hex: 0x5E77B0)]
    static let oceanStops = [Color(hex: 0x3C78FF), Color(hex: 0x2A4098), Color(hex: 0x6BEEFF)]

    static let items: [FindingItem] = [
        .init(
            id: "dumping-map",
            domain: "Engineering",
            title: "Environmental Wellness Monitoring Checks",
            before: "There has been a noticeable rise in illegal dumping operations throughout Abu Dhabi, with reports ",
            highlight: "increasing by 35%",
            after: " compared with last week",
            storyId: "r1"
        ),
        .init(
            id: "aqi-map",
            domain: "Operations",
            title: "Air Quality Corridor Review",
            before: "Fine particulate readings along the coastal corridor are ",
            highlight: "up 18% overnight",
            after: ", with three districts crossing the sensitive-group threshold",
            storyId: "r2"
        ),
        .init(
            id: "proactive-ai",
            domain: "Customer Success",
            title: "Proactive Risk Digest",
            before: "Llumen flagged a clustered complaint pattern in MBZ City that typically precedes ",
            highlight: "service-center delays of 40 minutes",
            after: " within 72 hours"
        ),
    ]
}

private enum FindingVote: Equatable {
    case up, down
}

struct FindingAuroraOverlay: View {
    @Environment(AppModel.self) private var model
    var mode: FindingAuroraMode
    @State private var votes: [String: FindingVote] = [:]
    @State private var auroraRise: CGFloat = 0.001
    @State private var pageDrag: CGFloat = 0
    @State private var slideID = 0
    @State private var sliding = false
    @State private var auroraToken = 0

    private var index: Int {
        guard !FindingLibrary.items.isEmpty else { return 0 }
        return min(max(model.findingIndex, 0), FindingLibrary.items.count - 1)
    }

    var body: some View {
        GeometryReader { geo in
            let fadeHold = geo.size.height * 0.42
            let home = max(geo.safeAreaInsets.bottom, 34)
            let bottomPad = home + Theme.chromeClearance
            ZStack(alignment: .bottom) {
                if mode == .alert {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.16),
                            .init(color: Color.black.opacity(0.45), location: 0.4),
                            .init(color: Color.black.opacity(0.78), location: 0.66),
                            .init(color: Color.black.opacity(0.9), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }

                AuroraField(
                    stops: FindingLibrary.alertStops,
                    fadeHold: fadeHold,
                    fadeSpan: 178
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.08),
                            .init(color: .black, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .scaleEffect(y: auroraRise, anchor: .bottom)
                }
                .mask(alignment: .bottom) {
                    Rectangle().padding(.top, max(geo.safeAreaInsets.top, 54) + 64)
                }
                .opacity(mode == .alert || auroraRise > 0.02 ? 1 : 0)
                .animation(.none, value: mode)
                .allowsHitTesting(false)
                .accessibilityHidden(mode != .alert)
                .onAppear {
                    guard mode == .alert else { return }
                    setAurora(showing: true)
                }
                .onChange(of: mode) { _, new in
                    setAurora(showing: new == .alert)
                }

                switch mode {
                case .off:
                    Color.clear.allowsHitTesting(false)
                case .alert, .chip:
                    findingLayout(bottomPad: bottomPad, width: geo.size.width, card: mode == .chip)
                }
            }
            .allowsHitTesting(mode != .off)
        }
        .ignoresSafeArea()
        .simultaneousGesture(alertDismiss)
    }

    private var alertDismiss: some Gesture {
        DragGesture(minimumDistance: 28)
            .onEnded { value in
                guard mode == .alert else { return }
                let downward = value.translation.height
                guard downward > 72, downward > abs(value.translation.width) else { return }
                model.dismissFinding()
            }
    }

    /// Light rises from the bottom edge, then rests at full brightness.
    private func setAurora(showing: Bool) {
        auroraToken += 1
        if showing {
            AuroraStage.shared.setRunning(true)
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { auroraRise = 0.001 }
            DispatchQueue.main.async {
                withAnimation(.easeIn(duration: 0.525)) { auroraRise = 1 }
            }
        } else {
            pageDrag = 0
            let token = auroraToken
            withAnimation(.easeIn(duration: 0.32)) {
                auroraRise = 0.001
            } completion: {
                guard auroraToken == token else { return }
                AuroraStage.shared.setRunning(false)
            }
        }
    }

    /// Toast and aurora share this stack. The page control sits outside the cards.
    private func findingLayout(bottomPad: CGFloat, width: CGFloat, card: Bool) -> some View {
        VStack(spacing: 12) {
            cardStrip(width: width, card: card)
            pageControl(width: width)
        }
        .padding(.bottom, bottomPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    /// One strip. Each page is a card with its content fixed inside it.
    private func cardStrip(width: CGFloat, card: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(FindingLibrary.items.indices, id: \.self) { i in
                findingPage(FindingLibrary.items[i], card: card)
                    .frame(width: width, alignment: .bottom)
            }
        }
        .offset(x: -CGFloat(index) * width + pageDrag)
        .frame(width: width, alignment: .leading)
        .clipped()
        .simultaneousGesture(pageSwipe(width: width))
    }

    private func findingPage(_ pageItem: FindingItem, card: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Text(pageItem.domain)
                    .font(LumenFont.font(15, .medium, relativeTo: .subheadline))
                    .foregroundStyle(card ? Theme.text.opacity(0.78) : Color.white.opacity(0.78))
                    .lineLimit(1)
                Spacer(minLength: 8)
                close(onGlass: card)
            }
            findingText(pageItem, onGlass: card)
            findingActions(pageItem)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .modifier(FindingCardGlass(enabled: card))
        .padding(.horizontal, 16)
    }

    /// Tell me more, then the circular overflow. Paging moves the whole card.
    private func findingActions(_ pageItem: FindingItem) -> some View {
        HStack(spacing: 10) {
            tellMeMore(pageItem)
            findingOverflow(pageItem)
            Spacer(minLength: 0)
        }
    }

    /// Dots sit under the cards, with no chrome of their own.
    private func pageControl(width: CGFloat) -> some View {
        FindingPageControl(
            count: FindingLibrary.items.count,
            index: index,
            onMedia: mode == .alert,
            suppressSync: sliding,
            onSelect: { page in
                guard FindingLibrary.items.indices.contains(page), page != index else { return }
                slide(to: page, width: width)
            }
        )
        .frame(height: 22)
        .frame(maxWidth: .infinity)
        .accessibilityHint("Swipe left or right to switch findings")
    }

    private func pageSwipe(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy) else { return }
                if abs(dx) < 36 { slideID += 1 }
                let last = FindingLibrary.items.count - 1
                let blocked = (index == 0 && dx > 0) || (index == last && dx < 0)
                let travel = blocked ? dx * 0.22 : dx
                var track = Transaction()
                track.disablesAnimations = true
                withTransaction(track) { pageDrag = travel }
            }
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                let flick = value.predictedEndTranslation.width
                let last = FindingLibrary.items.count - 1
                let horizontal = abs(dx) > abs(dy)
                if horizontal && index < last && (dx < -48 || flick < -120) {
                    slide(to: index + 1, width: width)
                } else if horizontal && index > 0 && (dx > 48 || flick > 120) {
                    slide(to: index - 1, width: width)
                } else {
                    slideID += 1
                    let token = slideID
                    withAnimation(Theme.motion, completionCriteria: .logicallyComplete) {
                        pageDrag = 0
                    } completion: {
                        guard slideID == token else { return }
                    }
                }
            }
    }

    /// Slides the strip so the card and its content stay one object, then settles the index.
    private func slide(to page: Int, width: CGFloat) {
        guard width > 1, page != index else { return }
        slideID += 1
        let token = slideID
        sliding = true
        let target = -CGFloat(page - index) * width
        withAnimation(Theme.motion, completionCriteria: .logicallyComplete) {
            pageDrag = target
        } completion: {
            guard slideID == token else { return }
            var snap = Transaction()
            snap.disablesAnimations = true
            withTransaction(snap) {
                model.findingIndex = page
                pageDrag = 0
                sliding = false
            }
        }
    }

    /// Finding context: Open slides when this finding has a story, plus Keep monitoring and the vote.
    private func findingOverflow(_ pageItem: FindingItem) -> some View {
        CircleOverflowButton(
            open: pageItem.storyId == nil ? nil : (
                title: "Open slides",
                icon: .slideshow,
                action: {
                    guard let storyId = pageItem.storyId else { return }
                    model.story = StoryRoute(id: storyId, title: pageItem.title)
                }
            ),
            keepMonitoring: {
                model.dismissFinding()
            },
            helpfulSelected: votes[pageItem.id] == .up,
            notHelpfulSelected: votes[pageItem.id] == .down,
            onHelpful: { vote(pageItem, .up) },
            onNotHelpful: { vote(pageItem, .down) }
        )
    }

    private func vote(_ pageItem: FindingItem, _ value: FindingVote) {
        votes[pageItem.id] = votes[pageItem.id] == value ? nil : value
    }

    private func tellMeMore(_ pageItem: FindingItem) -> some View {
        Button {
            model.askAbout(briefing: pageItem.title, finding: pageItem.before + pageItem.highlight + pageItem.after)
        } label: {
            HStack(spacing: 8) {
                PhosphorIcon(.chatCircle, size: 18)
                Text("Tell me more")
                    .font(LumenFont.font(16, .medium, relativeTo: .callout))
                    .lineLimit(1)
            }
            .foregroundStyle(Theme.text)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Title 2 (22pt). Scales with Dynamic Type from the Large content-size default.
    private func findingText(_ pageItem: FindingItem, onGlass: Bool) -> some View {
        Text(sentence(pageItem))
            .lineSpacing(4)
            .foregroundStyle(onGlass ? Theme.text : Color.white)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func sentence(_ pageItem: FindingItem) -> AttributedString {
        let font = Font.custom("InnovatorGrotesk-Regular", size: 22, relativeTo: .title2)
        var before = AttributedString(pageItem.before)
        var highlight = AttributedString(pageItem.highlight)
        var after = AttributedString(pageItem.after)
        before.font = font
        highlight.font = font
        highlight.underlineStyle = .single
        after.font = font
        return before + highlight + after
    }

    private func close(onGlass: Bool) -> some View {
        Button {
            model.dismissFinding()
        } label: {
            PhosphorIcon(.x, size: 15)
                .foregroundStyle(onGlass ? Theme.text.opacity(0.78) : Color.white.opacity(0.78))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close findings")
    }

}

/// Toast chrome. Alert copy sits on the aurora, so it stays unglassed.
private struct FindingCardGlass: ViewModifier {
    var enabled: Bool

    @ViewBuilder func body(content: Content) -> some View {
        if enabled {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            content
        }
    }
}

/// UIPageControl: the iPhone pattern for a short set of peer pages.
private struct FindingPageControl: UIViewRepresentable {
    var count: Int
    var index: Int
    /// Aurora stays dark, so the dots stay white. Toast glass follows the system.
    var onMedia: Bool
    var suppressSync: Bool
    var onSelect: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.backgroundStyle = .minimal
        applyChrome(control)
        control.hidesForSinglePage = true
        control.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ control: UIPageControl, context: Context) {
        context.coordinator.onSelect = onSelect
        context.coordinator.suppress = suppressSync
        control.numberOfPages = count
        applyChrome(control)
        if !suppressSync, control.currentPage != index {
            control.currentPage = index
        }
    }

    private func applyChrome(_ control: UIPageControl) {
        if onMedia {
            control.currentPageIndicatorTintColor = .white
            control.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.35)
        } else {
            control.currentPageIndicatorTintColor = .label
            control.pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.35)
        }
    }

    final class Coordinator: NSObject {
        var onSelect: (Int) -> Void
        var suppress = false
        init(onSelect: @escaping (Int) -> Void) { self.onSelect = onSelect }
        @objc func changed(_ sender: UIPageControl) {
            guard !suppress else { return }
            onSelect(sender.currentPage)
        }
    }
}

/// Circular overflow next to Tell me more. Open and Keep monitoring appear only when that context has them.
struct CircleOverflowButton: View {
    var open: (title: String, icon: Phosphor, action: () -> Void)? = nil
    var keepMonitoring: (() -> Void)? = nil
    var helpfulSelected: Bool
    var notHelpfulSelected: Bool
    var onHelpful: () -> Void
    var onNotHelpful: () -> Void

    private var marked: Bool { helpfulSelected || notHelpfulSelected }

    var body: some View {
        Menu {
            if let open {
                Button(action: open.action) {
                    PhosphorMenuLabel(title: open.title, icon: open.icon)
                }
            }
            if let keepMonitoring {
                Button(action: keepMonitoring) {
                    PhosphorMenuLabel(title: "Keep monitoring", icon: .eye)
                }
            }
            Button(action: onHelpful) {
                PhosphorMenuLabel(title: "Helpful", icon: .thumbsUp)
            }
            Button(action: onNotHelpful) {
                PhosphorMenuLabel(title: "Not helpful", icon: .thumbsDown)
            }
        } label: {
            PhosphorIcon(.dotsThree, size: 18)
                .foregroundStyle(Theme.text)
                .frame(width: 44, height: 44)
                .glassEffect(
                    marked ? .regular.tint(Color.primary.opacity(0.18)).interactive() : .regular.interactive(),
                    in: Circle()
                )
        }
        .menuOrder(.fixed)
        .buttonStyle(.plain)
        .accessibilityLabel("More actions")
        .accessibilityValue(helpfulSelected ? "Helpful" : (notHelpfulSelected ? "Not helpful" : ""))
    }
}

struct AuroraField: View {
    var stops: [Color]
    var fadeHold: CGFloat
    var fadeSpan: CGFloat

    var body: some View {
        AuroraWebView(stops: stops, fadeHold: fadeHold, fadeSpan: fadeSpan)
            .allowsHitTesting(false)
    }
}

/// One WebGL canvas for the whole process. Created at launch and parked in a
/// window so the shader is already running when the alert is shown.
@MainActor
final class AuroraStage: NSObject, WKNavigationDelegate {
    static let shared = AuroraStage()

    let webView: EdgeToEdgeWebView
    private var claimed = false
    private var parkAttempts = 0
    private var warmupWindow: UIWindow?
    private var pendingJS: String?
    private var pushed: (stops: [Color], fadeHold: CGFloat, fadeSpan: CGFloat)?
    private var running = false

    private override init() {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        configuration.websiteDataStore = .nonPersistent()
        let web = EdgeToEdgeWebView(frame: CGRect(x: 0, y: 0, width: 440, height: 956), configuration: configuration)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.underPageBackgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.alpha = 0
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.isUserInteractionEnabled = false
        web.pinContentToPhysicalEdges()
        self.webView = web
        super.init()
        web.navigationDelegate = self
        web.loadHTMLString(AuroraWebView.page, baseURL: nil)
    }

    static func preload() {
        shared.schedulePark()
    }

    func claim() -> WKWebView {
        claimed = true
        webView.removeFromSuperview()
        warmupWindow?.isHidden = true
        warmupWindow = nil
        return webView
    }

    func push(stops: [Color], fadeHold: CGFloat, fadeSpan: CGFloat) {
        if let pushed, pushed.stops == stops, pushed.fadeHold == fadeHold, pushed.fadeSpan == fadeSpan { return }
        pushed = (stops, fadeHold, fadeSpan)
        let hexes = stops.map(Self.hex).joined(separator: "','")
        let js = "window.llumenAurora && window.llumenAurora(['\(hexes)'], \(Float(fadeHold)), \(Float(fadeSpan)));"
        pendingJS = js
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    /// The shader only draws frames while the aurora can be seen.
    func setRunning(_ on: Bool) {
        guard on != running else { return }
        running = on
        webView.evaluateJavaScript(Self.runJS(on), completionHandler: nil)
    }

    private static func runJS(_ on: Bool) -> String {
        "window.llumenAuroraRun && window.llumenAuroraRun(\(on));"
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let reveal = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                UIView.animate(withDuration: 0.18) { webView.alpha = 1 }
            }
        }
        webView.evaluateJavaScript((pendingJS ?? "") + Self.runJS(running)) { _, _ in reveal() }
    }

    private func schedulePark() {
        parkAttempts += 1
        guard parkAttempts < 30, !claimed else { return }
        DispatchQueue.main.async { [weak self] in
            self?.park()
        }
    }

    private func park() {
        guard !claimed, webView.superview == nil else { return }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else {
            schedulePark()
            return
        }
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue - 1)
        window.backgroundColor = .clear
        let host = UIViewController()
        host.view.backgroundColor = .clear
        window.rootViewController = host
        guard !claimed, webView.superview == nil else { return }
        webView.frame = window.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.addSubview(webView)
        guard !claimed else {
            webView.removeFromSuperview()
            return
        }
        window.isHidden = false
        warmupWindow = window
    }

    private static func hex(_ color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02x%02x%02x", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

/// Same fragment shader as `Aurora.tsx`, drawn in a transparent WebGL canvas.
private struct AuroraWebView: UIViewRepresentable {
    var stops: [Color]
    var fadeHold: CGFloat
    var fadeSpan: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        let web = AuroraStage.shared.claim()
        web.pinContentToPhysicalEdges()
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        web.pinContentToPhysicalEdges()
        AuroraStage.shared.push(stops: stops, fadeHold: fadeHold, fadeSpan: fadeSpan)
    }

    fileprivate static let page = """
    <!DOCTYPE html>
    <html><head>
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <style>html,body,canvas{margin:0;width:100%;height:100%;background:transparent;overflow:hidden}</style>
    </head><body><canvas id="c" width="880" height="1912"></canvas><script>
    const canvas = document.getElementById('c');
    const gl = canvas.getContext('webgl2', { premultipliedAlpha: false, alpha: true });
    const vert = `#version 300 es
    in vec2 position;
    void main(){ gl_Position = vec4(position, 0.0, 1.0); }`;
    const frag = `#version 300 es
    precision highp float;
    uniform float uTime; uniform float uAmplitude; uniform vec3 uColorStops[3];
    uniform vec2 uResolution; uniform float uBlend; uniform float uFadeHold;
    uniform float uFadeSpan; uniform float uStreaks; uniform float uHighlights;
    out vec4 fragColor;
    vec3 permute(vec3 x){ return mod(((x*34.0)+1.0)*x, 289.0); }
    float snoise(vec2 v){
      const vec4 C = vec4(0.211324865405187,0.366025403784439,-0.577350269189626,0.024390243902439);
      vec2 i = floor(v + dot(v, C.yy));
      vec2 x0 = v - i + dot(i, C.xx);
      vec2 i1 = (x0.x > x0.y) ? vec2(1.0,0.0) : vec2(0.0,1.0);
      vec4 x12 = x0.xyxy + C.xxzz; x12.xy -= i1; i = mod(i, 289.0);
      vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
      vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
      m = m*m; m = m*m;
      vec3 x = 2.0 * fract(p * C.www) - 1.0;
      vec3 h = abs(x) - 0.5; vec3 ox = floor(x + 0.5); vec3 a0 = x - ox;
      m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
      vec3 g; g.x = a0.x * x0.x + h.x * x0.y; g.yz = a0.yz * x12.xz + h.yz * x12.yw;
      return 130.0 * dot(m, g);
    }
    vec3 hex(float r, float g, float b){ return vec3(r,g,b); }
    void main(){
      vec2 uv = gl_FragCoord.xy / uResolution; uv.y = 1.0 - uv.y;
      vec3 ramp = mix(uColorStops[0], uColorStops[2], uv.x);
      float mid = smoothstep(0.0, 0.5, uv.x) * (1.0 - smoothstep(0.5, 1.0, uv.x));
      ramp = mix(ramp, uColorStops[1], mid);
      float height = snoise(vec2(uv.x * 2.0 + uTime * 0.1, uTime * 0.25)) * 0.5 * uAmplitude;
      height = exp(height); height = (uv.y * 2.0 - height + 0.2); float intensity = 0.6 * height;
      float midPoint = 0.20;
      float auroraAlpha = smoothstep(midPoint - uBlend * 0.5, midPoint + uBlend * 0.5, intensity);
      float fromBottom = gl_FragCoord.y;
      float fadeStart = max(uFadeHold * 0.45, uFadeHold - uFadeSpan * 0.65);
      float fadeEnd = uFadeHold + max(uFadeSpan, 1.0) * 1.65;
      float t = clamp((fromBottom - fadeStart) / max(fadeEnd - fadeStart, 1.0), 0.0, 1.0);
      float s = t*t*t*(t*(t*6.0-15.0)+10.0); float veil = 1.0 - s; auroraAlpha *= veil;
      float nWide = snoise(vec2(uv.x * 2.4 + uTime * 0.035, uv.y * 0.18 - uTime * 0.012));
      float nFine = snoise(vec2(uv.x * 5.0 - uTime * 0.028, uv.y * 0.06 + nWide * 0.4));
      float fine = sin(uv.x * 15.0 + nWide * 1.4 + nFine * 0.7); float wide = sin(uv.x * 7.0 + nFine * 0.9 + uTime * 0.015);
      fine = fine * 0.5 + 0.5; wide = wide * 0.5 + 0.5;
      float curtains = mix(wide, fine, 0.2); float rays = smoothstep(0.34, 0.86, curtains) * mix(0.72, 1.0, veil);
      auroraAlpha *= mix(1.0, 0.34 + rays, clamp(uStreaks, 0.0, 1.0));
      float core = pow(smoothstep(0.58, 1.0, curtains), 1.7) * veil * veil;
      vec3 bright = mix(ramp, vec3(0.82, 0.96, 1.0), 0.4);
      vec3 body = ramp * max(intensity, 0.0) * mix(1.0, 0.62 + 0.7 * rays, clamp(uStreaks, 0.0, 1.0));
      vec3 auroraColor = body + bright * core * uHighlights * 1.45;
      float alpha = clamp(auroraAlpha + core * uHighlights * 0.28, 0.0, 1.0);
      fragColor = vec4(auroraColor * alpha, alpha);
    }`;
    function compile(type, src){ const s = gl.createShader(type); gl.shaderSource(s, src); gl.compileShader(s); return s; }
    const program = gl.createProgram();
    gl.attachShader(program, compile(gl.VERTEX_SHADER, vert));
    gl.attachShader(program, compile(gl.FRAGMENT_SHADER, frag));
    gl.linkProgram(program); gl.useProgram(program);
    const buf = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, buf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1, 3,-1, -1,3]), gl.STATIC_DRAW);
    const loc = gl.getAttribLocation(program, 'position');
    gl.enableVertexAttribArray(loc); gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
    const u = {
      time: gl.getUniformLocation(program, 'uTime'),
      amp: gl.getUniformLocation(program, 'uAmplitude'),
      stops: gl.getUniformLocation(program, 'uColorStops'),
      res: gl.getUniformLocation(program, 'uResolution'),
      blend: gl.getUniformLocation(program, 'uBlend'),
      hold: gl.getUniformLocation(program, 'uFadeHold'),
      span: gl.getUniformLocation(program, 'uFadeSpan'),
      streaks: gl.getUniformLocation(program, 'uStreaks'),
      highlights: gl.getUniformLocation(program, 'uHighlights')
    };
    let colors = [0.255,0.063,0.776, 1.0,0.137,0.267, 0.369,0.467,0.690];
    let holdFrac = 0.42, spanFrac = 0.21;
    function parse(hex){
      const n = parseInt(hex.slice(1), 16);
      return [(n>>16&255)/255, (n>>8&255)/255, (n&255)/255];
    }
    window.llumenAurora = function(stops, fadeHold, fadeSpan){
      colors = [].concat(parse(stops[0]), parse(stops[1]), parse(stops[2]));
      const cssH = canvas.clientHeight;
      if (cssH > 200 && fadeHold > 2.5) {
        holdFrac = fadeHold / cssH;
        spanFrac = Math.max(fadeSpan, 1) / cssH;
      }
    };
    const start = performance.now() - 80000;
    let running = false, scheduled = false, warmed = false;
    function schedule(){
      if (scheduled) return;
      scheduled = true;
      requestAnimationFrame(frame);
    }
    window.llumenAuroraRun = function(on){
      running = on;
      if (on) schedule();
    };
    function frame(now){
      scheduled = false;
      const dpr = Math.min(devicePixelRatio || 1, 2);
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      if (w < 200 || h < 200) { if (running || !warmed) schedule(); return; }
      const bw = Math.floor(w * dpr), bh = Math.floor(h * dpr);
      if (canvas.width !== bw || canvas.height !== bh) {
        canvas.width = bw; canvas.height = bh;
      }
      gl.viewport(0, 0, canvas.width, canvas.height);
      gl.clearColor(0,0,0,0); gl.clear(gl.COLOR_BUFFER_BIT);
      gl.uniform1f(u.time, (now - start) / 1000);
      gl.uniform1f(u.amp, 1.44); gl.uniform1f(u.blend, 0.5);
      gl.uniform3fv(u.stops, colors); gl.uniform2f(u.res, canvas.width, canvas.height);
      gl.uniform1f(u.hold, canvas.height * holdFrac);
      gl.uniform1f(u.span, canvas.height * spanFrac);
      gl.uniform1f(u.streaks, 0.55); gl.uniform1f(u.highlights, 0.05);
      gl.drawArrays(gl.TRIANGLES, 0, 3);
      warmed = true;
      if (running) schedule();
    }
    schedule();
    </script></body></html>
    """
}

/// Conic ocean border. Turns twice, then fades out.
struct OceanShimmerBorder: View {
    var stops: [Color] = FindingLibrary.oceanStops
    @State private var spin: Double = 0
    @State private var ringOpacity: Double = 1
    @State private var played = false

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                AngularGradient(
                    stops: [
                        .init(color: stops[1], location: 0),
                        .init(color: stops[0], location: 70 / 360),
                        .init(color: stops[2], location: 120 / 360),
                        .init(color: stops[0], location: 170 / 360),
                        .init(color: stops[1], location: 240 / 360),
                        .init(color: stops[1], location: 1),
                    ],
                    center: .center,
                    angle: .degrees(spin)
                ),
                lineWidth: 1.5
            )
            .opacity(ringOpacity)
            .onAppear(perform: play)
            .allowsHitTesting(false)
    }

    private func play() {
        guard !played else { return }
        played = true
        withAnimation(.easeOut(duration: 2.1)) { spin = 720 }
        withAnimation(.easeIn(duration: 0.4).delay(1.7)) { ringOpacity = 0 }
    }
}

/// Frosted launcher from Llumen: glass disc, pulsing coral orb, ocean shimmer ring.
struct LlumenAskButton: View {
    var cue: FindingAuroraMode
    var token: Int
    var action: () -> Void
    @State private var pulse = false
    @State private var spin: Double = 0
    @State private var ringOpacity: Double = 0

    private var ring: [Color] {
        cue == .alert ? FindingLibrary.alertStops : FindingLibrary.oceanStops
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            stops: [
                                .init(color: ring[1], location: 0),
                                .init(color: ring[0], location: 70 / 360),
                                .init(color: ring[2], location: 120 / 360),
                                .init(color: ring[0], location: 170 / 360),
                                .init(color: ring[1], location: 240 / 360),
                                .init(color: ring[1], location: 1),
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .rotationEffect(.degrees(spin))
                    .opacity(ringOpacity)
                    .padding(1)
                LlumenOrb()
                    .frame(width: 24, height: 24)
                    .scaleEffect(pulse ? 1.14 : 1)
            }
            .frame(width: 58, height: 58)
            .glassEffect(.regular, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask Llumen")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onChange(of: token) { _, _ in
            guard cue == .chip || cue == .alert else { return }
            playRim()
        }
    }

    /// Two turns, then the ring fades. Toast uses the ocean stops; aurora uses the alert stops.
    private func playRim() {
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            spin = 0
            ringOpacity = 1
        }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 2.1)) { spin = 720 }
            withAnimation(.easeIn(duration: 0.4).delay(1.7)) { ringOpacity = 0 }
        }
    }
}

/// `launcher-orb.svg`: coral glow with a white core.
struct LlumenOrb: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xFF6A6A).opacity(0.85))
                .blur(radius: 5)
            Circle()
                .fill(Color.white)
                .padding(3)
                .blur(radius: 2.5)
            Circle()
                .fill(Color.white.opacity(0.95))
                .padding(6)
        }
    }
}
