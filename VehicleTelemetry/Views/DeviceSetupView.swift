//
//  DeviceSetupView.swift
//  VehicleTelemetry
//
//  Device Setup -> Encryption Key -> Save and Test. Shows the selected device
//  and routes to key onboarding.
//

import SwiftUI

struct DeviceSetupView: View {
    @Environment(BluetoothManager.self) private var bluetooth

    var body: some View {
        Form {
            Section("Selected device") {
                if let device = bluetooth.selectedDevice {
                    LabeledContent("Name", value: device.name ?? "Unknown")
                    LabeledContent("Victron", value: device.isVictron ? "Yes" : "No")
                    LabeledContent("Signal", value: "\(device.rssi) dBm")
                } else {
                    Text("No device selected.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                NavigationLink {
                    DeviceDiscoveryView()
                } label: {
                    Label("Discover Devices", systemImage: "antenna.radiowaves.left.and.right")
                }
                NavigationLink {
                    EncryptionKeyView()
                } label: {
                    Label("Encryption Key", systemImage: "key.fill")
                }
                .disabled(bluetooth.selectedDevice == nil)
            }
        }
        .navigationTitle("Set Up Device")
    }
}
