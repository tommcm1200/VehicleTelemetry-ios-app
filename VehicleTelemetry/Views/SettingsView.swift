//
//  SettingsView.swift
//  VehicleTelemetry
//
//  Manage the configured BMV: change device, change key, view diagnostics, and
//  forget the device (which clears the Keychain key and remembered device).
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(BluetoothManager.self) private var bluetooth

    @State private var showForgetConfirm = false

    private var hasStoredKey: Bool {
        guard let config = DeviceConfiguration.load() else { return false }
        return SecureKeyStore().hasKey(for: config.deviceID.uuidString)
    }

    var body: some View {
        Form {
            Section("Device") {
                LabeledContent("Configured BMV", value: appState.configuredDeviceName ?? "None")
                LabeledContent("Encryption key", value: hasStoredKey ? "Stored" : "Not set")
                LabeledContent("Bluetooth", value: bluetooth.stateDescription)
            }

            Section {
                NavigationLink {
                    DeviceDiscoveryView()
                } label: {
                    Label("Change BMV", systemImage: "antenna.radiowaves.left.and.right")
                }
                NavigationLink {
                    EncryptionKeyView()
                } label: {
                    Label("Change Encryption Key", systemImage: "key.fill")
                }
                NavigationLink {
                    DiagnosticsView()
                } label: {
                    Label("Diagnostics", systemImage: "stethoscope")
                }
            }

            Section {
                Button(role: .destructive) {
                    showForgetConfirm = true
                } label: {
                    Label("Forget BMV", systemImage: "trash")
                }
            } footer: {
                Text("Removes the stored encryption key, the remembered device, and the shared widget snapshot from this iPhone.")
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Forget this BMV?", isPresented: $showForgetConfirm, titleVisibility: .visible) {
            Button("Forget BMV", role: .destructive) { appState.forgetDevice() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need the encryption key from VictronConnect again to reconnect.")
        }
    }
}
