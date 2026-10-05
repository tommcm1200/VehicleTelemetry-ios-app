//
//  DeviceDiscoveryView.swift
//  VehicleTelemetry
//
//  Lists BLE devices seen while scanning. Devices are never auto-selected;
//  selection is always an explicit user action.
//

import SwiftUI
import Combine
import CoreBluetooth

struct DeviceDiscoveryView: View {
    @Environment(BluetoothManager.self) private var bluetooth

    @State private var now = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var sortedDevices: [DiscoveredDevice] {
        bluetooth.devices.sorted { lhs, rhs in
            if lhs.isVictron != rhs.isVictron { return lhs.isVictron }
            return lhs.rssi > rhs.rssi
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label(bluetooth.stateDescription, systemImage: "dot.radiowaves.left.and.right")
                    Spacer()
                    if bluetooth.isScanning {
                        ProgressView()
                    }
                }
                .font(.subheadline)
            }

            if bluetooth.state != .poweredOn {
                Section {
                    Text("Bluetooth is \(bluetooth.stateDescription.lowercased()). Enable Bluetooth to scan for devices.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Devices (\(sortedDevices.count))") {
                ForEach(sortedDevices) { device in
                    deviceRow(device)
                }
            }
        }
        .navigationTitle("Discover")
        .onAppear { bluetooth.startScanning() }
        .onDisappear { bluetooth.stopScanning() }
        .onReceive(tick) { now = $0 }
    }

    @ViewBuilder
    private func deviceRow(_ device: DiscoveredDevice) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(device.name ?? "Unknown device")
                    .font(.headline)
                Spacer()
                if device.isVictron {
                    Text("Victron")
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.blue.opacity(0.15), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }

            Text(device.id.uuidString)
                .font(.caption2).monospaced()
                .foregroundStyle(.secondary)
                .lineLimit(1).truncationMode(.middle)

            HStack(spacing: 12) {
                Label("\(device.rssi) dBm", systemImage: "antenna.radiowaves.left.and.right")
                Label(device.hasManufacturerData ? "Mfr data" : "No mfr data",
                      systemImage: device.hasManufacturerData ? "shippingbox" : "shippingbox.slash")
                Spacer()
                Text(TelemetryFormatting.shortAge(since: device.lastSeen, now: now))
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                if bluetooth.selectedDeviceID == device.id {
                    Label("Selected", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                } else {
                    Button("Select") { bluetooth.select(device.id) }
                        .font(.caption).buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
