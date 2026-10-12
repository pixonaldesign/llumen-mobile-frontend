import SwiftUI
import WebKit

/// Public Mapbox token and studio style from `InteractiveMap.tsx` in llumen-ai-frontend.
enum MapboxFeed {
    static let token = "pk.eyJ1IjoicGl4b25hbCIsImEiOiJjbHJocDZvY2cwMXAzMm1zMWZnZDhxNngxIn0.PcC8G5xFaPmXUGOY2h2tmw"
    static let style = "mapbox://styles/pixonal/cmqzd3vp2003g01s7f4oy3af9"
}

/// One Mapbox GL map behind the feed. Blur and scale match `FeedLanding` `.mapBlur` (22px, 1.06, 700ms).
/// Shows a shimmer until the first frame with all tiles has rendered.
struct LlumenMapView: View {
    var longitude: Double
    var latitude: Double
    var zoom: Double
    var blurred: Bool

    @State private var ready = false

    var body: some View {
        ZStack {
            MapWebView(
                longitude: longitude,
                latitude: latitude,
                zoom: zoom,
                blurred: blurred,
                onReady: { ready = true }
            )
            if !ready {
                MapShimmer()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.35), value: ready)
    }
}

/// Placeholder in the map's own base color, drawn by the `mapShimmer` Metal shader.
private struct MapShimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = Float(context.date.timeIntervalSince(start))
            Rectangle()
                .fill(MapWebView.base)
                .visualEffect { content, proxy in
                    content.colorEffect(
                        ShaderLibrary.mapShimmer(.float2(proxy.size), .float(time))
                    )
                }
        }
        .allowsHitTesting(false)
    }
}

private struct MapWebView: UIViewRepresentable {
    static let base = Color(hex: 0x1C1C1E)

    var longitude: Double
    var latitude: Double
    var zoom: Double
    var blurred: Bool
    var onReady: () -> Void

    private var state: MapState {
        MapState(longitude: longitude, latitude: latitude, zoom: zoom, blurred: blurred)
    }

    func makeCoordinator() -> Coordinator {
        var loaded = state
        loaded.blurred = false
        return Coordinator(loaded: loaded)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: Coordinator.readyMessage)
        let web = EdgeToEdgeWebView(frame: .zero, configuration: configuration)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.isUserInteractionEnabled = false
        web.pinContentToPhysicalEdges()
        web.navigationDelegate = context.coordinator
        web.loadHTMLString(
            Self.page(longitude: longitude, latitude: latitude, zoom: zoom),
            baseURL: URL(string: "https://api.mapbox.com")
        )
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        web.pinContentToPhysicalEdges()
        context.coordinator.onReady = onReady
        context.coordinator.sync(state, in: web)
    }

    static func dismantleUIView(_ web: WKWebView, coordinator: Coordinator) {
        web.configuration.userContentController.removeScriptMessageHandler(forName: Coordinator.readyMessage)
    }

    struct MapState: Equatable {
        var longitude: Double
        var latitude: Double
        var zoom: Double
        var blurred: Bool
    }

    /// Sends camera and blur changes once the page can take them, and only when they differ from what it shows.
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        static let readyMessage = "llumenMapReady"

        var onReady: (() -> Void)?
        private var applied: MapState
        private var wanted: MapState
        private var ready = false

        init(loaded: MapState) {
            applied = loaded
            wanted = loaded
        }

        func sync(_ state: MapState, in web: WKWebView) {
            wanted = state
            flush(web)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            ready = true
            flush(webView)
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            onReady?()
        }

        private func flush(_ web: WKWebView) {
            guard ready, wanted != applied else { return }
            applied = wanted
            let js = "window.llumenSync && window.llumenSync(\(wanted.longitude), \(wanted.latitude), \(wanted.zoom), \(wanted.blurred));"
            web.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private static func page(longitude: Double, latitude: Double, zoom: Double) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">
        <link href="https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.css" rel="stylesheet">
        <script src="https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.js"></script>
        <style>
          html, body, #map { margin: 0; height: 100%; width: 100%; background: #1c1c1e; }
          #map { transition: filter 700ms ease, transform 700ms ease; transform-origin: center center; }
          .mapboxgl-ctrl-logo, .mapboxgl-ctrl-attrib { display: none !important; }
        </style>
        </head>
        <body>
        <div id="map"></div>
        <script>
          mapboxgl.accessToken = '\(MapboxFeed.token)';
          const map = new mapboxgl.Map({
            container: 'map',
            style: '\(MapboxFeed.style)',
            center: [\(longitude), \(latitude)],
            zoom: \(zoom),
            attributionControl: false,
            interactive: false,
            fadeDuration: 0
          });
          let pending = null;
          window.llumenSync = function(lng, lat, zoom, blur) {
            const next = { center: [lng, lat], zoom: zoom, duration: 700, essential: true };
            const el = document.getElementById('map');
            el.style.filter = blur ? 'blur(22px)' : 'blur(0px)';
            el.style.transform = blur ? 'scale(1.06)' : 'scale(1)';
            if (!map.loaded()) { pending = next; return; }
            map.easeTo(next);
          };
          map.on('load', function() {
            if (pending) map.easeTo(pending);
            map.resize();
          });
          map.once('idle', function() {
            window.webkit.messageHandlers.\(Coordinator.readyMessage).postMessage(true);
          });
          new ResizeObserver(function() { map.resize(); }).observe(document.body);
        </script>
        </body>
        </html>
        """
    }
}

extension WKWebView {
    func pinContentToPhysicalEdges() {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = .zero
        scrollView.automaticallyAdjustsScrollIndicatorInsets = false
    }
}

/// Map and aurora canvases paint under the status bar and home indicator.
final class EdgeToEdgeWebView: WKWebView {
    override var safeAreaInsets: UIEdgeInsets { .zero }
}
