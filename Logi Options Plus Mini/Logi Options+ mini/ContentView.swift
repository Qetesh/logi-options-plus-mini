import SwiftUI
import Sparkle
import SwiftGlass

struct ContentView: View {
    @State private var selectedFeature: FeatureList? = .logiOptionsPlusInstaller
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @StateObject private var installerController = InstallerController()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    List(selection: $selectedFeature) {
                        ForEach(FeatureList.allCases, id: \.self) { feature in
                            NavigationLink(value: feature) {
                                HStack(alignment: .center, spacing: 10) {
                                    Image(feature.iconName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(feature.displayName)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text(feature.description)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .background(VisualEffectView().ignoresSafeArea())
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFeature = nil
                    }
                    .frame(minWidth: 260)
                    .navigationTitle("Features")
                    .toolbar(removing: .sidebarToggle)
                } detail: {
                    if selectedFeature == .logiOptionsPlusInstaller {
                        LogiOptionsPlusView(controller: installerController)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("Select a feature")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        sidebarToggleButton
                    }
                    
                    ToolbarItem {
                        settingsButton
                    }
                }
                
                BottomStatusBar()
            }
            .background(VisualEffectView().ignoresSafeArea())
        }
        .frame(minWidth: 850, minHeight: 552)
    }
    
    private func toggleSidebar() {
        withAnimation {
            columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
        }
    }
    
    private var sidebarIconName: String {
        columnVisibility == .detailOnly ? "sidebar.leading" : "sidebar.trailing"
    }
    
    @ViewBuilder
    private var sidebarToggleButton: some View {
        Button {
            toggleSidebar()
        } label: {
            Label("Toggle Sidebar", systemImage: sidebarIconName)
        }
        .help("Toggle Sidebar")
        .glass(
            material: .regularMaterial,
            gradientOpacity: 0.7,
            shadowRadius: 10
        )
    }
    
    @ViewBuilder
    private var settingsButton: some View {
        SettingsLink(label: {
            Label("Preferences", systemImage: "gearshape")
        })
        .help("Preferences")
        .glass(
            material: .regularMaterial,
            gradientOpacity: 0.7,
            shadowRadius: 10
        )
    }
}


#Preview {
    ContentView()
        .environmentObject(LogStore())
}
