import SwiftUI
import WebKit

/// Slow mesh on the assistant sheet while a reply is being composed.
/// Paper mesh gradient with distortion 0.09 and swirl 0. Dark lumen colors at speed 0.8,
/// or the light Paper palette at speed 0.2 when the system is light. It fades in over 1.2 seconds.
struct ThinkingMesh: View {
    var active: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        MeshGradientWebView(active: active, light: colorScheme == .light)
            .opacity(active ? 1 : 0)
            .animation(.easeInOut(duration: 1.2), value: active)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct MeshGradientWebView: UIViewRepresentable {
    var active: Bool
    var light: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        let web = WKWebView(frame: .zero, configuration: configuration)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.underPageBackgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.isUserInteractionEnabled = false
        web.navigationDelegate = context.coordinator
        context.coordinator.webView = web
        web.loadHTMLString(Self.page, baseURL: nil)
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.update(active: active, light: light)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        private var active = false
        private var light: Bool?
        private var appliedLight: Bool?
        private var appliedActive: Bool?
        private var ready = false

        func update(active nextActive: Bool, light nextLight: Bool) {
            active = nextActive
            light = nextLight
            apply()
        }

        private func apply() {
            guard ready, let light else { return }
            if appliedLight != light {
                appliedLight = light
                appliedActive = nil
                webView?.evaluateJavaScript("window.setMeshPalette('\(light ? "light" : "dark")')")
            }
            guard appliedActive != active else { return }
            appliedActive = active
            webView?.evaluateJavaScript("window.setMeshActive(\(active))")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            ready = true
            apply()
        }
    }

    private static let page = """
    <!DOCTYPE html>
    <html><head>
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <style>html,body,canvas{margin:0;width:100%;height:100%;background:transparent;overflow:hidden;display:block}</style>
    </head><body><canvas id="c"></canvas><script>
    const canvas = document.getElementById('c');
    const gl = canvas.getContext('webgl2', { premultipliedAlpha: false, alpha: true, antialias: false });
    const vert = `#version 300 es
    in vec2 position;
    out vec2 vUV;
    void main() {
      vUV = position * 0.5 + 0.5;
      gl_Position = vec4(position, 0.0, 1.0);
    }`;
    const frag = `#version 300 es
    precision highp float;
    uniform float uTime;
    uniform vec2 uResolution;
    uniform vec3 uColors[3];
    in vec2 vUV;
    out vec4 fragColor;

    float hash21(vec2 p) {
      p = fract(p * vec2(0.3183099, 0.3678794)) + 0.1;
      p += dot(p, p + 19.19);
      return fract(p.x * p.y);
    }
    vec2 spot(int i, float t) {
      float a = float(i) * 0.37;
      float b = 0.6 + fract(float(i) / 3.0) * 0.9;
      float c = 0.8 + fract(float(i + 1) / 4.0);
      return 0.5 + 0.5 * vec2(sin(t * b + a), cos(t * c + a * 1.5));
    }
    void main() {
      vec2 uv = vec2(gl_FragCoord.x / uResolution.x, 1.0 - gl_FragCoord.y / uResolution.y);
      float distortion = 0.09;
      float t = 0.5 * (uTime + 41.5);
      float radius = smoothstep(0.0, 1.0, length(uv - 0.5));
      float center = 1.0 - radius;
      for (float i = 1.0; i <= 2.0; i++) {
        uv.x += distortion * center / i * sin(t + i * 0.4 * smoothstep(0.0, 1.0, uv.y)) * cos(0.2 * t + i * 2.4 * smoothstep(0.0, 1.0, uv.y));
        uv.y += distortion * center / i * cos(t + i * 2.0 * smoothstep(0.0, 1.0, uv.x));
      }
      vec3 mixed = vec3(0.0);
      float weightSum = 0.0;
      for (int i = 0; i < 3; i++) {
        float dist = pow(length(uv - spot(i, t)), 3.5);
        float weight = 1.0 / (dist + 0.001);
        mixed += uColors[i] * weight;
        weightSum += weight;
      }
      mixed /= max(weightSum, 0.0001);
      fragColor = vec4(mixed, 1.0);
    }`;
    function compile(type, src) {
      const shader = gl.createShader(type);
      gl.shaderSource(shader, src);
      gl.compileShader(shader);
      return shader;
    }
    const program = gl.createProgram();
    gl.attachShader(program, compile(gl.VERTEX_SHADER, vert));
    gl.attachShader(program, compile(gl.FRAGMENT_SHADER, frag));
    gl.linkProgram(program);
    gl.useProgram(program);
    const buf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1, 3,-1, -1,3]), gl.STATIC_DRAW);
    const loc = gl.getAttribLocation(program, 'position');
    gl.enableVertexAttribArray(loc);
    gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
    const uTime = gl.getUniformLocation(program, 'uTime');
    const uResolution = gl.getUniformLocation(program, 'uResolution');
    const uColors = gl.getUniformLocation(program, 'uColors');
    const hex = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);
    const palettes = {
      dark: { colors: ['#03071E', '#070F2C', '#202E5D'], frame: 17852.965, speed: 0.8 },
      light: { colors: ['#92A5DA', '#516DCE', '#3B57E4'], frame: 20456.225, speed: 0.2 },
    };
    let palette = palettes.dark;
    let frame = palette.frame;
    let speed = 0;
    let last = performance.now();
    function useColors() {
      gl.uniform3fv(uColors, new Float32Array(palette.colors.flatMap(hex)));
    }
    useColors();
    function resize() {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const w = Math.max(1, Math.floor(canvas.clientWidth * dpr));
      const h = Math.max(1, Math.floor(canvas.clientHeight * dpr));
      if (canvas.width !== w || canvas.height !== h) {
        canvas.width = w;
        canvas.height = h;
      }
      gl.viewport(0, 0, canvas.width, canvas.height);
      gl.uniform2f(uResolution, canvas.width, canvas.height);
    }
    function draw(now) {
      const dt = now - last;
      last = now;
      if (speed !== 0) frame += dt * speed;
      resize();
      gl.uniform1f(uTime, frame * 0.001);
      gl.drawArrays(gl.TRIANGLES, 0, 3);
    }
    function loop(now) {
      draw(now);
      if (speed !== 0) requestAnimationFrame(loop);
    }
    function setSpeed(next) {
      const wasStill = speed === 0;
      speed = next;
      if (next !== 0 && wasStill) {
        last = performance.now();
        requestAnimationFrame(loop);
      } else if (next === 0) {
        draw(performance.now());
      }
    }
    window.setMeshPalette = function(name) {
      palette = palettes[name] || palettes.dark;
      frame = palette.frame;
      useColors();
      if (speed !== 0) speed = palette.speed;
      draw(performance.now());
    };
    window.setMeshActive = function(active) {
      setSpeed(active ? palette.speed : 0);
    };
    draw(performance.now());
    window.addEventListener('resize', () => draw(performance.now()));
    </script></body></html>
    """
}
