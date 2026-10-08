import SwiftUI

struct ContentView: View {
    @State private var selectedTab: CaosTab = .aim
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
    @State private var enabledPatchFiles: Set<String> = []

    private let patches: [CaosPatch] = [
        CaosPatch(fileName: "xTop1 External File (1).3105", name: "AIM HEAD", description: "CAOS X • AIM HEAD", icon: "scope"),
        CaosPatch(fileName: "xTop1 External File (2).3105", name: "AIM CHEST", description: "CAOS X • AIM CHEST", icon: "scope"),
        CaosPatch(fileName: "xTop1 External File (3).3105", name: "AIM DRAG + ANTENNA", description: "CAOS X • AIM DRAG COMBO", icon: "scope"),
        CaosPatch(fileName: "xTop1 External File (4).3105", name: "AIM HEAD + ANTENNA", description: "CAOS X • AIM HEAD COMBO", icon: "scope"),
        CaosPatch(fileName: "xTop1 External File (5).3105", name: "MAGIC BULLET + ANTENNA", description: "CAOS X • MAGIC COMBO", icon: "sparkles"),
        CaosPatch(fileName: "xTop1 External File (6).3105", name: "AIM DRAG", description: "CAOS X • AIM DRAG", icon: "scope"),
        CaosPatch(fileName: "xTop1 External File (7).3105", name: "AIM NECK", description: "CAOS X • AIM NECK", icon: "scope"),
        CaosPatch(fileName: "xTop1 External File (8).3105", name: "ANTENNA", description: "CAOS X • ANTENNA", icon: "antenna.radiowaves.left.and.right"),
        CaosPatch(fileName: "xTop1 External File (9).3105", name: "OBB", description: "CAOS X • OBB MODULE", icon: "cube"),
        CaosPatch(fileName: "xTop1 External File (10).3105", name: "144 FPS", description: "CAOS X • PERFORMANCE", icon: "speedometer"),
        CaosPatch(fileName: "xTop1 External File (11).3105", name: "AIM HEAD + BODY", description: "CAOS X • AIM COMBO", icon: "scope"),
        CaosPatch(fileName: "xTop1 External File (12).3105", name: "AIM BODY", description: "CAOS X • AIM BODY", icon: "scope"),
        CaosPatch(fileName: "xTop1 External File (13).3105", name: "AIM CHEST + BODY", description: "CAOS X • AIM COMBO", icon: "scope"),
        CaosPatch(fileName: "xTop1 External File (14).3105", name: "MAGIC BULLET", description: "CAOS X • MAGIC BULLET", icon: "sparkles")
    ]

    private var resources: [String] { patches.map(\.name) }

    var body: some View {
        ZStack {
            CaosBackground()
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
            CaosTopBar(title: "CAOS X")
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
                        Text("SYNCING CAOS X MODULES")
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
            Text("SECURE RESOURCE CHANNEL • CAOS X")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.35))
                .padding(.bottom, 24)
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            CaosTopBar(title: selectedTab.title)
                .padding(.horizontal, 12)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    identityCard
                    injectStatusCard
                    selectedContent
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CaosTabBar(selected: $selectedTab)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial.opacity(0.92))
        }
    }

    private var identityCard: some View {
        HStack(spacing: 12) {
            AppLogo(size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("CAOS X")
                    .font(.system(size: 20, weight: .black, design: .rounded))
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
        .padding(16)
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
        case .menu:
            emptyContent(title: "MENU", subtitle: "CAOS X MENU MODULES", message: "NO MENU MODULES — ADD FILES FROM CAOS X")
        case .hologram:
            emptyContent(title: "HOLOGRAM", subtitle: "REMOTE HOLOGRAM PATCHES", message: "NO HOLOGRAM PATCHES — ADD FILES FROM CAOS X")
        case .skin:
            emptyContent(title: "SKIN MOD", subtitle: "REMOTE SKIN PATCHES", message: "NO SKIN MOD PATCHES — ADD FILES FROM CAOS X")
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
                ForEach(patches) { patch in
                    patchRow(patch, isOn: Binding(
                        get: { enabledPatchFiles.contains(patch.fileName) },
                        set: { enabled in
                            if enabled { enabledPatchFiles.insert(patch.fileName) }
                            else { enabledPatchFiles.remove(patch.fileName) }
                        }
                    ))
                    if patch.id != patches.last?.id {
                        Divider().overlay(Color.white.opacity(0.06))
                    }
                }
                Text("ONE ACTIVE FEATURE AT A TIME")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.secondaryAccent.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.accent.opacity(0.24), lineWidth: 1))
        }
    }

    private func emptyContent(title: String, subtitle: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryCard(title: title, subtitle: subtitle, icon: title == "MENU" ? "list.bullet.rectangle" : "sparkles")
            VStack(spacing: 18) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                Text(message)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.56))
                Button {
                    activateSection(title)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "power")
                        Text("ACTIVATE \(title)")
                    }
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: AppTheme.accent.opacity(0.30), radius: 14, y: 7)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(Color.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AppTheme.accent.opacity(0.28), lineWidth: 1))
            Spacer(minLength: 160)
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
                    Text("CAOS X • LOCAL LIBRARY")
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
            .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.44))
            }
            Spacer()
        }
        .padding(18)
        .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(AppTheme.accent.opacity(0.25), lineWidth: 1))
    }

    private func activateSection(_ title: String) {
        processingPatch = title
        patchMessage = "PROCESSING — \(title)"
    }

    private func patchRow(_ patch: CaosPatch, isOn: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                isOn.wrappedValue.toggle()
                processingPatch = isOn.wrappedValue ? patch.name : nil
                patchMessage = isOn.wrappedValue ? "PROCESSING — \(patch.name)" : "READY — SELECT A PATCH"
            }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: patch.icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(isOn.wrappedValue ? AppTheme.accent : .white.opacity(0.42))
                    .frame(width: 25)
                VStack(alignment: .leading, spacing: 3) {
                    Text(patch.name)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                    Text(patch.description)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
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

private struct CaosPatch: Identifiable, Hashable {
    let fileName: String
    let name: String
    let description: String
    let icon: String

    var id: String { fileName }
}

enum CaosTab: String, CaseIterable, Identifiable {
    case aim = "AIM"
    case menu = "MENU"
    case hologram = "HOLOGRAM"
    case skin = "SKIN MOD"
    case files = "FILE STATUS"

    var id: String { rawValue }
    var title: String { rawValue }
    var icon: String {
        switch self {
        case .aim: return "scope"
        case .menu: return "list.bullet.rectangle"
        case .hologram: return "sparkles"
        case .skin: return "tshirt.fill"
        case .files: return "folder.fill"
        }
    }
}

private struct CaosTopBar: View {
    let title: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CAOS X")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(AppTheme.accent)
            }
            Spacer()
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white)
            Spacer()
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

private struct CaosTabBar: View {
    @Binding var selected: CaosTab

    var body: some View {
        HStack(spacing: 2) {
            ForEach(CaosTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.20)) { selected = tab }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .bold))
                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(0.35)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(selected == tab ? AppTheme.accent : .white.opacity(0.42))
                    .frame(maxWidth: .infinity, minHeight: 62)
                    .background(selected == tab ? AppTheme.accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CaosBackground: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.34, green: 0.008, blue: 0.008),
                        Color(red: 0.12, green: 0.004, blue: 0.004),
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
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(x: animate ? -90 : 90, y: proxy.size.height * 0.28)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
        }
    }
}

// Compatibility wrapper for existing onboarding/license screens in the project.
struct AnimatedHyperBackdrop: View {
    var body: some View {
        CaosBackground()
    }
}

private struct CaosGrid: View {
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
