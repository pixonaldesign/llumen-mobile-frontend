import SwiftUI
import WebKit

/// Public Mapbox token and studio style from `InteractiveMap.tsx` in llumen-ai-frontend.
enum MapboxFeed {
    static let token = "pk.eyJ1IjoicGl4b25hbCIsImEiOiJjbHJocDZvY2cwMXAzMm1zMWZnZDhxNngxIn0.PcC8G5xFaPmXUGOY2h2tmw"
    static let style = "mapbox://styles/pixonal/cmqzd3vp2003g01s7f4oy3af9"
}

/// One Mapbox GL map behind the feed. Blur and scale match `FeedLanding` `.mapBlur` (22px, 1.06, 700ms).
struct LlumenMapView: UIViewRepresentable {
    var longitude: Double
    var latitude: Double
    var zoom: Double
    var blurred: Bool

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.isUserInteractionEnabled = false
        web.loadHTMLString(
            Self.page(longitude: longitude, latitude: latitude, zoom: zoom),
            baseURL: URL(string: "https://api.mapbox.com")
        )
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        let blur = blurred ? "true" : "false"
        let js = "window.llumenSync && window.llumenSync(\(longitude), \(latitude), \(zoom), \(blur));"
        web.evaluateJavaScript(js, completionHandler: nil)
    }

    private static func page(longitude: Double, latitude: Double, zoom: Double) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
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
          new ResizeObserver(function() { map.resize(); }).observe(document.body);
        </script>
        </body>
        </html>
        """
    }
}
