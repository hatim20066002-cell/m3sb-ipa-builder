import SwiftUI

struct ContentView: View {
    @State private var selectedTab: VesperTab = .aim
    @State private var isLoading = true
    @State private var completedResources = 0
    @State private var patchMessage = "READY — SELECT A PATCH"
    @State private var processingPatch: String?
    @State private var keepPatchActive = true
    @State private var aimHead = false
    @State private var aimDrag = false
    @State private var aimBody = false
    @State private var magicBullet = false
    @State private var aimDragAntenna = false
    @State private var aimHeadAntenna = false
    @State private var magicAntenna = false
    @State private var fps144 = false

    private let resources = [
        "AIM HEAD", "AIM DRAG", "AIM BODY", "MAGIC BULET",
        "AIM DRAG + ANTENA", "AIM HEAD + ANTENA", "MAGIC BULET + ANTENA", "144 FPS", "AIM BODY"
    ]

    var body: some View {
        ZStack {
            VesperBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                        .transition(.opacity)
                } else {
                    mainView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await runResourceLoading() }
    }

    private var loadingView: some View {
        VStack(spacing: 0) {
            VesperTopBar(title: "VESPER EXTERNAL")
                .padding(.horizontal, 18)
                .padding(.top, 12)

            Spacer(minLength: 38)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("DOWNLOAD RESOURCE FROM SERVER")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(.white)
                        Text("SYNCING VESPERDASH MODULES")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    Spacer()
                    Text("\(completedResources)/\(resources.count)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                }

                ProgressView(value: Double(completedResources), total: Double(resources.count))
                    .tint(AppTheme.accent)
                    .scaleEffect(x: 1, y: 1.8, anchor: .center)

                VStack(spacing: 0) {
                    ForEach(Array(resources.enumerated()), id: \.offset) { index, resource in
                        ResourceRow(name: resource, completed: index < completedResources)
                        if index < resources.count - 1 {
                            Divider().overlay(Color.white.opacity(0.06))
                        }
                    }
                }
                .padding(.vertical, 6)
                .background(AppTheme.referenceCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.accent.opacity(0.28), lineWidth: 1))
            }
            .padding(18)
            .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AppTheme.accent.opacity(0.40), lineWidth: 1))
            .padding(.horizontal, 18)

            Spacer()
            Text("SECURE RESOURCE CHANNEL • VESPERDASH")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.35))
                .padding(.bottom, 24)
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            VesperTopBar(title: selectedTab.title)
                .padding(.horizontal, 18)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    identityCard
                    injectStatusCard
                    selectedContent
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 14)
            }

            VesperTabBar(selected: $selectedTab)
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial.opacity(0.92))
        }
    }

    private var identityCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AppTheme.accent.opacity(0.20))
                Image(systemName: "bolt.horizontal.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text("VESPER EXTERNAL")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(1.7)
                    .foregroundStyle(.white)
                Text("PATCH CONTROL CENTER")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(14)
        .background(AppTheme.referenceCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AppTheme.accent.opacity(0.42), lineWidth: 1))
        .shadow(color: AppTheme.accent.opacity(0.18), radius: 16)
    }

    private var injectStatusCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(processingPatch == nil ? AppTheme.accent : .orange)
                .frame(width: 9, height: 9)
                .shadow(color: processingPatch == nil ? AppTheme.accent : .orange, radius: 7)
            VStack(alignment: .leading, spacing: 3) {
                Text("INJECT STATUS")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.accent)
                Text(patchMessage)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            Spacer()
            Text(processingPatch == nil ? "READY" : "RUNNING")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(processingPatch == nil ? .green : .orange)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.accent.opacity(0.24), lineWidth: 1))
        .animation(.easeInOut(duration: 0.22), value: patchMessage)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .aim:
            aimContent
        case .esp:
            emptyContent(title: "ESP", subtitle: "REMOTE ESP PATCHES", message: "NO ESP PATCHES — ADD FILES FROM VESPERDASH")
        case .hologram:
            emptyContent(title: "HOLOGRAM", subtitle: "REMOTE HOLOGRAM PATCHES", message: "NO HOLOGRAM PATCHES — ADD FILES FROM VESPERDASH")
        case .skin:
            emptyContent(title: "SKIN MOD", subtitle: "REMOTE SKIN PATCHES", message: "NO SKIN MOD PATCHES — ADD FILES FROM VESPERDASH")
        case .files:
            fileStatusContent
        }
    }

    private var aimContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            categoryCard(title: "AIM", subtitle: "REMOTE AIM PATCHES", icon: "scope")
            HStack {
                Label("FF NORMAL", systemImage: "bolt.fill")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Text("SELECT PATCH")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(.horizontal, 4)
            VStack(spacing: 0) {
                patchRow("AIM HEAD", description: "FREE FIRE • NORMAL", icon: "scope", isOn: $aimHead)
                patchRow("AIM DRAG", description: "FREE FIRE • NORMAL", icon: "arrow.up.right", isOn: $aimDrag)
                patchRow("AIM BODY", description: "FREE FIRE • NORMAL", icon: "figure.stand", isOn: $aimBody)
                patchRow("MAGIC BULET", description: "FREE FIRE • NORMAL", icon: "wand.and.stars", isOn: $magicBullet)
                patchRow("AIM DRAG + ANTENA", description: "FREE FIRE • NORMAL", icon: "antenna.radiowaves.left.and.right", isOn: $aimDragAntenna)
                patchRow("AIM HEAD + ANTENA", description: "FREE FIRE • NORMAL", icon: "dot.radiowaves.left.and.right", isOn: $aimHeadAntenna)
                patchRow("MAGIC BULET + ANTENA", description: "FREE FIRE • NORMAL", icon: "sparkles", isOn: $magicAntenna)
                patchRow("144 FPS", description: "FREE FIRE • NORMAL", icon: "speedometer", isOn: $fps144)
            }
            .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.accent.opacity(0.24), lineWidth: 1))
        }
    }

    private func emptyContent(title: String, subtitle: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryCard(title: title, subtitle: subtitle, icon: title == "ESP" ? "eye" : "sparkles")
            Text(message)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(.white.opacity(0.42))
                .padding(.horizontal, 6)
            Spacer(minLength: 280)
        }
    }

    private var fileStatusContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("PATCH FILES")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.white)
                    Text("VESPERDASH • LOCAL LIBRARY")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.42))
                }
                Spacer()
                Toggle("", isOn: $keepPatchActive)
                    .labelsHidden()
                    .tint(AppTheme.accent)
            }
            .padding(14)
            .background(AppTheme.referenceCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.accent.opacity(0.30), lineWidth: 1))

            Text("KEEP PATCH ACTIVE AFTER EXIT")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.52))
                .padding(.horizontal, 5)

            VStack(spacing: 0) {
                ForEach(Array(resources.enumerated()), id: \.offset) { index, resource in
                    FileStatusRow(index: index + 1, name: resource)
                    if index < resources.count - 1 {
                        Divider().overlay(Color.white.opacity(0.06))
                    }
                }
            }
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.accent.opacity(0.22), lineWidth: 1))
        }
    }

    private func categoryCard(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 11) {
            ZStack {
                Circle().fill(AppTheme.accent.opacity(0.18))
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.44))
            }
            Spacer()
        }
        .padding(13)
        .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(AppTheme.accent.opacity(0.25), lineWidth: 1))
    }

    private func patchRow(_ name: String, description: String, icon: String, isOn: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                isOn.wrappedValue.toggle()
                processingPatch = isOn.wrappedValue ? name : nil
                patchMessage = isOn.wrappedValue ? "PROCESSING — \(name)" : "READY — SELECT A PATCH"
            }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isOn.wrappedValue ? AppTheme.accent : .white.opacity(0.42))
                    .frame(width: 25)
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(.white.opacity(0.38))
                }
                Spacer()
                Text(isOn.wrappedValue ? "ON" : "OFF")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(isOn.wrappedValue ? AppTheme.accent : .white.opacity(0.36))
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(AppTheme.accent)
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func runResourceLoading() async {
        guard isLoading else { return }
        for index in 1...resources.count {
            try? await Task.sleep(nanoseconds: 380_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.18)) {
                    completedResources = index
                }
            }
        }
        try? await Task.sleep(nanoseconds: 350_000_000)
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.35)) {
                isLoading = false
            }
        }
    }
}

enum VesperTab: String, CaseIterable, Identifiable {
    case aim = "AIM"
    case esp = "ESP"
    case hologram = "HOLOGRAM"
    case skin = "SKIN MOD"
    case files = "FILE STATUS"

    var id: String { rawValue }
    var title: String { rawValue }
    var icon: String {
        switch self {
        case .aim: return "scope"
        case .esp: return "eye"
        case .hologram: return "sparkles"
        case .skin: return "tshirt.fill"
        case .files: return "folder.fill"
        }
    }
}

private struct VesperTopBar: View {
    let title: String

    var body: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "ellipsis")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AppTheme.accent)
        }
        .frame(height: 42)
    }
}

private struct ResourceRow: View {
    let name: String
    let completed: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(completed ? .green : AppTheme.accent.opacity(0.7))
            Text(name)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(completed ? .white : .white.opacity(0.56))
            Spacer()
            if completed {
                Text("SYNCED")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(.green.opacity(0.85))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .animation(.easeInOut(duration: 0.2), value: completed)
    }
}

private struct FileStatusRow: View {
    let index: Int
    let name: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("#\(index) • AIM • NORMAL")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
            }
            Spacer()
            Text("SAFE")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 11)
    }
}

private struct VesperTabBar: View {
    @Binding var selected: VesperTab

    var body: some View {
        HStack(spacing: 2) {
            ForEach(VesperTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.20)) { selected = tab }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .bold))
                        Text(tab.rawValue)
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .tracking(0.35)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(selected == tab ? AppTheme.accent : .white.opacity(0.42))
                    .frame(maxWidth: .infinity, minHeight: 45)
                    .background(selected == tab ? AppTheme.accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct VesperBackground: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.025, blue: 0.34),
                        Color(red: 0.075, green: 0.008, blue: 0.13),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Circle()
                    .fill(AppTheme.accent.opacity(0.18))
                    .frame(width: 290, height: 290)
                    .blur(radius: 70)
                    .offset(x: animate ? 110 : -100, y: -proxy.size.height * 0.36)
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(x: animate ? -90 : 90, y: proxy.size.height * 0.28)
                VesperGrid()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
        }
    }
}

private struct VesperGrid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            stride(from: 0, through: size.width, by: 34).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: 0, through: size.height, by: 34).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(AppTheme.accent.opacity(0.035)), lineWidth: 0.7)
        }
        .allowsHitTesting(false)
    }
}
