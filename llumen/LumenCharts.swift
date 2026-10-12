import Charts
import SwiftUI

struct LumenAxisTick: Identifiable {
    var index: Int
    var label: String
    var id: Int { index }
}

/// Evenly spaced ticks. Callers drop down a count until the gaps are wide enough to read.
func lumenAxisTicks(_ labels: [String], maximum: Int) -> [LumenAxisTick] {
    guard !labels.isEmpty else { return [] }
    let last = labels.count - 1
    let count = min(max(maximum, 1), labels.count)
    if last == 0 || count == 1 {
        return [LumenAxisTick(index: 0, label: labels[0])]
    }
    var ticks: [LumenAxisTick] = []
    for step in 0..<count {
        let index = Int((Double(step) * Double(last) / Double(count - 1)).rounded())
        if ticks.last?.index == index { continue }
        ticks.append(LumenAxisTick(index: index, label: labels[index]))
    }
    return ticks
}

/// Series colors from the Lumen asset-builder palettes (categorical, refract, and the Dust ramp).
enum LumenChart {
    static let categorical: [Color] = [
        Color(hex: 0x6A9EF0),
        Color(hex: 0x7B6FE8),
        Color(hex: 0x3EC4B8),
        Color(hex: 0x59C96A),
        Color(hex: 0xF0A830),
        Color(hex: 0xF06840),
        Color(hex: 0xD45090),
        Color(hex: 0xE85868),
    ]
    static var series: Color { categorical[0] }

    static let teal = Color(hex: 0x2EC4B6)
    static let olive = Color(hex: 0xA4B86A)
    static let mint = Color(hex: 0x3EBE8A)
    static let slate = Color(hex: 0x7E8DA3)
    static let coral = Color(hex: 0xE3945A)
    static let amber = Color(hex: 0xE08A3C)
    static let crimson = Color(hex: 0xE15B78)
    static let axis = Color.primary.opacity(0.5)
    static let grid = Color.primary.opacity(0.16)
    static let track = Color.primary.opacity(0.14)
}

struct LumenPoint: Identifiable, Equatable {
    var label: String
    var value: Double
    var id: String { label }
}

struct LumenShare: Identifiable, Equatable {
    var name: String
    var fraction: CGFloat
    var detail: String
    var color: Color
    var id: String { name }
}

struct LumenBarRow: Identifiable {
    var name: String
    var fraction: CGFloat
    var valueLabel: String? = nil
    var id: String { name }
}

/// Column chart: top-rounded bars, hairline grid, 10pt axis labels.
struct LumenColumnChart: View {
    var points: [LumenPoint]
    var yDomain: ClosedRange<Double>
    var yMarks: [Double]
    var yLabels: [String]
    var color: Color
    var showsLabels: Bool

    var body: some View {
        LumenChartFrame(
            points: points,
            yDomain: yDomain,
            yMarks: yMarks,
            yLabels: yLabels,
            showsLabels: showsLabels
        ) {
            Chart(points) { point in
                BarMark(
                    x: .value("Month", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(color)
                .cornerRadius(3)
            }
            .chartYScale(domain: yDomain)
            .chartPlotStyle { plot in
                plot.background(Color.clear)
            }
        }
    }
}

/// Area chart: smooth line, gradient fill, same axis chrome as the columns.
struct LumenTrendChart: View {
    var points: [LumenPoint]
    var yDomain: ClosedRange<Double>
    var yMarks: [Double]
    var yLabels: [String]
    var color: Color
    var showsLabels: Bool

    var body: some View {
        LumenChartFrame(
            points: points,
            yDomain: yDomain,
            yMarks: yMarks,
            yLabels: yLabels,
            showsLabels: showsLabels
        ) {
            Chart(points) { point in
                AreaMark(
                    x: .value("Month", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.55), color.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                LineMark(
                    x: .value("Month", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            }
            .chartYScale(domain: yDomain)
            .chartPlotStyle { plot in
                plot.background(Color.clear)
            }
        }
    }
}

/// Y labels sit in their own gutter, month labels sit on a row under the plot.
/// Each row keeps only as many ticks as fit, so nothing stacks on the line or on its neighbor.
private struct LumenChartFrame<Plot: View>: View {
    var points: [LumenPoint]
    var yDomain: ClosedRange<Double>
    var yMarks: [Double]
    var yLabels: [String]
    var showsLabels: Bool
    @ViewBuilder var plot: () -> Plot

    var body: some View {
        VStack(spacing: 4) {
            plot()
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
                .chartLegend(.hidden)
                .overlay { gridlines }
                .overlay { axisOverlay }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            xLabels
                .frame(height: 14)
        }
        .accessibilityHidden(true)
    }

    private var axisOverlay: some View {
        GeometryReader { geo in
            let marks = fittedY(height: geo.size.height)
            let span = max(yDomain.upperBound - yDomain.lowerBound, 0.0001)
            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                let t = (mark.value - yDomain.lowerBound) / span
                let raw = geo.size.height * (1 - CGFloat(t))
                let y = min(max(raw, 7), max(geo.size.height - 7, 7))
                Text(mark.label)
                    .font(LumenFont.font(10))
                    .foregroundStyle(LumenChart.axis)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .position(x: geo.size.width / 2, y: y)
            }
        }
        .allowsHitTesting(false)
    }

    private var xLabels: some View {
        GeometryReader { geo in
            let ticks = fittedX(width: geo.size.width)
            let last = max(points.count - 1, 1)
            ForEach(ticks) { tick in
                let t = CGFloat(tick.index) / CGFloat(last)
                let inset: CGFloat = 12
                let span = max(geo.size.width - inset * 2, 1)
                Text(tick.label)
                    .font(LumenFont.font(10))
                    .foregroundStyle(LumenChart.axis)
                    .lineLimit(1)
                    .fixedSize()
                    .position(x: inset + span * t, y: geo.size.height / 2)
            }
        }
    }

    private var gridlines: some View {
        Canvas { context, size in
            let marks = fittedY(height: size.height)
            let span = max(yDomain.upperBound - yDomain.lowerBound, 0.0001)
            for mark in marks {
                let t = (mark.value - yDomain.lowerBound) / span
                let y = size.height * (1 - CGFloat(t))
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(LumenChart.grid), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }

    private func fittedX(width: CGFloat) -> [LumenAxisTick] {
        let labels = points.map(\.label)
        let preferred = showsLabels ? 4 : 2
        for count in stride(from: preferred, through: 2, by: -1) {
            let ticks = lumenAxisTicks(labels, maximum: count)
            guard ticks.count >= 2 else { return ticks }
            if width / CGFloat(ticks.count - 1) >= 36 { return ticks }
        }
        return lumenAxisTicks(labels, maximum: 2)
    }

    private func fittedY(height: CGFloat) -> [(value: Double, label: String)] {
        let pairs = Array(zip(yMarks, yLabels)).map { (value: $0.0, label: $0.1) }
        guard pairs.count > 2 else { return pairs }
        let room = max(2, Int(height / 18))
        guard pairs.count > room else { return pairs }
        let kept = min(room, pairs.count)
        var chosen: [(value: Double, label: String)] = []
        let last = pairs.count - 1
        for step in 0..<kept {
            let index = Int((Double(step) * Double(last) / Double(kept - 1)).rounded())
            let pair = pairs[index]
            if chosen.last?.label == pair.label { continue }
            chosen.append(pair)
        }
        return chosen
    }
}

struct LumenShareBar: View {
    var slices: [LumenShare]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let gap: CGFloat = 4
                let gaps = CGFloat(max(slices.count - 1, 0)) * gap
                let usable = max(geo.size.width - gaps, 0)
                HStack(spacing: gap) {
                    ForEach(slices) { slice in
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(slice.color)
                            .frame(width: max(6, usable * slice.fraction))
                    }
                }
            }
            .frame(height: 16)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(slices) { slice in
                    HStack(spacing: 6) {
                        Circle().fill(slice.color).frame(width: 8, height: 8)
                        Text(slice.name)
                            .font(LumenFont.font(12))
                            .foregroundStyle(Theme.text.opacity(0.85))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(slice.detail)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(Theme.text.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct LumenRingChart: View {
    var slices: [LumenShare]
    var diameter: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(slices) { slice in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Circle().fill(slice.color).frame(width: 8, height: 8)
                            Text(slice.name)
                                .font(LumenFont.font(12))
                                .foregroundStyle(Theme.text.opacity(0.85))
                                .lineLimit(1)
                        }
                        Text(slice.detail)
                            .font(LumenFont.font(12))
                            .foregroundStyle(Theme.text.opacity(0.7))
                            .padding(.leading, 14)
                    }
                }
            }
            Spacer(minLength: 0)
            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Share", Double(slice.fraction)),
                    innerRadius: .ratio(0.64),
                    angularInset: 2
                )
                .foregroundStyle(slice.color)
            }
            .chartLegend(.hidden)
            .frame(width: diameter, height: diameter)
        }
    }
}

struct LumenAssetFace: View {
    var widget: BoardWidget
    var detailed: Bool
    var reservesControls: Bool
    /// Gallery pages that are off-screen skip the live map.
    var showsLiveMap: Bool = true

    var body: some View {
        if widget.kind == .map {
            mapFace
        } else {
            chartFace
        }
    }

    /// The map is the widget. The figure sits on top of it, with no inner frame.
    private var mapFace: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if showsLiveMap {
                    LlumenMapView(
                        longitude: widget.longitude,
                        latitude: widget.latitude,
                        zoom: widget.zoom,
                        blurred: false
                    )
                } else {
                    Theme.surfaceDeep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.black.opacity(0)],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 4) {
                titleRow
                figureRow
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var chartFace: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleRow
            figureRow
            if let pill = widget.pill {
                Text(pill)
                    .font(LumenFont.font(11, .medium))
                    .foregroundStyle(widget.pillColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay {
                        Capsule().strokeBorder(widget.pillColor, lineWidth: 1)
                    }
            }
            chart
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var chart: some View {
        switch widget.kind {
        case .columns:
            LumenColumnChart(
                points: widget.points,
                yDomain: widget.yDomain,
                yMarks: widget.yMarks,
                yLabels: widget.yLabels,
                color: widget.seriesColor,
                showsLabels: detailed
            )
        case .area:
            LumenTrendChart(
                points: widget.points,
                yDomain: widget.yDomain,
                yMarks: widget.yMarks,
                yLabels: widget.yLabels,
                color: widget.seriesColor,
                showsLabels: detailed
            )
        case .share:
            LumenShareBar(slices: widget.slices)
        case .donut:
            LumenRingChart(slices: widget.slices, diameter: detailed ? 112 : 72)
        case .map:
            EmptyView()
        }
    }

    private var titleRow: some View {
        HStack(spacing: 8) {
            if reservesControls {
                Color.clear.frame(width: 22, height: 22)
            }
            Text(widget.title)
                .font(LumenFont.font(14))
                .foregroundStyle(widget.kind == .map ? Color.white : Theme.text.opacity(0.7))
                .shadow(color: .black.opacity(widget.kind == .map ? 0.45 : 0), radius: 8, y: 2)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            if reservesControls {
                Color.clear.frame(width: 28, height: 22)
            }
        }
    }

    @ViewBuilder private var figureRow: some View {
        if !widget.figure.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(widget.figure)
                    .font(.system(size: detailed ? 32 : 22, weight: .medium, design: .monospaced))
                    .foregroundStyle(widget.kind == .map ? Color.white : Theme.text)
                    .shadow(color: .black.opacity(widget.kind == .map ? 0.45 : 0), radius: 8, y: 2)
                if !widget.unit.isEmpty {
                    Text(widget.unit)
                        .font(LumenFont.font(detailed ? 20 : 14))
                        .foregroundStyle(widget.kind == .map ? Color.white.opacity(0.7) : Theme.text.opacity(0.7))
                }
            }
        }
    }
}

/// Horizontal bars used by the focused housing chart.
struct LumenHBarChart: View {
    var rows: [LumenBarRow]
    var color: Color = LumenChart.series
    var barHeight: CGFloat = 8
    var nameWidth: CGFloat = 88
    var labelSize: CGFloat = 11
    var spacing: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(rows) { row in
                HStack(spacing: 6) {
                    Text(row.name)
                        .font(LumenFont.font(labelSize, .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: nameWidth, alignment: .leading)
                        .lineLimit(1)
                    GeometryReader { geo in
                        let width = max(barHeight, geo.size.width * min(max(row.fraction, 0), 1))
                        ZStack(alignment: .leading) {
                            Capsule().fill(LumenChart.track)
                            Capsule()
                                .fill(color.opacity(0.92))
                                .frame(width: width)
                        }
                    }
                    .frame(height: barHeight)
                    if let valueLabel = row.valueLabel {
                        Text(valueLabel)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.text)
                            .frame(width: 48, alignment: .trailing)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
