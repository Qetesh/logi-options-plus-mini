import SwiftUI
import SwiftGlass

struct LogiOptionsPlusView: View {
    @EnvironmentObject var logStore: LogStore
    @State private var isLoading: Bool = false
    @State private var isUninstalling: Bool = false
    @State private var isFixing: Bool = false
    @State private var showOfflineInstallConfirmation: Bool = false
    @State private var showFixConfirmation: Bool = false
    @State private var updateTextIsLoading: Bool = false
    @State private var installedVersionUpdateLoading: Bool = false
    @ObservedObject var controller: InstallerController
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURL
    @State private var logiOptionsPlusLatestVersion: String = ""
    @State private var isFeatureListHovered: Bool = false

    init(controller: InstallerController) {
        self.controller = controller
    }
    
    func fetchLatestVersion() async {
        self.logiOptionsPlusLatestVersion = await getLogiOptionsPlusLatestVersion()
    }
    
    @ViewBuilder
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack(alignment: .leading, spacing: 10) {
                Text("Select the features to install:")
                    .font(.headline)
                
                List {
                    ForEach(controller.features, id: \.self) { feature in
                        HStack {
                            Toggle(feature.description, isOn: Binding(
                                get: { controller.selectedFeatures.contains(feature) },
                                set: { isSelected in
                                    if isSelected {
                                        controller.selectedFeatures.insert(feature)
                                    } else {
                                        controller.selectedFeatures.remove(feature)
                                    }
                                    controller.saveSelectedFeatures()
                                }
                            ))
                            .disabled(controller.unsupportedFeatures.contains(feature))
                            .foregroundStyle(controller.unsupportedFeatures.contains(feature) ? .secondary : .primary)
                        }
                        // Keep the tooltip on an enabled container so unavailable toggles still explain why.
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .help(controller.helpText(for: feature))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(.thinMaterial)
                .frame(minHeight: 320, maxHeight: .infinity)
                .cornerRadius(10)
                .glass(
                    radius: 10,
                    color: .gray
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFeatureListHovered ? Color.accentColor.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(isFeatureListHovered ? 1.002 : 1.0, anchor: .top)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isFeatureListHovered)
                .onHover { hovering in
                    isFeatureListHovered = hovering
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Logi Options+ installed version: \(installedVersionUpdateLoading ? "Updating..." : controller.installedVersion)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .onTapGesture {
                                if !installedVersionUpdateLoading {
                                    Task {
                                        installedVersionUpdateLoading = true
                                        try? await Task.sleep(nanoseconds: 100_000_000)
                                        controller.updateInstalledVersion()
                                        installedVersionUpdateLoading = false
                                    }
                                }
                            }
                        if self.logiOptionsPlusLatestVersion != "" && self.logiOptionsPlusLatestVersion != "Unknown" {
                                                    
                            Text("Logi Options+ latest stable version: \(self.logiOptionsPlusLatestVersion)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .onTapGesture {
                                    if !updateTextIsLoading {
                                        Task {
                                            updateTextIsLoading = true
                                            self.logiOptionsPlusLatestVersion = "Updating..."
                                            await fetchLatestVersion()
                                            updateTextIsLoading = false
                                        }
                                    }
                                }
                        }
                    }
                        
                    Spacer()
                    HStack(spacing: 0) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.5)
                            } else {
                                Button(action: {
                                    Task {
                                        isLoading = true
                                        await controller.install()
                                        isLoading = false
                                    }
                                }) {
                                    Text("Install/Reinstall")
                                        .font(.headline)
                                }
                                .buttonStyle(.borderedProminent)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                                .glass(
                                    radius: 20,
                                    color: .blue,
                                    material: .regularMaterial,
                                    gradientOpacity: 0.7,
                                    shadowColor: .blue,
                                    shadowRadius: 10
                                )
                                .disabled(isUninstalling || isFixing)
                            }
                        }
                        .frame(width: 140, height: 20)

                        ZStack {
                            if isFixing || isUninstalling {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.5)
                            } else {
                                let isDisabled = isLoading || isUninstalling
                                let toolButtonBaseColor = Color(red: 0.56, green: 0.56, blue: 0.58)
                                let buttonColor: Color = isDisabled ? toolButtonBaseColor.opacity(0.4) : toolButtonBaseColor
                                
                                Menu {
                                    Button(role: .destructive) {
                                        Task {
                                            isUninstalling = true
                                            await controller.uninstall()
                                            isUninstalling = false
                                        }
                                    } label: {
                                        Label(String(localized: "Uninstall"), systemImage: "trash")
                                    }

                                    Divider()

                                    Button {
                                        showOfflineInstallConfirmation = true
                                    } label: {
                                        Label(String(localized: "Offline Install/Reinstall"), systemImage: "square.and.arrow.down")
                                    }

                                    Divider()

                                    Button {
                                        showFixConfirmation = true
                                    } label: {
                                        Label(String(localized: "Fix Certificate Issue"), systemImage: "checkmark.seal")
                                    }
                                    
                                    Button {
                                        Task {
                                            isFixing = true
                                            await controller.scanJavaScriptErrorFiles()
                                            isFixing = false
                                        }
                                    } label: {
                                        Label(String(localized: "Fix JavaScript Error"), systemImage: "exclamationmark.triangle")
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(String(localized: "More"))
                                            .font(.headline)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .frame(height: 23)
                                    .background {
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(buttonColor)
                                    }
                                }
                                .menuStyle(.button)
                                .menuIndicator(.hidden)
                                .buttonStyle(.plain)
                                .glass(
                                    radius: 20,
                                    color: buttonColor,
                                    colorOpacity: isDisabled ? 0.12 : 0.3,
                                    material: .regularMaterial,
                                    gradientOpacity: isDisabled ? 0.45 : 1.0,
                                    shadowColor: buttonColor,
                                    shadowOpacity: isDisabled ? 0.55 : 0.9,
                                    shadowRadius: isDisabled ? 7 : 14
                                )
                                .disabled(isDisabled)
                                .confirmationDialog(
                                    String(localized: "Install Offline Package?"),
                                    isPresented: $showOfflineInstallConfirmation
                                ) {
                                    Button(String(localized: "Continue")) {
                                        Task {
                                            isLoading = true
                                            await controller.installOffline()
                                            isLoading = false
                                        }
                                    }
                                    Button(String(localized: "Cancel"), role: .cancel) { }
                                } message: {
                                    Text("The offline installer is larger than 1.3 GB and may not contain the latest version. However, it can repair some installation or application errors.\n\nDo you want to continue?")
                                }
                                .confirmationDialog(String(localized: "Run Fix Tool"), isPresented: $showFixConfirmation) {
                                    Button(String(localized: "Confirm")) {
                                        Task {
                                            isFixing = true
                                            await controller.fix()
                                            isFixing = false
                                        }
                                    }
                                    Button(String(localized: "View Details")) {
                                        openURL(URL(string: "https://support.logi.com/hc/zh-cn/articles/37493733117847-Options-and-G-HUB-macOS-Certificate-Issue")!)
                                    }
                                    Button(String(localized: "Cancel"), role: .cancel) { }
                                } message: {
                                    Text("The fix operation launches the official repair tool to resolve startup issues.\n\nDetail:\n https://support.logi.com/hc/zh-cn/articles/37493733117847-Options-and-G-HUB-macOS-Certificate-Issue")
                                }
                                .confirmationDialog(String(localized: "Confirm Delete Files"), isPresented: $controller.showDeleteFilesConfirmation) {
                                    Button(String(localized: "Delete"), role: .destructive) {
                                        Task {
                                            isFixing = true
                                            await controller.confirmDeleteFiles()
                                            isFixing = false
                                        }
                                    }
                                    Button(String(localized: "View Details")) {
                                        openURL(URL(string: "https://support.logi.com/hc/zh-cn/articles/37493733117847-Options-and-G-HUB-macOS-Certificate-Issue")!)
                                    }
                                    Button(String(localized: "Cancel"), role: .cancel) {
                                        controller.filesToDelete = []
                                    }
                                } message: {
                                    Text("The following \(controller.filesToDelete.count) file(s) will be deleted:\n\n\(controller.filesToDelete.map { $0.lastPathComponent }.joined(separator: "\n"))\n\nThese corrupted config backup files may cause JavaScript errors in Logi Options+.")
                                }
                                .confirmationDialog(String(localized: "Fix JavaScript Error"), isPresented: $controller.showNoFilesToDeleteAlert) {
                                    Button(String(localized: "View Details")) {
                                        openURL(URL(string: "https://support.logi.com/hc/zh-cn/articles/37493733117847-Options-and-G-HUB-macOS-Certificate-Issue")!)
                                    }
                                    Button(String(localized: "OK"), role: .cancel) { }
                                } message: {
                                    Text("No corrupted config backup files found.\n\nIf you're still experiencing JavaScript errors, please visit the official support page for more solutions.")
                                }
                            }
                        }
                        .frame(width: 80, height: 20)
                        .padding(.leading, 8)
                    }
                }
                
                Divider()
                
                // Installation progress indicator - always visible, click to toggle activity log drawer
                InstallationProgressView(controller: controller, showActivityLog: $controller.showActivityLog)
            }
            .padding()
            .zIndex(0)
            
            // Activity log backdrop (kept alive to avoid disappearing before drawer removal finishes)
            Color.black
                .opacity(controller.showActivityLog ? 0.3 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(controller.showActivityLog)
                .onTapGesture {
                    guard controller.showActivityLog else { return }
                    withAnimation(.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.24)) {
                        controller.showActivityLog = false
                    }
                }
                .animation(.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.32), value: controller.showActivityLog)
                .zIndex(10)

            // Activity log drawer overlay
            if controller.showActivityLog {
                // Drawer panel
                ActivityLogDrawerView(
                    logStore: logStore,
                    colorScheme: colorScheme,
                    showActivityLog: $controller.showActivityLog
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom)
                            .combined(with: .scale(scale: 0.92, anchor: .bottom))
                    )
                )
                .zIndex(20)
            }
        }
        .frame(minWidth: 600, minHeight: 460, maxHeight: .infinity)
        .task {
            controller.loadSelectedFeatures()
            await fetchLatestVersion()
        }
    }
}

/// Activity log drawer view
struct ActivityLogDrawerView: View {
    @ObservedObject var logStore: LogStore
    let colorScheme: ColorScheme
    @Binding var showActivityLog: Bool
    
    @State private var isHoveringHandle: Bool = false
    @State private var dragOffsetY: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Drawer handle - tap to close
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(isHoveringHandle ? Color.primary.opacity(0.6) : Color.secondary.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .scaleEffect(isHoveringHandle ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isHoveringHandle)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHoveringHandle = hovering
            }
            .onTapGesture {
                withAnimation(.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.24)) {
                    showActivityLog = false
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        dragOffsetY = max(0, value.translation.height)
                    }
                    .onEnded { value in
                        if value.translation.height > 0 {
                            withAnimation(.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.24)) {
                                dragOffsetY = 0
                                showActivityLog = false
                            }
                        } else {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                dragOffsetY = 0
                            }
                        }
                    }
            )
            .help(String(localized: "Click to close"))
            
            // Header - tap "Activity Log" to clear
            HStack {
                Button(action: {
                    logStore.clearMessages()
                }) {
                    Text("Activity Log")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .help(String(localized: "Click to clear log"))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider()
            
            // Log content
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 2) {
                        ForEach(logStore.messages) { message in
                            Text(message.content)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                .font(.system(size: 12, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 2)
                        }
                    }
                    .id("scrollId")
                    .onChange(of: logStore.messages) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("scrollId", anchor: .bottom)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: 200)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .offset(y: dragOffsetY)
    }
}

struct LogiOptionsPlusViewWrapper: View {
    @StateObject private var logStore = LogStore()
    var body: some View {
        LogiOptionsPlusView(controller: InstallerController())
            .environmentObject(logStore)
    }
}

#Preview{
    LogiOptionsPlusViewWrapper()
}
