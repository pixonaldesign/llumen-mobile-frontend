import SwiftUI

/// One idea per frame: kicker, headline, two-line takeaway, then a single hero.
struct StoryPlayer: View {
    @Environment(AppModel.self) private var model
    var route: StoryRoute
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var paused = false
    @State private var showLearnMore = false
    @State private var frameStarted = Date()

    private var frames: [StoryFrame] { StoryFrame.frames(for: route) }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Theme.spaceXL) {
                progress
                header
                Text(frames[index].takeaway)
                    .font(LumenFont.font(16))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                hero
                Button {
                    paused = true
                    showLearnMore = true
                } label: {
                    Text("Learn more")
                        .font(LumenFont.font(14, .medium))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(Theme.primary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.spaceXL)
            .padding(.bottom, Theme.spaceXL)

            HStack(spacing: 0) {
                Color.clear.contentShape(Rectangle()).onTapGesture { step(-1) }
                Color.clear.contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.15, maximumDistance: 20, pressing: { holding in
                        paused = holding
                    }, perform: {})
                    .frame(maxWidth: .infinity)
                Color.clear.contentShape(Rectangle()).onTapGesture { step(1) }
            }
            .padding(.top, 168)
            .padding(.bottom, 72)
        }
        .task(id: tickID) {
            guard !paused else { return }
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, !paused else { return }
            step(1)
        }
        .sheet(isPresented: $showLearnMore) {
            NavigationStack {
                VStack(alignment: .leading, spacing: Theme.spaceXL) {
                    Text("The full slide deck opens in landscape, read only.")
                        .font(LumenFont.font(16))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                .padding(Theme.space3XL)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.background)
                .navigationTitle("Learn more")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Close") { showLearnMore = false }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationBackground(Theme.background)
        }
        .preferredColorScheme(.dark)
    }

    private var tickID: String { "\(index)-\(paused)" }

    private var progress: some View {
        HStack(spacing: 4) {
            ForEach(frames.indices, id: \.self) { position in
                Capsule()
                    .fill(position < index ? Color.white : Color.white.opacity(0.28))
                    .overlay(alignment: .leading) {
                        if position == index {
                            TimelineView(.animation(minimumInterval: 1 / 30, paused: paused)) { context in
                                Capsule()
                                    .fill(Color.white)
                                    .scaleEffect(x: fill(at: context.date), y: 1, anchor: .leading)
                            }
                        }
                    }
                    .frame(height: 3)
            }
        }
        .padding(.top, Theme.spaceMD)
    }

    private func fill(at date: Date) -> CGFloat {
        let elapsed = date.timeIntervalSince(frameStarted)
        return min(1, max(0, elapsed / 5))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Theme.spaceLG) {
            VStack(alignment: .leading, spacing: 6) {
                Text(frames[index].kicker.uppercased())
                    .font(LumenFont.font(12, .medium))
                    .tracking(0.6)
                    .foregroundStyle(Theme.primarySoft)
                Text(frames[index].title)
                    .font(LumenFont.font(24, .semibold))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            GlassIconButton(systemName: "xmark", label: "Close briefing") {
                dismiss()
            }
        }
    }

    @ViewBuilder private var hero: some View {
        switch frames[index].hero {
        case .chart:
            ChartHero()
        case .map:
            MapHero()
        case .figure(let value, let unit):
            VStack(alignment: .leading, spacing: 8) {
                Text(value)
                    .font(LumenFont.font(48, .semibold))
                    .foregroundStyle(Theme.text)
                Text(unit)
                    .font(LumenFont.font(14, .medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.spaceXL)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        }
    }

    private func step(_ delta: Int) {
        let next = index + delta
        if next < 0 || next >= frames.count {
            dismiss()
            return
        }
        index = next
        frameStarted = Date()
    }
}

private struct StoryFrame: Identifiable {
    var id: Int
    var kicker: String
    var title: String
    var takeaway: String
    var hero: Hero

    enum Hero {
        case chart, map, figure(String, String)
    }

    static func frames(for route: StoryRoute) -> [StoryFrame] {
        if route.id == "speeds" || route.id == "x23" || route.id == "route10" {
            return [
                .init(id: 0, kicker: "Dubai Municipality", title: route.title, takeaway: "Late-night readings on this route are a local incident, not a network trend.", hero: .chart),
                .init(id: 1, kicker: "Where it happens", title: "Clustered on route X23", takeaway: "The slow points sit on one corridor, mostly between midnight and 3:00.", hero: .map),
                .init(id: 2, kicker: "What to do", title: "Treat it as a flagged incident", takeaway: "Compare tonight with the same hour last week before changing the corridor plan.", hero: .figure("11", "km/h average in the sample")),
            ]
        }
        return [
            .init(id: 0, kicker: "Briefing", title: route.title, takeaway: "A short read of the latest sample. Open Learn more for the full deck.", hero: .figure("3", "slides in this briefing")),
        ]
    }
}

private struct ChartHero: View {
    private let hours = ["04:00", "12:00", "20:00"]
    private let points: [CGFloat] = [0.55, 0.28, 0.42, 0.48, 0.62, 0.58, 0.7, 0.66, 0.22]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceLG) {
            Text("Hourly average speed")
                .font(LumenFont.font(13, .medium))
                .foregroundStyle(Theme.textSecondary)
            GeometryReader { geo in
                let step = geo.size.width / CGFloat(points.count - 1)
                ZStack(alignment: .bottomLeading) {
                    VStack {
                        ForEach(0..<4, id: \.self) { _ in
                            Spacer()
                            Rectangle().fill(Theme.border).frame(height: 1)
                        }
                    }
                    Path { path in
                        for (index, point) in points.enumerated() {
                            let p = CGPoint(x: CGFloat(index) * step, y: geo.size.height * point)
                            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
                        }
                    }
                    .stroke(Theme.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(height: 160)
            HStack {
                ForEach(hours, id: \.self) { hour in
                    Text(hour)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                    if hour != hours.last { Spacer() }
                }
            }
            HStack(spacing: 6) {
                Circle().fill(Theme.primary).frame(width: 8, height: 8)
                Text("km/h")
                    .font(LumenFont.font(12, .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(Theme.spaceXL)
        .frame(maxWidth: .infinity, alignment: .top)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }
}

private struct MapHero: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(hex: 0x12344A), Theme.background], startPoint: .top, endPoint: .bottom)
            Path { path in
                path.move(to: CGPoint(x: 30, y: 40))
                path.addCurve(to: CGPoint(x: 280, y: 180), control1: CGPoint(x: 120, y: 20), control2: CGPoint(x: 160, y: 200))
            }
            .stroke(Theme.chartTeal, lineWidth: 3)
            Text("Route X23")
                .font(LumenFont.font(13, .medium))
                .foregroundStyle(Theme.text)
                .padding(Theme.spaceLG)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }
}
