import SwiftUI

struct FocusScreen: View {
    @Environment(\.dismiss) private var dismiss
    var focus: BoardFocus
    @State private var style = "Aimsun Base"
    @State private var showInfo = false

    private let styles = ["Default", "Aimsun Base", "Satellite"]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            switch focus {
            case .map:
                map
            case .chart:
                chart
            }
        }
    }

    private var map: some View {
        ZStack(alignment: .top) {
            MapSketchFull()
                .ignoresSafeArea()
            VStack(spacing: Theme.spaceLG) {
                HStack(spacing: Theme.spaceMD) {
                    GlassIconButton(icon: .x, label: "Close map") { dismiss() }
                    Spacer()
                    Menu {
                        ForEach(styles, id: \.self) { name in
                            Button(name) { style = name }
                        }
                    } label: {
                        Text(style)
                            .font(LumenFont.font(13, .medium))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .glassEffect(.regular.interactive(), in: Capsule())
                    }
                    GlassIconButton(icon: .info, label: "About this map") { showInfo.toggle() }
                }
                if showInfo {
                    Text("Average speed on the coastal network. Darker teal is slower traffic.")
                        .font(LumenFont.font(14))
                        .foregroundStyle(Theme.text)
                        .padding(Theme.spaceXL)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Average speed")
                        .font(LumenFont.font(13, .medium))
                        .foregroundStyle(Theme.text)
                    HStack {
                        Text("Low 11 km/h")
                        Spacer()
                        Text("High 28 km/h")
                    }
                    .font(LumenFont.font(12))
                    .foregroundStyle(Theme.textSecondary)
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.chartTeal.opacity(0.3), Theme.chartTeal], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 8)
                }
                .padding(Theme.spaceXL)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
            }
            .padding(.horizontal, Theme.spaceXL)
            .padding(.bottom, Theme.spaceXL)
        }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: Theme.spaceXL) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shared housing violations")
                        .font(LumenFont.font(20, .medium))
                        .foregroundStyle(Theme.text)
                    Text("Share of inspected homes")
                        .font(LumenFont.font(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                GlassIconButton(icon: .x, label: "Close chart") { dismiss() }
            }
            LumenHBarChart(
                rows: [
                    .init(name: "Al Muraqqabat", fraction: 0.92, valueLabel: "54.5%"),
                    .init(name: "Al Twar Fifth", fraction: 0.84, valueLabel: "51.6%"),
                    .init(name: "Al Nahda Second", fraction: 0.78, valueLabel: "50%"),
                    .init(name: "Umm Hurair Second", fraction: 0.70, valueLabel: "46.2%"),
                    .init(name: "Al Quasis Second", fraction: 0.64, valueLabel: "44.4%"),
                ],
                barHeight: 10,
                nameWidth: 132,
                labelSize: 13,
                spacing: 12
            )
            .padding(Theme.spaceXL)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(LumenChart.series)
                    .frame(width: 8, height: 8)
                Text("Violation share")
                    .font(LumenFont.font(12, .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text("Al Muraqqabat has the highest share in this sample. The other districts sit close behind, so the gap is narrow.")
                .font(LumenFont.font(14))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(Theme.spaceXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background)
    }

}

private struct MapSketchFull: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x071018), Color(hex: 0x14384A), Color(hex: 0x071018)], startPoint: .top, endPoint: .bottom)
            Path { path in
                path.move(to: CGPoint(x: 40, y: 180))
                path.addCurve(to: CGPoint(x: 320, y: 420), control1: CGPoint(x: 140, y: 80), control2: CGPoint(x: 200, y: 500))
                path.move(to: CGPoint(x: 20, y: 360))
                path.addLine(to: CGPoint(x: 360, y: 240))
            }
            .stroke(Theme.chartTeal.opacity(0.9), lineWidth: 4)
        }
    }
}
