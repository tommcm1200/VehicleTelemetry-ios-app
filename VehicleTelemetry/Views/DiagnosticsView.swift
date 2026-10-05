//
//  DiagnosticsView.swift
//  VehicleTelemetry
//
//  BLE and telemetry diagnostics for field debugging. Encryption keys are never
//  shown here. Raw manufacturer data (public broadcast, not secret) is viewable
//  and copyable only in DEBUG builds.
//

import SwiftUI
import UIKit
import Combine

struct DiagnosticsView: View {
    @Environment(BluetoothManager.self) private var bluetooth

    @State private var now = Date()
    @State private var didCopy = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var decoded: BatteryState? {
        guard let device = bluetooth.selectedDevice else { return nil }
        return VictronLiveDecoder().decodeLatest(for: device)
    }

    private var recordTypeDescription: String {
        guard let data = bluetooth.selectedDevice?.manufacturerData,
              let record = VictronInstantReadoutRecord.parse(manufacturerData: data) else {
            return "—"
        }
        return record.deviceType?.displayName
            ?? String(format: "Unknown (0x%02X)", record.deviceTypeRaw)
    }

    var body: some View {
        List {
            Section("Bluetooth") {
                row("State", bluetooth.stateDescription)
                row("Scanning", bluetooth.isScanning ? "Yes" : "No")
            }

            Section("Advertisements") {
                row("Received", "\(bluetooth.advertisementsReceived)")
                row("Victron identified", "\(bluetooth.victronAdvertisementsIdentified)")
                row("Last advertisement", age(bluetooth.lastAdvertisementAt))
                row("Last Victron advertisement", age(bluetooth.lastVictronAdvertisementAt))
            }

            Section("Selected device") {
                if let device = bluetooth.selectedDevice {
                    row("Name", device.name ?? "Unknown")
                    row("Identifier", device.id.uuidString)
                    row("RSSI", "\(device.rssi) dBm")
                    row("Victron", device.isVictron ? "Yes" : "No")
                    row("Product advertisement",
                        device.victron?.isProductAdvertisement == true ? "Yes" : "No")
                    row("Last seen", age(device.lastSeen))
                } else {
                    Text("No device selected").foregroundStyle(.secondary)
                }
            }

            Section("Decoded telemetry") {
                row("Record type", recordTypeDescription)
                if let decoded {
                    row("State of charge", TelemetryFormatting.stateOfCharge(decoded.stateOfCharge))
                    row("Voltage", TelemetryFormatting.voltage(decoded.voltage))
                    row("Current", TelemetryFormatting.current(decoded.current))
                    row("Power (derived)", TelemetryFormatting.power(decoded.power))
                    row("Consumed", TelemetryFormatting.consumedAh(decoded.consumedAh))
                    row("Time remaining", TelemetryFormatting.timeRemaining(decoded.timeRemainingMinutes))
                    row("Decoded from", age(bluetooth.selectedDevice?.lastSeen))
                } else {
                    Text("No decoded telemetry. Select the device and set its encryption key.")
                        .foregroundStyle(.secondary)
                }
            }

#if DEBUG
            if let data = bluetooth.selectedDevice?.manufacturerData {
                Section("Manufacturer data (hex) - DEBUG") {
                    Text(data.hexString())
                        .font(.caption2).monospaced()
                        .textSelection(.enabled)
                }
            }
#endif

            Section {
                Button {
                    UIPasteboard.general.string = diagnosticsReport()
                    didCopy = true
                } label: {
                    Label(didCopy ? "Copied" : "Copy Diagnostics",
                          systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }
            }
        }
        .navigationTitle("Diagnostics")
        .onReceive(tick) { value in
            now = value
            didCopy = false
        }
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.subheadline)
    }

    private func age(_ date: Date?) -> String {
        guard let date else { return "—" }
        return TelemetryFormatting.shortAge(since: date, now: now)
    }

    /// A plain-text report for pasting back. Includes raw manufacturer data hex
    /// only in DEBUG. Never includes any encryption key (we hold none here).
    private func diagnosticsReport() -> String {
        var lines: [String] = []
        lines.append("Vehicle Telemetry diagnostics")
        lines.append("Generated: \(ISO8601DateFormatter().string(from: Date()))")
        lines.append("Bluetooth state: \(bluetooth.stateDescription)")
        lines.append("Advertisements received: \(bluetooth.advertisementsReceived)")
        lines.append("Victron advertisements: \(bluetooth.victronAdvertisementsIdentified)")

        if let device = bluetooth.selectedDevice {
            lines.append("")
            lines.append("Selected device:")
            lines.append("  Name: \(device.name ?? "Unknown")")
            lines.append("  Identifier: \(device.id.uuidString)")
            lines.append("  RSSI: \(device.rssi) dBm")
            lines.append("  Victron: \(device.isVictron ? "Yes" : "No")")
            lines.append("  Product advertisement: \(device.victron?.isProductAdvertisement == true ? "Yes" : "No")")
#if DEBUG
            if let data = device.manufacturerData {
                lines.append("  Manufacturer data (\(data.count) bytes): \(data.hexString())")
            }
#endif
        } else {
            lines.append("")
            lines.append("No device selected.")
        }
        return lines.joined(separator: "\n")
    }
}
