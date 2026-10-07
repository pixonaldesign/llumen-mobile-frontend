import SwiftUI

struct BoardWidget: Identifiable, Equatable {
    var id: String
    var title: String
    var figure: String
    var caption: String
    var kind: Kind
    var size: Size

    enum Kind { case map, bars, donut, kpi }
    enum Size: String, CaseIterable { case s, m, l
        var next: Size {
            switch self {
            case .s: .m
            case .m: .l
            case .l: .s
            }
        }
        var title: String { rawValue.uppercased() }
    }
}

struct BoardScreen: View {
    @Environment(AppModel.self) private var model
    @State private var widgets: [BoardWidget] = BoardWidget.sample
    @State private var filters: [BoardFilter] = BoardFilter.sample

    private var activeFilters: Int { filters.filter(\.isOn).count }

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spaceLG) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Board")
                            .font(LumenFont.font(24, .semibold))
                            .foregroundStyle(Theme.text)
                        Text("\(widgets.count) widgets")
                            .font(LumenFont.font(13))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Button {
                        withAnimation(Theme.motion) { model.editingBoard.toggle() }
                    } label: {
                        Text(model.editingBoard ? "Done" : "Edit")
                            .font(LumenFont.font(14, .medium))
                            .foregroundStyle(model.editingBoard ? Color.black : Theme.text)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(model.editingBoard ? Theme.primary : Theme.fillQuiet, in: Capsule())
                            .overlay {
                                Capsule().strokeBorder(model.editingBoard ? Theme.primary : Theme.border, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }

                if model.editingBoard {
                    Text("Drag a widget to reorder. Remove and size sit inside the card, clear of the chart.")
                        .font(LumenFont.font(13))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button { model.showFilters = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text(activeFilters == 0 ? "Filters" : "Filters · \(activeFilters)")
                    }
                    .font(LumenFont.font(13, .medium))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .glassEffect(
                        activeFilters > 0 ? .regular.tint(Theme.primary.opacity(0.35)).interactive() : .regular.interactive(),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(widgets) { widget in
                        widgetButton(widget)
                    }
                }

                if model.editingBoard {
                    Button { model.showPicker = true } label: {
                        Text("Add widget")
                            .font(LumenFont.font(14, .medium))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Theme.primary, in: RoundedRectangle(cornerRadius: Theme.radiusUI, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.spaceXL)
            .padding(.bottom, Theme.chromeClearance + Theme.spaceLG)
        }
        .sheet(isPresented: $model.showFilters) {
            FilterSheet(filters: $filters)
                .presentationDetents([.medium])
                .presentationBackground(Theme.background)
        }
        .sheet(isPresented: $model.showPicker) {
            PickerSheet { kind in
                widgets.append(BoardWidget.make(kind))
            }
            .presentationDetents([.medium])
            .presentationBackground(Theme.background)
        }
    }

    private func widgetButton(_ widget: BoardWidget) -> some View {
        Button {
            guard !model.editingBoard else { return }
            switch widget.kind {
            case .map: model.focus = .map(widget.id)
            case .bars, .donut, .kpi: model.focus = .chart(widget.id)
            }
        } label: {
            GlassSurface(padding: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        if model.editingBoard {
                            Button {
                                widgets.removeAll { $0.id == widget.id }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Theme.negative, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(widget.title)")
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(widget.title)
                                .font(LumenFont.font(13, .medium))
                                .foregroundStyle(Theme.text)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            Text(widget.figure)
                                .font(LumenFont.font(20, .semibold))
                                .foregroundStyle(Theme.text)
                        }
                        Spacer(minLength: 4)
                        if model.editingBoard {
                            Button {
                                guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
                                widgets[index].size = widgets[index].size.next
                            } label: {
                                Text(widget.size.title)
                                    .font(LumenFont.font(11, .semibold))
                                    .foregroundStyle(Theme.text)
                                    .frame(width: 26, height: 26)
                                    .background(Theme.fillQuiet, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Size \(widget.size.title)")
                        }
                    }
                    widgetBody(widget)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .clipped()
                    Text(widget.caption)
                        .font(LumenFont.font(12))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(height: 188)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        }
        .buttonStyle(.plain)
        .draggable(widget.id) {
            Text(widget.title).padding().background(.ultraThinMaterial)
        }
        .dropDestination(for: String.self) { items, _ in
            guard let source = items.first, source != widget.id,
                  let from = widgets.firstIndex(where: { $0.id == source }),
                  let to = widgets.firstIndex(where: { $0.id == widget.id }) else { return false }
            let moving = widgets.remove(at: from)
            widgets.insert(moving, at: to)
            return true
        }
    }

    @ViewBuilder private func widgetBody(_ widget: BoardWidget) -> some View {
        switch widget.kind {
        case .map:
            MapSketch(tint: Theme.chartTeal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        case .bars:
            VStack(spacing: 6) {
                bar("Al Muraqqabat", 0.92)
                bar("Al Twar Fifth", 0.84)
                bar("Al Nahda", 0.7)
            }
        case .donut:
            HStack(spacing: 8) {
                DonutMark()
                VStack(alignment: .leading, spacing: 4) {
                    legend("Etihad Airways", Theme.primary)
                    legend("Wizz Air", Theme.chartViolet)
                    legend("Air Arabia", Theme.chartPink)
                }
                Spacer(minLength: 0)
            }
        case .kpi:
            EmptyView()
        }
    }

    private func bar(_ name: String, _ value: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .font(LumenFont.font(11))
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 88, alignment: .leading)
                .lineLimit(1)
            GeometryReader { geo in
                Capsule().fill(Theme.negative.opacity(0.85))
                    .frame(width: geo.size.width * value, height: 6)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 10)
        }
    }

    private func legend(_ name: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(name)
                .font(LumenFont.font(11))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
    }
}

struct BoardFilter: Identifiable {
    var id: String
    var title: String
    var value: String
    var isOn: Bool

    static let sample: [BoardFilter] = [
        .init(id: "date", title: "Date", value: "1 Sep 2026 – 17 Sep 2026", isOn: true),
        .init(id: "aqi", title: "AQI timeseries", value: "All stations", isOn: true),
        .init(id: "riyadh", title: "Riyadh traffic timeseries", value: "Citywide", isOn: false),
    ]
}

private struct FilterSheet: View {
    @Binding var filters: [BoardFilter]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach($filters) { $filter in
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(isOn: $filter.isOn) {
                            Text(filter.title)
                                .font(LumenFont.font(16, .medium))
                        }
                        .tint(Theme.primary)
                        Text(filter.value)
                            .font(LumenFont.font(13))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .listRowBackground(Theme.neutral800)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") { filters.indices.forEach { filters[$0].isOn = false } }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct PickerSheet: View {
    var add: (BoardWidget.Kind) -> Void
    @Environment(\.dismiss) private var dismiss

    private let options: [(String, String, BoardWidget.Kind)] = [
        ("Passenger share", "Pie chart", .donut),
        ("Housing violation rate", "Bar chart", .bars),
        ("Sensor occupancy", "Points map", .map),
        ("Areas with change signals", "Score", .kpi),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(options, id: \.0) { option in
                    Button {
                        add(option.2)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.0)
                                .font(LumenFont.font(16, .medium))
                                .foregroundStyle(Theme.text)
                            Text(option.1)
                                .font(LumenFont.font(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .listRowBackground(Theme.neutral800)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Add widget")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MapSketch: View {
    var tint: Color
    var body: some View {
        ZStack {
            LinearGradient(colors: [tint.opacity(0.45), Theme.background], startPoint: .topLeading, endPoint: .bottomTrailing)
            Path { path in
                path.move(to: CGPoint(x: 8, y: 20))
                path.addCurve(to: CGPoint(x: 140, y: 56), control1: CGPoint(x: 40, y: 4), control2: CGPoint(x: 80, y: 70))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
        }
    }
}

private struct DonutMark: View {
    var body: some View {
        ZStack {
            Circle().trim(from: 0, to: 0.67).stroke(Theme.primary, style: StrokeStyle(lineWidth: 8, lineCap: .butt)).rotationEffect(.degrees(-90))
            Circle().trim(from: 0.67, to: 0.82).stroke(Theme.chartViolet, style: StrokeStyle(lineWidth: 8, lineCap: .butt)).rotationEffect(.degrees(-90))
            Circle().trim(from: 0.82, to: 1).stroke(Theme.chartPink, style: StrokeStyle(lineWidth: 8, lineCap: .butt)).rotationEffect(.degrees(-90))
        }
        .frame(width: 44, height: 44)
    }
}

extension BoardWidget {
    static let sample: [BoardWidget] = [
        .init(id: "coast", title: "Coastal air quality", figure: "42 AQI", caption: "Abu Dhabi coast · last hour", kind: .map, size: .s),
        .init(id: "network", title: "Dubai network", figure: "18 km/h", caption: "Mean speed · city center", kind: .map, size: .s),
        .init(id: "housing", title: "Shared housing violations", figure: "54.5%", caption: "Highest share is Al Muraqqabat", kind: .bars, size: .l),
        .init(id: "airline", title: "Passenger share by airline", figure: "66.97%", caption: "Etihad leads Abu Dhabi departures", kind: .donut, size: .l),
    ]

    static func make(_ kind: Kind) -> BoardWidget {
        switch kind {
        case .map: .init(id: UUID().uuidString, title: "Sensor occupancy", figure: "71%", caption: "Points map · live sensors", kind: .map, size: .s)
        case .bars: .init(id: UUID().uuidString, title: "Housing violation rate", figure: "48%", caption: "Bar chart · districts", kind: .bars, size: .l)
        case .donut: .init(id: UUID().uuidString, title: "Passenger share", figure: "66.97%", caption: "Pie chart · airlines", kind: .donut, size: .l)
        case .kpi: .init(id: UUID().uuidString, title: "Areas with change signals", figure: "102", caption: "Places that need a second look", kind: .kpi, size: .s)
        }
    }
}
