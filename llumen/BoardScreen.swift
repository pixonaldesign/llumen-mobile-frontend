import SwiftUI

struct BoardWidget: Identifiable, Equatable {
    var id: String
    var title: String
    var figure: String
    var unit: String
    var kind: Kind
    var size: Size
    var topic: String = "Monitoring"
    var points: [LumenPoint] = []
    var yDomain: ClosedRange<Double> = 0...1
    var yMarks: [Double] = []
    var yLabels: [String] = []
    var slices: [LumenShare] = []
    var seriesColor: Color = LumenChart.teal
    var longitude: Double = 54.3773
    var latitude: Double = 24.4539
    var zoom: Double = 11
    var pill: String? = nil
    var pillColor: Color = Theme.negative

    enum Kind: String, CaseIterable {
        case columns, area, share, donut, map
        var title: String {
            switch self {
            case .columns: "Columns"
            case .area: "Area"
            case .share: "Share"
            case .donut: "Donut"
            case .map: "Map"
            }
        }
    }

    enum Size: String, CaseIterable {
        case small, medium, large
        /// Columns on the two-up board grid.
        var columns: Int { self == .small ? 1 : 2 }
        /// Rows of the same grid. Medium is one row tall, just twice as wide.
        var rows: Int { self == .large ? 2 : 1 }
        var title: String {
            switch self {
            case .small: "Small"
            case .medium: "Medium"
            case .large: "Large"
            }
        }
        var grid: String {
            switch self {
            case .small: "1×1"
            case .medium: "2×1"
            case .large: "2×2"
            }
        }
        var icon: Phosphor {
            switch self {
            case .small: .square
            case .medium: .rectangle
            case .large: .squaresFour
            }
        }
    }

    func fresh() -> BoardWidget {
        var copy = self
        copy.id = UUID().uuidString
        return copy
    }

    func sized(_ size: Size) -> BoardWidget {
        var copy = self
        copy.size = size
        return copy
    }
}

struct BoardScreen: View {
    @Environment(AppModel.self) private var model
    @State private var widgets: [BoardWidget] = BoardLibrary.sample
    @State private var filters: [BoardFilter] = BoardFilter.sample
    @State private var cellWidth: CGFloat = 160
    @State private var resizeAnchor: CGPoint?
    @State private var resizeStart: BoardWidget.Size?

    private var activeFilters: Int { filters.filter(\.isOn).count }

    var body: some View {
        @Bindable var model = model
        ScrollView {
            BlockGrid(gap: 12) {
                ForEach(widgets) { widget in
                    widgetButton(widget)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .layoutValue(key: BlockSpan.self, value: widget.size)
                }
            }
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: CellWidthKey.self,
                        value: max((proxy.size.width - 12) / 2, 1)
                    )
                }
            }
            .onPreferenceChange(CellWidthKey.self) { cellWidth = $0 }
            .padding(.horizontal, Theme.spaceXL)
            .padding(.top, 8)
            .padding(.bottom, Theme.chromeClearance + Theme.spaceLG)
        }
        .safeAreaBar(edge: .top, spacing: 0) {
            monitorHeader
                .padding(.horizontal, Theme.spaceXL)
                .padding(.top, 4)
                .padding(.bottom, 8)
        }
        .floatingTabScrollEdge()
        .sheet(isPresented: $model.showFilters) {
            FilterSheet(filters: $filters)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.background)
        }
        .sheet(isPresented: $model.showPicker) {
            PickerSheet { template in
                widgets.append(template.fresh())
            }
            .presentationDetents([.large, .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.background)
        }
    }

    private var monitorHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Monitor")
                .font(LumenFont.font(24, .semibold))
                .foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            if !model.editingBoard {
                filterButton
            }
            editButton
        }
    }

    private var editButton: some View {
        Button {
            withAnimation(Theme.motion) { model.editingBoard.toggle() }
        } label: {
            HStack(spacing: 6) {
                PhosphorIcon(model.editingBoard ? .check : .pencilSimple, size: 15)
                Text(model.editingBoard ? "Done" : "Edit")
                    .font(LumenFont.font(14, .medium))
            }
            .foregroundStyle(model.editingBoard ? Color.black.opacity(0.9) : Theme.text)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .glassEffect(
                model.editingBoard ? .regular.tint(Theme.primary).interactive() : .regular.interactive(),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    private var filterButton: some View {
        Button { model.showFilters = true } label: {
            PhosphorIcon(.funnel, size: 16)
                .foregroundStyle(Theme.text)
                .frame(width: 36, height: 36)
                .glassEffect(.regular.interactive(), in: Circle())
                .overlay(alignment: .topTrailing) {
                    if activeFilters > 0 {
                        Text("\(activeFilters)")
                            .font(LumenFont.font(10, .semibold))
                            .foregroundStyle(Color.black.opacity(0.9))
                            .padding(.horizontal, 4)
                            .frame(minWidth: 16)
                            .frame(height: 16)
                            .background(Theme.primary, in: Capsule())
                            .offset(x: 5, y: -4)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(activeFilters == 0 ? "Filters" : "Filters, \(activeFilters) active")
    }

    private func widgetButton(_ widget: BoardWidget) -> some View {
        Button {
            guard !model.editingBoard else { return }
            if widget.kind == .map {
                model.focus = .map(widget.id)
            } else {
                model.focus = .chart(widget.id)
            }
        } label: {
            ZStack(alignment: .topLeading) {
                Group {
                    if widget.kind == .map {
                        LumenAssetFace(
                            widget: widget,
                            detailed: widget.size != .small,
                            reservesControls: model.editingBoard
                        )
                    } else {
                        GlassSurface(padding: 12) {
                            LumenAssetFace(
                                widget: widget,
                                detailed: widget.size != .small,
                                reservesControls: model.editingBoard
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .draggable(widget.id) {
                    Text(widget.title)
                        .padding()
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusUI, style: .continuous))
                }
                if model.editingBoard {
                    VStack {
                        HStack {
                            Button {
                                widgets.removeAll { $0.id == widget.id }
                            } label: {
                                PhosphorIcon(.minus, size: 12)
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Theme.negative, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(widget.title)")
                            Spacer()
                            sizeMenu(widget)
                        }
                        Spacer()
                    }
                    .padding(10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                if model.editingBoard {
                    resizeGrip
                        .highPriorityGesture(resizeGesture(widget))
                        .accessibilityLabel("Resize \(widget.title)")
                }
            }
        }
        .buttonStyle(.plain)
        .dropDestination(for: String.self) { items, _ in
            guard let source = items.first, source != widget.id,
                  let from = widgets.firstIndex(where: { $0.id == source }),
                  let to = widgets.firstIndex(where: { $0.id == widget.id }) else { return false }
            let moving = widgets.remove(at: from)
            widgets.insert(moving, at: to)
            return true
        }
    }

    private func sizeMenu(_ widget: BoardWidget) -> some View {
        Menu {
            ForEach(BoardWidget.Size.allCases, id: \.self) { option in
                Button {
                    guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
                    withAnimation(Theme.motion) { widgets[index].size = option }
                } label: {
                    if option == widget.size {
                        PhosphorMenuLabel(title: option.title, icon: .check)
                    } else {
                        PhosphorMenuLabel(title: option.title, icon: option.icon)
                    }
                }
            }
        } label: {
            PhosphorIcon(widget.size.icon, size: 13)
                .foregroundStyle(Theme.text)
                .frame(width: 28, height: 28)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Size, \(widget.size.title)")
    }

    /// iOS has no public widget-resize control, so this uses the system resize symbol on system glass.
    private var resizeGrip: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.text)
            .frame(width: 28, height: 28)
            .glassEffect(.regular.interactive(), in: Circle())
            .contentShape(Circle())
            .padding(10)
    }

    private func resizeGesture(_ widget: BoardWidget) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if resizeAnchor == nil {
                    resizeAnchor = value.startLocation
                    resizeStart = widget.size
                }
                guard let anchor = resizeAnchor, let start = resizeStart else { return }
                let translation = CGSize(
                    width: value.location.x - anchor.x,
                    height: value.location.y - anchor.y
                )
                let next = snappedSize(from: start, translation: translation)
                guard let index = widgets.firstIndex(where: { $0.id == widget.id }),
                      widgets[index].size != next else { return }
                withAnimation(.snappy(duration: 0.22)) {
                    widgets[index].size = next
                }
            }
            .onEnded { _ in
                resizeAnchor = nil
                resizeStart = nil
            }
    }

    /// Snap a corner drag to the three home-screen sizes. A tall drag becomes large, since there is no 1×2.
    private func snappedSize(from start: BoardWidget.Size, translation: CGSize) -> BoardWidget.Size {
        let cell = max(cellWidth, 1)
        let startWidth = start.columns == 2 ? cell * 2 + 12 : cell
        let startHeight = start.rows == 2 ? cell * 2 + 12 : cell
        let width = startWidth + translation.width
        let height = startHeight + translation.height
        let columns = width > cell * 1.45 ? 2 : 1
        let rows = height > cell * 1.45 ? 2 : 1
        if rows == 2 { return .large }
        if columns == 2 { return .medium }
        return .small
    }
}

private struct BlockSpan: LayoutValueKey {
    static let defaultValue: BoardWidget.Size = .small
}

private struct CellWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 160
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Two-column board. Small is one cell, medium is two cells wide and one tall, large is a 2×2 block.
private struct BlockGrid: Layout {
    var gap: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let packed = frames(width: width, subviews: subviews)
        return CGSize(width: width, height: packed.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let packed = frames(width: bounds.width, subviews: subviews)
        for (subview, frame) in zip(subviews, packed.frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func frames(width: CGFloat, subviews: Subviews) -> (frames: [CGRect], height: CGFloat) {
        let cell = max((width - gap) / 2, 0)
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview[BlockSpan.self]
            let itemWidth = size.columns == 2 ? width : cell
            let itemHeight = cell * CGFloat(size.rows) + gap * CGFloat(max(size.rows - 1, 0))
            if x > 0, x + itemWidth > width + 0.5 {
                x = 0
                y += rowHeight + gap
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: itemWidth, height: itemHeight))
            x += itemWidth + gap
            rowHeight = max(rowHeight, itemHeight)
        }
        return (frames, y + rowHeight)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach($filters) { $filter in
                        VStack(alignment: .leading, spacing: 6) {
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
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
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
    var add: (BoardWidget) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var topic = "All"
    @State private var topicsVisible = true
    @State private var didTrackScroll = false
    @State private var topicLock = Date.distantPast

    private var topics: [String] { ["All"] + BoardLibrary.topicOrder }

    private var matches: [BoardWidget] {
        BoardLibrary.catalog.filter { asset in
            let inTopic = topic == "All" || asset.topic == topic
            let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesQuery = needle.isEmpty
                || asset.title.localizedStandardContains(needle)
                || asset.topic.localizedStandardContains(needle)
            return inTopic && matchesQuery
        }
    }

    private var sections: [(String, [BoardWidget])] {
        if topic != "All" {
            return matches.isEmpty ? [] : [(topic, matches)]
        }
        return BoardLibrary.topicOrder.compactMap { name in
            let group = matches.filter { $0.topic == name }
            return group.isEmpty ? nil : (name, group)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if sections.isEmpty {
                        Text("No widgets match.")
                            .font(LumenFont.font(15))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                    } else {
                        ForEach(sections, id: \.0) { section in
                            VStack(alignment: .leading, spacing: 16) {
                                if topic == "All" {
                                    Text(section.0)
                                        .font(LumenFont.font(20, .semibold))
                                        .foregroundStyle(Theme.text)
                                }
                                ForEach(section.1) { asset in
                                    GalleryCard(asset: asset) { chosen in
                                        add(chosen)
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { previous, current in
                updateTopics(scrolled: current, delta: current - previous)
            }
            .safeAreaBar(edge: .top, spacing: 0) {
                browserBar
            }
            .background(Theme.background)
            .navigationTitle("Add asset")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var browserBar: some View {
        VStack(alignment: .leading, spacing: topicsVisible ? 12 : 0) {
            HStack(spacing: 8) {
                PhosphorIcon(.magnifyingGlass, size: 16)
                    .foregroundStyle(Theme.textTertiary)
                TextField("Search widgets", text: $query)
                    .font(LumenFont.font(16))
                    .foregroundStyle(Theme.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        PhosphorIcon(.xCircle, size: 16)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .glassEffect(.regular, in: Capsule())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topics, id: \.self) { name in
                        Button {
                            topic = name
                        } label: {
                            Text(name)
                                .font(LumenFont.font(13, .medium))
                                .foregroundStyle(topic == name ? Color.black : Theme.text)
                                .padding(.horizontal, 12)
                                .frame(height: 32)
                                .glassEffect(
                                    topic == name ? .regular.tint(Theme.primary).interactive() : .regular.interactive(),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: topicsVisible ? 32 : 0, alignment: .top)
            .clipped()
            .opacity(topicsVisible ? 1 : 0)
            .allowsHitTesting(topicsVisible)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background)
    }

    /// Topics follow the scroll: hide while moving down, bring them back while moving up or at the top.
    private func updateTopics(scrolled: CGFloat, delta: CGFloat) {
        guard didTrackScroll else {
            didTrackScroll = true
            return
        }
        guard Date.now.timeIntervalSince(topicLock) > 0.3 else { return }
        let show: Bool
        if scrolled <= 2 {
            show = true
        } else if delta > 8 {
            show = false
        } else if delta < -8 {
            show = true
        } else {
            return
        }
        guard show != topicsVisible else { return }
        topicLock = .now
        withAnimation(.snappy(duration: 0.28)) { topicsVisible = show }
    }
}

/// One widget family. Every preview opens at 2×1. Swipe for the other sizes, then tap to add that size.
private struct GalleryCard: View {
    var asset: BoardWidget
    var add: (BoardWidget) -> Void
    @State private var size: BoardWidget.Size = .medium
    @State private var width: CGFloat = 0

    private var stageHeight: CGFloat {
        canvas(width: width > 1 ? width : 320, option: size).height
    }

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                TabView(selection: $size) {
                    ForEach(BoardWidget.Size.allCases, id: \.self) { option in
                        page(option, width: geo.size.width)
                            .tag(option)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Theme.background)
            }
            .frame(height: stageHeight)
            .animation(Theme.motion, value: size)

            HStack(spacing: 6) {
                ForEach(BoardWidget.Size.allCases, id: \.self) { option in
                    Capsule()
                        .fill(option == size ? Theme.text : Theme.text.opacity(0.35))
                        .frame(width: option == size ? 14 : 6, height: 6)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(size.title)

            VStack(spacing: 2) {
                Text(asset.title)
                    .font(LumenFont.font(15, .medium))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                Text(asset.topic)
                    .font(LumenFont.font(12))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { _, new in
            width = new
        }
    }

    private func page(_ option: BoardWidget.Size, width: CGFloat) -> some View {
        let sized = asset.sized(option)
        let canvas = canvas(width: width, option: option)
        return ZStack {
            Group {
                if sized.kind == .map {
                    LumenAssetFace(
                        widget: sized,
                        detailed: option != .small,
                        reservesControls: false,
                        showsLiveMap: option == size
                    )
                } else {
                    LumenAssetFace(
                        widget: sized,
                        detailed: option != .small,
                        reservesControls: false
                    )
                    .padding(12)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
            .frame(width: canvas.width, height: canvas.height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                if sized.kind == .map {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            add(sized)
        }
        .accessibilityLabel("Add \(asset.title), \(option.title)")
        .accessibilityAddTraits(.isButton)
    }

    /// Medium is a true 2:1. Small is the square of that height, centered. Large fills the width as a square.
    private func canvas(width: CGFloat, option: BoardWidget.Size) -> CGSize {
        let available = max(width, 1)
        let row = available / 2
        switch option {
        case .small:
            return CGSize(width: row, height: row)
        case .medium:
            return CGSize(width: available, height: row)
        case .large:
            return CGSize(width: available, height: available)
        }
    }
}

enum BoardLibrary {
    static let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    static let coast = BoardWidget(
        id: "coast",
        title: "Coastal air quality",
        figure: "42",
        unit: "AQI",
        kind: .map,
        size: .medium,
        topic: "Air Quality",
        longitude: 54.51,
        latitude: 24.47,
        zoom: 10.2
    )

    static let dubai = BoardWidget(
        id: "dubai",
        title: "Dubai network",
        figure: "18",
        unit: "km/h",
        kind: .map,
        size: .small,
        topic: "Monitoring",
        longitude: 55.2708,
        latitude: 25.2048,
        zoom: 11.4
    )

    static let alAin = BoardWidget(
        id: "alain",
        title: "Areas with change signals",
        figure: "102",
        unit: "",
        kind: .map,
        size: .large,
        topic: "Monitoring",
        longitude: 55.7606,
        latitude: 24.2075,
        zoom: 11.6
    )

    static let groundwater = BoardWidget(
        id: "groundwater",
        title: "Total groundwater abstraction",
        figure: "120K",
        unit: "m³",
        kind: .columns,
        size: .medium,
        topic: "Water",
        points: zip(months, [38, 44, 70, 99, 91, 74, 59, 72, 65, 76, 89, 110]).map { LumenPoint(label: $0.0, value: Double($0.1)) },
        yDomain: 0...150,
        yMarks: [0, 50, 100, 150],
        yLabels: ["0", "50K", "100K", "150K"],
        seriesColor: LumenChart.teal
    )

    static let depletion = BoardWidget(
        id: "depletion",
        title: "Groundwater depletion rate",
        figure: "0.32",
        unit: "m",
        kind: .area,
        size: .small,
        topic: "Water",
        points: zip(months, [0.04, 0.05, 0.09, 0.14, 0.20, 0.24, 0.18, 0.22, 0.17, 0.20, 0.28, 0.42]).map { LumenPoint(label: $0.0, value: $0.1) },
        yDomain: 0...0.5,
        yMarks: [0, 0.5],
        yLabels: ["0", "0.5"],
        seriesColor: LumenChart.crimson
    )

    static let enforcement = BoardWidget(
        id: "enforcement",
        title: "Active enforcement cases",
        figure: "84",
        unit: "",
        kind: .share,
        size: .medium,
        topic: "Monitoring",
        slices: [
            .init(name: "Under investigation", fraction: 0.47, detail: "40 (47%)", color: LumenChart.teal),
            .init(name: "Notice issued", fraction: 0.35, detail: "30 (35%)", color: LumenChart.olive),
            .init(name: "Pending court", fraction: 0.18, detail: "14 (18%)", color: LumenChart.amber),
        ]
    )

    static let recharge = BoardWidget(
        id: "recharge",
        title: "Abstraction vs recharge ratio",
        figure: "24:1",
        unit: "",
        kind: .share,
        size: .medium,
        topic: "Water",
        slices: [
            .init(name: "Abstraction", fraction: 0.96, detail: "120K m³", color: LumenChart.coral),
            .init(name: "Recharge", fraction: 0.04, detail: "5k m³", color: LumenChart.teal),
        ],
        pill: "Severe deficit",
        pillColor: LumenChart.crimson
    )

    static let patrol = BoardWidget(
        id: "patrol",
        title: "Patrol coverage",
        figure: "",
        unit: "",
        kind: .donut,
        size: .medium,
        topic: "Monitoring",
        slices: [
            .init(name: "Patrolled", fraction: 0.67, detail: "67%", color: LumenChart.mint),
            .init(name: "Unpatrolled", fraction: 0.33, detail: "33%", color: LumenChart.slate),
        ]
    )

    static let aqiTrend = BoardWidget(
        id: "aqi-trend",
        title: "Coastal AQI trend",
        figure: "42",
        unit: "AQI",
        kind: .area,
        size: .medium,
        topic: "Air Quality",
        points: zip(months, [28, 31, 36, 44, 52, 61, 58, 49, 42, 38, 34, 30]).map { LumenPoint(label: $0.0, value: Double($0.1)) },
        yDomain: 0...80,
        yMarks: [0, 40, 80],
        yLabels: ["0", "40", "80"],
        seriesColor: LumenChart.teal
    )

    static let gulf = BoardWidget(
        id: "gulf",
        title: "Arabian Gulf habitats",
        figure: "18",
        unit: "sites",
        kind: .map,
        size: .medium,
        topic: "Marine Life",
        longitude: 52.6,
        latitude: 25.2,
        zoom: 7.2
    )

    static let coral = BoardWidget(
        id: "coral",
        title: "Coral cover",
        figure: "",
        unit: "",
        kind: .donut,
        size: .small,
        topic: "Marine Life",
        slices: [
            .init(name: "Live coral", fraction: 0.46, detail: "46%", color: LumenChart.teal),
            .init(name: "Algae", fraction: 0.32, detail: "32%", color: LumenChart.olive),
            .init(name: "Rubble", fraction: 0.22, detail: "22%", color: LumenChart.slate),
        ]
    )

    static let landings = BoardWidget(
        id: "landings",
        title: "Fish landings",
        figure: "64K",
        unit: "t",
        kind: .columns,
        size: .medium,
        topic: "Marine Life",
        points: zip(months, [4.2, 3.8, 5.1, 6.4, 8.8, 11.2, 10.4, 9.1, 7.6, 6.2, 5.4, 4.8]).map { LumenPoint(label: $0.0, value: $0.1) },
        yDomain: 0...12,
        yMarks: [0, 6, 12],
        yLabels: ["0", "6K", "12K"],
        seriesColor: LumenChart.categorical[0]
    )

    static let topicOrder = ["Air Quality", "Monitoring", "Marine Life", "Water"]
    static let sample: [BoardWidget] = [coast, depletion, dubai, groundwater, enforcement, alAin]
    static let catalog: [BoardWidget] = [
        coast, aqiTrend,
        dubai, alAin, enforcement, patrol,
        gulf, coral, landings,
        groundwater, depletion, recharge,
    ]
}
