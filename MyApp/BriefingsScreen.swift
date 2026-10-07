import SwiftUI

/// Story listing from `LandingHomeDefault` `RECOMMENDED`, with the Figma story thumbs.
private struct ListedStory: Identifiable {
    enum Thumb { case map, chart, satellite }
    var id: String
    var category: String
    var title: String
    var kind: String
    var sections: String
    var thumb: Thumb
}

private enum StoryListing {
    static let recommended: [ListedStory] = [
        .init(id: "r1", category: "Engineering", title: "Building a Scalable Microservices Architecture From the Ground Up", kind: "Story", sections: "19 Sections", thumb: .map),
        .init(id: "r2", category: "Marketing", title: "Brand Repositioning Strategy for the Next-Gen Consumer Market", kind: "Story", sections: "19 Sections", thumb: .chart),
        .init(id: "r3", category: "Product", title: "User Onboarding Redesign: Reducing Time-to-Value by 40%", kind: "Story", sections: "19 Sections", thumb: .satellite),
        .init(id: "r4", category: "Sales", title: "Enterprise Pipeline Acceleration: Lessons From Q3 Wins", kind: "Story", sections: "19 Sections", thumb: .map),
        .init(id: "r5", category: "Operations", title: "Streamlining Cross-Team Workflows With Automation", kind: "Story", sections: "19 Sections", thumb: .chart),
        .init(id: "r6", category: "HR", title: "Remote Culture Playbook: Keeping Teams Connected at Scale", kind: "Story", sections: "19 Sections", thumb: .satellite),
        .init(id: "r7", category: "Customer Success", title: "Reducing Churn Through Proactive Health Scoring", kind: "Story", sections: "19 Sections", thumb: .chart),
        .init(id: "r8", category: "Finance", title: "Annual Budget Planning Framework for Hypergrowth Startups", kind: "Story", sections: "19 Sections", thumb: .map),
        .init(id: "r9", category: "IT", title: "Zero-Trust Security Rollout: A 90-Day Implementation Guide", kind: "Story", sections: "19 Sections", thumb: .satellite),
        .init(id: "r10", category: "Engineering", title: "Migrating Legacy Systems to Cloud-Native Infrastructure", kind: "Story", sections: "19 Sections", thumb: .map),
        .init(id: "r11", category: "Marketing", title: "Content-Led Growth: Driving Organic Acquisition at Scale", kind: "Story", sections: "19 Sections", thumb: .chart),
        .init(id: "r12", category: "Product", title: "Feature Prioritization With Impact vs Effort Scoring", kind: "Story", sections: "19 Sections", thumb: .satellite),
    ]
}

struct BriefingsScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        switch model.briefingMode {
        case .latest:
            ZStack(alignment: .top) {
                FeedReel()
                BriefingModeSwitcher()
                    .padding(.top, 8)
            }
        case .all:
            AllBriefingsGrid()
                .padding(.bottom, 96)
        }
    }
}

struct BriefingModeSwitcher: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 2) {
            ForEach(BriefingMode.allCases) { mode in
                let selected = model.briefingMode == mode
                Button {
                    withAnimation(Theme.motion) { model.briefingMode = mode }
                } label: {
                    Text(mode.title)
                        .font(LumenFont.font(13, .medium))
                        .foregroundStyle(selected ? Color.black : Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .frame(height: 28)
                        .background(selected ? Theme.primary : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .glassEffect(.regular, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Briefings")
    }
}

private struct AllBriefingsGrid: View {
    @Environment(AppModel.self) private var model
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer(minLength: 0)
                    BriefingModeSwitcher()
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(StoryListing.recommended) { story in
                        Button {
                            model.story = StoryRoute(id: story.id, title: story.title)
                        } label: {
                            StoryGridCard(story: story)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}

private struct StoryGridCard: View {
    var story: ListedStory

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            storyMedia
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(story.category)
                        .font(LumenFont.font(12, .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.white.opacity(0.48))
                        .lineLimit(1)
                    Text(story.title)
                        .font(LumenFont.font(18, .semibold))
                        .foregroundStyle(Color.white)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)
                }
                Text("\(story.kind) / \(story.sections)")
                    .font(LumenFont.font(12))
                    .foregroundStyle(Color.white.opacity(0.48))
                    .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.ultraThinMaterial, in: shape)
        .background(Color.black.opacity(0.56), in: shape)
        .overlay { shape.strokeBorder(Color.white.opacity(0.1), lineWidth: 1) }
        .clipShape(shape)
        .accessibilityElement(children: .combine)
    }

    private var storyMedia: some View {
        ZStack {
            Image(story.thumb == .map ? "story-thumb-map-base" : "story-thumb-chart-base")
                .resizable()
                .scaledToFill()
            if story.thumb == .map {
                Image("story-thumb-map-markers")
                    .resizable()
                    .scaledToFill()
            } else if story.thumb == .chart {
                Image("story-thumb-chart-bars")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(363.2 / 204.3, contentMode: .fill)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.55),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipped()
    }
}

// MARK: - Latest reel

private enum FeedVote: Equatable {
    case up, down
}

private struct FeedSeries: Identifiable {
    var name: String
    var value: String
    var pct: CGFloat
    var color: Color
    var id: String { name }
}

private struct FeedChart {
    var label: String
    var value: String
    var series: [FeedSeries]
}

private struct FeedStop: Identifiable {
    enum Kind { case map, chart, gradient }
    var id: String
    var kind: Kind
    var domain: String
    var title: String
    var before: String
    var highlight: String
    var after: String
    var storyId: String?
    var longitude: Double?
    var latitude: Double?
    var zoom: Double?
    var chart: FeedChart?
    var gradient: [Gradient.Stop]?
}

private enum FeedLibrary {
    static let population = FeedChart(
        label: "Population",
        value: "2,500,000",
        series: [
            .init(name: "Adults (20-59)", value: "1,700,000 (68%)", pct: 68, color: Color(hex: 0x3FA7A0)),
            .init(name: "Youth (0-19)", value: "675,000 (27%)", pct: 27, color: Color(hex: 0x9BBF6A)),
            .init(name: "Seniors (60+)", value: "125,000 (5%)", pct: 5, color: Color(hex: 0xC56B3C)),
        ]
    )

    static let landUse = FeedChart(
        label: "Land use",
        value: "100%",
        series: [
            .init(name: "Residential", value: "42%", pct: 42, color: Color(hex: 0x3FA7A0)),
            .init(name: "Industrial", value: "31%", pct: 31, color: Color(hex: 0x9BBF6A)),
            .init(name: "Open space", value: "27%", pct: 27, color: Color(hex: 0xC56B3C)),
        ]
    )

    static let stops: [FeedStop] = [
        .init(
            id: "abu-dhabi",
            kind: .map,
            domain: "Engineering",
            title: "Environmental Wellness Monitoring Checks",
            before: "There has been a noticeable rise in illegal dumping operations throughout Abu Dhabi, with reports ",
            highlight: "increasing by 35%",
            after: " compared with last week",
            storyId: "r1",
            longitude: 54.3773,
            latitude: 24.4539,
            zoom: 11.2
        ),
        .init(
            id: "proactive-ai",
            kind: .gradient,
            domain: "Customer Success",
            title: "Proactive Risk Digest",
            before: "Llumen flagged a clustered complaint pattern in MBZ City that typically precedes ",
            highlight: "service-center delays of 40 minutes",
            after: " within 72 hours",
            gradient: [
                .init(color: Color(hex: 0x757ABF), location: 0),
                .init(color: Color(hex: 0x8583BE), location: 0.6),
                .init(color: Color(hex: 0xEAB0D1), location: 1),
            ]
        ),
        .init(
            id: "population",
            kind: .chart,
            domain: "Operations",
            title: "Population composition across the capital",
            before: "Working-age residents still account for most of the emirate, while the youth share is ",
            highlight: "holding at 27%",
            after: " of the recorded population.",
            chart: population
        ),
        .init(
            id: "dubai",
            kind: .map,
            domain: "Operations",
            title: "Coastal corridor air quality",
            before: "Fine particulate readings along the coastal corridor are ",
            highlight: "up 18% overnight",
            after: ", with three districts crossing the sensitive-group threshold.",
            storyId: "r2",
            longitude: 55.2708,
            latitude: 25.2048,
            zoom: 11.35
        ),
        .init(
            id: "heat-stress",
            kind: .gradient,
            domain: "Operations",
            title: "Coastal Heat Stress Advisory",
            before: "Night-time temperatures along the corniche stayed above 32°C for a third consecutive week, with heat-related clinic visits ",
            highlight: "up 22%",
            after: " versus the seasonal baseline",
            gradient: [
                .init(color: Color(hex: 0x40405C), location: 0),
                .init(color: Color(hex: 0x6F71AA), location: 0.8),
                .init(color: Color(hex: 0x8A76AB), location: 1),
            ]
        ),
        .init(
            id: "land-use",
            kind: .chart,
            domain: "Planning",
            title: "Land use mix",
            before: "Industrial parcels now cover nearly a third of the monitored belt, ",
            highlight: "outpacing open space",
            after: " along the southern approach roads.",
            chart: landUse
        ),
        .init(
            id: "water-network",
            kind: .gradient,
            domain: "Engineering",
            title: "Water Network Pressure Review",
            before: "Several districts in Al Ain recorded overnight pressure drops that typically precede ",
            highlight: "service interruptions of 4–6 hours",
            after: " within the next 48 hours",
            gradient: [
                .init(color: Color(hex: 0x94C5F8), location: 0),
                .init(color: Color(hex: 0x8EC0E8), location: 0.25),
                .init(color: Color(hex: 0x7E9AD2), location: 0.45),
                .init(color: Color(hex: 0x6D74BC), location: 0.7),
                .init(color: Color(hex: 0x5A61AD), location: 1),
            ]
        ),
        .init(
            id: "al-ain",
            kind: .map,
            domain: "Environment",
            title: "Al Ain station cluster",
            before: "Inland stations around Al Ain show a quieter profile, with dumping reports ",
            highlight: "down 12% this week",
            after: " against the coastal belt.",
            storyId: "r4",
            longitude: 55.7447,
            latitude: 24.1917,
            zoom: 11.5
        ),
    ]

    /// Last map stop at or before the active page, matching `FeedLanding` `mapFocus`.
    static func mapFocus(at index: Int) -> (longitude: Double, latitude: Double, zoom: Double) {
        let clamped = min(max(index, 0), stops.count - 1)
        for cursor in stride(from: clamped, through: 0, by: -1) {
            let stop = stops[cursor]
            if stop.kind == .map, let longitude = stop.longitude, let latitude = stop.latitude {
                return (longitude, latitude, stop.zoom ?? 11.2)
            }
        }
        return (54.3773, 24.4539, 11.2)
    }
}

private struct FeedReel: View {
    @Environment(AppModel.self) private var model
    @State private var votes: [String: FeedVote] = [:]
    @State private var position: String?

    private var activeIndex: Int {
        guard let position, let index = FeedLibrary.stops.firstIndex(where: { $0.id == position }) else { return 0 }
        return index
    }

    var body: some View {
        let focus = FeedLibrary.mapFocus(at: activeIndex)
        let blurred = FeedLibrary.stops[activeIndex].kind == .chart
        ZStack {
            LlumenMapView(
                longitude: focus.longitude,
                latitude: focus.latitude,
                zoom: focus.zoom,
                blurred: blurred
            )
            .ignoresSafeArea()
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(FeedLibrary.stops) { stop in
                        FeedPage(
                            stop: stop,
                            vote: votes[stop.id],
                            onVote: { value in
                                votes[stop.id] = votes[stop.id] == value ? nil : value
                            }
                        )
                        .containerRelativeFrame(.vertical)
                        .id(stop.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $position)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            let index = min(max(model.feedStart, 0), FeedLibrary.stops.count - 1)
            guard index > 0 else { return }
            position = FeedLibrary.stops[index].id
        }
    }
}

private struct FeedPage: View {
    @Environment(AppModel.self) private var model
    var stop: FeedStop
    var vote: FeedVote?
    var onVote: (FeedVote) -> Void

    var body: some View {
        GeometryReader { geo in
            // Full-bleed pages report a zero bottom inset, so reserve the home
            // indicator plus the floating bar or the actions land under the capsule.
            let home = max(geo.safeAreaInsets.bottom, 34)
            let bottomPad = home + 58 + 8 + 20
            let topPad = max(geo.safeAreaInsets.top, 54) + 8
            ZStack {
                pageBackground
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.38),
                        .init(color: Color(hex: 0x050A14).opacity(0.28), location: 0.62),
                        .init(color: Color(hex: 0x050A14).opacity(0.86), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 14) {
                    if stop.kind == .chart, let chart = stop.chart {
                        Spacer(minLength: 8)
                        FeedChartCard(chart: chart)
                        Spacer(minLength: 8)
                    } else {
                        Spacer(minLength: 0)
                    }
                    copy
                        .opacity(model.findingMode == .off ? 1 : 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, topPad)
                .padding(.bottom, bottomPad)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }

    @ViewBuilder private var pageBackground: some View {
        switch stop.kind {
        case .gradient:
            if let gradient = stop.gradient {
                LinearGradient(stops: gradient, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        case .map, .chart:
            Color.clear
        }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(stop.domain)
                .font(LumenFont.font(12, .medium))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.62))
            Text(stop.title)
                .font(LumenFont.font(15, .medium))
                .foregroundStyle(Color.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
            Text(findingAttributed)
                .foregroundStyle(Color.white)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            actions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var findingAttributed: AttributedString {
        let font = Font.custom("InnovatorGrotesk-Regular", size: 20)
        var before = AttributedString(stop.before)
        var highlight = AttributedString(stop.highlight)
        var after = AttributedString(stop.after)
        before.font = font
        highlight.font = font
        highlight.underlineStyle = .single
        after.font = font
        return before + highlight + after
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            actionRow
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    tellMeMore
                    if stop.storyId != nil { openStory }
                }
                voteGroup
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            tellMeMore
            if stop.storyId != nil { openStory }
            voteGroup
        }
    }

    private var tellMeMore: some View {
        Button {
            model.attachedBriefing = stop.title
            model.chatTitle = stop.title
            model.showChat = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 16, weight: .regular))
                Text("Tell me more")
                    .font(LumenFont.font(14, .medium))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .overlay {
                Capsule().strokeBorder(Theme.textSecondary, lineWidth: 1.4)
            }
        }
        .buttonStyle(.plain)
    }

    private var openStory: some View {
        Button {
            guard let storyId = stop.storyId else { return }
            model.story = StoryRoute(id: storyId, title: stop.title)
        } label: {
            Text("Open story")
                .font(LumenFont.font(14, .medium))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .frame(height: 36)
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

    private func voteButton(_ value: FeedVote, symbol: String, label: String) -> some View {
        let selected = vote == value
        return Button {
            onVote(value)
        } label: {
            Image(systemName: selected ? "\(symbol).fill" : symbol)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.white)
                .frame(width: 36, height: 36)
                .background(selected ? Color.white.opacity(0.12) : Color.clear, in: Circle())
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct FeedChartCard: View {
    var chart: FeedChart

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(chart.label)
                .font(LumenFont.font(13))
                .foregroundStyle(Color.white.opacity(0.62))
            Text(chart.value)
                .font(LumenFont.font(34, .medium))
                .foregroundStyle(Color.white)
                .tracking(-0.8)
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(chart.series) { series in
                        series.color.frame(width: geo.size.width * series.pct / 100)
                    }
                }
            }
            .frame(height: 14)
            .clipShape(Capsule())
            VStack(alignment: .leading, spacing: 8) {
                ForEach(chart.series) { series in
                    HStack(spacing: 8) {
                        Circle().fill(series.color).frame(width: 10, height: 10)
                        Text(series.name)
                            .font(LumenFont.font(14))
                            .foregroundStyle(Color.white.opacity(0.76))
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(series.value)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.86))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: shape)
        .background(Color(hex: 0x080C14).opacity(0.72), in: shape)
        .overlay { shape.strokeBorder(Color.white.opacity(0.12), lineWidth: 1) }
    }
}

