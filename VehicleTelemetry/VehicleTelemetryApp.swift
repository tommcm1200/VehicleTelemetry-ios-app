//
//  VehicleTelemetryApp.swift
//  VehicleTelemetry
//
//  Created by Tom McMeekin on 3/10/2026.
//

import SwiftUI

@main
struct VehicleTelemetryApp: App {
    // Shared with the CarPlay scene so both drive one telemetry pipeline.
    private let appState = AppEnvironment.shared.appState
    private let bluetooth = AppEnvironment.shared.bluetooth
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DashboardView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                NavigationLink {
                                    DeviceDiscoveryView()
                                } label: {
                                    Label("Discover Devices", systemImage: "antenna.radiowaves.left.and.right")
                                }
                                NavigationLink {
                                    DeviceSetupView()
                                } label: {
                                    Label("Set Up Device", systemImage: "key.fill")
                                }
                                NavigationLink {
                                    SettingsView()
                                } label: {
                                    Label("Settings", systemImage: "gearshape")
                                }
                                NavigationLink {
                                    DiagnosticsView()
                                } label: {
                                    Label("Diagnostics", systemImage: "stethoscope")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
            }
            .environment(appState)
            .environment(bluetooth)
            .onAppear {
                // Drive from a configured real BMV if set up; otherwise (DEBUG
                // only) fall back to the simulator. Idempotent: the CarPlay
                // scene may have started telemetry already.
                AppEnvironment.shared.startIfNeeded()
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active: appState.resumeTelemetry()
                case .background: appState.enterBackground()
                default: break
                }
            }
        }
    }
}
