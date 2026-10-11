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

    private var index: Int {
        guard !FindingLibrary.items.isEmpty else { return 0 }
        return min(max(model.findingIndex, 0), FindingLibrary.items.count - 1)
    }

    private var item: FindingItem { FindingLibrary.items[index] }

    var body: some View {
        GeometryReader { geo in
            let fadeHold = geo.size.height * 0.42
            let home = max(geo.safeAreaInsets.bottom, 34)
            let bottomPad = home + Theme.chromeClearance
            ZStack(alignment: .bottom) {
                AuroraField(
                    stops: FindingLibrary.alertStops,
                    fadeHold: fadeHold,
                    fadeSpan: 178
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .opacity(mode == .alert ? 1 : 0)
                .animation(nil, value: mode)
                .allowsHitTesting(false)
                .accessibilityHidden(mode != .alert)

                switch mode {
                case .off:
                    Color.clear.allowsHitTesting(false)
                case .alert:
                    ZStack(alignment: .bottom) {
                        alertVeil
                        alertCopy
                            .padding(.horizontal, 24)
                            .padding(.bottom, bottomPad)
                    }
                    .contentShape(Rectangle())
                case .chip:
                    chipStack
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
                withAnimation(Theme.motion) { model.findingMode = .off }
            }
    }

    private var alertVeil: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color.black.opacity(0.28), location: 0.18),
                    .init(color: Color.black.opacity(0.62), location: 0.42),
                    .init(color: Color.black.opacity(0.78), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 620)
            .background(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 420)
                    .mask(
                        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private var alertCopy: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(item.domain)
                    .font(LumenFont.font(13, .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                Spacer(minLength: 8)
                close
            }
            findingText(size: 22)
            alertActions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Bottom row matches the toast: Tell me more leading, pager trailing.
    private var alertActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    keepMonitoring
                    if item.storyId != nil { openSlides }
                    voteGroup
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        keepMonitoring
                        if item.storyId != nil { openSlides }
                    }
                    voteGroup
                }
            }
            HStack(spacing: 10) {
                tellMeMore
                Spacer(minLength: 0)
                nav
            }
        }
    }

    private var keepMonitoring: some View {
        Button {
            withAnimation(Theme.motion) { model.findingMode = .off }
        } label: {
            Text("Keep monitoring")
                .font(LumenFont.font(14, .medium))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .overlay {
                    Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var tellMeMore: some View {
        Button {
            model.attachedBriefing = item.title
            model.chatTitle = item.title
            model.showChat = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 16, weight: .regular))
                Text("Tell me more")
                    .font(LumenFont.font(14, .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .overlay {
                Capsule().strokeBorder(Theme.textSecondary, lineWidth: 1.4)
            }
        }
        .buttonStyle(.plain)
    }

    private var openSlides: some View {
        Button {
            guard let storyId = item.storyId else { return }
            model.story = StoryRoute(id: storyId, title: item.title)
        } label: {
            Text("Open slides")
                .font(LumenFont.font(14, .medium))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .overlay {
                    Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var voteGroup: some View {
        HStack(spacing: 8) {
            voteButton(.up, symbol: "hand.thumbsup", label: "Helpful")
            voteButton(.down, symbol: "hand.thumbsdown", label: "Not helpful")
        }
    }

    private func voteButton(_ value: FindingVote, symbol: String, label: String) -> some View {
        let selected = votes[item.id] == value
        return Button {
            votes[item.id] = votes[item.id] == value ? nil : value
        } label: {
            Image(systemName: selected ? "\(symbol).fill" : symbol)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 44)
                .background(selected ? Color.white.opacity(0.12) : Color.clear, in: Circle())
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var chipStack: some View {
        VStack {
            Spacer(minLength: 0)
            chipCard(item: item)
                .background {
                    ZStack {
                        if index + 2 < FindingLibrary.items.count {
                            chipBack
                                .padding(.horizontal, 16)
                                .offset(y: -28)
                        }
                        if index + 1 < FindingLibrary.items.count {
                            chipBack
                                .padding(.horizontal, 8)
                                .offset(y: -14)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 58 + 8 + 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Same height as the front card, shifted up so only a lip shows. No labels or body.
    private var chipBack: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(hex: 0x0E1014).opacity(0.28))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func chipCard(item: FindingItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(item.domain)
                    .font(LumenFont.font(11))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(1)
                Spacer(minLength: 8)
                close
            }
            findingText(size: 15)
                .lineLimit(3)
            HStack(spacing: 10) {
                Button {
                    model.attachedBriefing = item.title
                    model.chatTitle = item.title
                    model.findingMode = .off
                    model.showChat = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble")
                        Text("Tell me more")
                    }
                    .font(LumenFont.font(13, .medium))
                    .foregroundStyle(Color.white)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                nav
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: 196, alignment: .topLeading)
        .background(Color(hex: 0x0E1014).opacity(0.42), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
        }
    }

    private func findingText(size: CGFloat) -> some View {
        Text(sentence(size: size))
            .foregroundStyle(Color.white)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func sentence(size: CGFloat) -> AttributedString {
        let font = Font.custom("InnovatorGrotesk-Regular", size: size)
        var before = AttributedString(item.before)
        var highlight = AttributedString(item.highlight)
        var after = AttributedString(item.after)
        before.font = font
        highlight.font = font
        highlight.underlineStyle = .single
        after.font = font
        return before + highlight + after
    }

    private var nav: some View {
        HStack(spacing: 4) {
            Button { step(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(index == 0)
            Text("\(index + 1) / \(FindingLibrary.items.count)")
                .font(LumenFont.font(12, .medium))
                .foregroundStyle(Color.white.opacity(0.72))
            Button { step(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(index >= FindingLibrary.items.count - 1)
        }
        .foregroundStyle(Color.white.opacity(0.9))
    }

    private var close: some View {
        Button {
            withAnimation(Theme.motion) { model.findingMode = .off }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.72))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close findings")
    }

    private func step(_ delta: Int) {
        let next = index + delta
        guard FindingLibrary.items.indices.contains(next) else { return }
        withAnimation(Theme.motion) { model.findingIndex = next }
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

    private override init() {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = false
        configuration.websiteDataStore = .nonPersistent()
        let web = EdgeToEdgeWebView(frame: CGRect(x: 0, y: 0, width: 440, height: 956), configuration: configuration)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.underPageBackgroundColor = .clear
        web.scrollView.backgroundColor = .clear
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
        let hexes = stops.map(Self.hex).joined(separator: "','")
        let js = "window.llumenAurora && window.llumenAurora(['\(hexes)'], \(Float(fadeHold)), \(Float(fadeSpan)));"
        pendingJS = js
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let pendingJS else { return }
        webView.evaluateJavaScript(pendingJS, completionHandler: nil)
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
    let hold = 480, span = 178;
    function parse(hex){
      const n = parseInt(hex.slice(1), 16);
      return [(n>>16&255)/255, (n>>8&255)/255, (n&255)/255];
    }
    window.llumenAurora = function(stops, fadeHold, fadeSpan){
      colors = [].concat(parse(stops[0]), parse(stops[1]), parse(stops[2]));
      hold = fadeHold; span = fadeSpan;
    };
    const start = performance.now() - 80000;
    function frame(now){
      const dpr = Math.min(devicePixelRatio || 1, 2);
      const w = canvas.clientWidth > 1 ? canvas.clientWidth : 440;
      const h = canvas.clientHeight > 1 ? canvas.clientHeight : 956;
      if (canvas.width !== Math.floor(w*dpr) || canvas.height !== Math.floor(h*dpr)) {
        canvas.width = Math.floor(w*dpr); canvas.height = Math.floor(h*dpr);
      }
      gl.viewport(0, 0, canvas.width, canvas.height);
      gl.clearColor(0,0,0,0); gl.clear(gl.COLOR_BUFFER_BIT);
      gl.uniform1f(u.time, (now - start) / 1000);
      gl.uniform1f(u.amp, 1.44); gl.uniform1f(u.blend, 0.5);
      gl.uniform3fv(u.stops, colors); gl.uniform2f(u.res, canvas.width, canvas.height);
      gl.uniform1f(u.hold, hold * dpr); gl.uniform1f(u.span, span * dpr);
      gl.uniform1f(u.streaks, 0.55); gl.uniform1f(u.highlights, 0.05);
      gl.drawArrays(gl.TRIANGLES, 0, 3);
      requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
    </script></body></html>
    """
}

/// Conic ocean border from the finding toast card. Spins once per 1.15s.
struct OceanShimmerBorder: View {
    var stops: [Color] = FindingLibrary.oceanStops
    @State private var spin = false

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
                    angle: .degrees(spin ? 360 : 0)
                ),
                lineWidth: 1.5
            )
            .onAppear {
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    spin = true
                }
            }
            .allowsHitTesting(false)
    }
}

/// Frosted launcher from Llumen: glass disc, pulsing coral orb, ocean shimmer ring.
struct LlumenAskButton: View {
    var cue: FindingAuroraMode
    var action: () -> Void
    @State private var pulse = false
    @State private var spin = false

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
                    .rotationEffect(.degrees(spin ? 360 : 0))
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
            withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                spin = true
            }
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
