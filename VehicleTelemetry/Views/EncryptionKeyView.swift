//
//  EncryptionKeyView.swift
//  VehicleTelemetry
//
//  Enter the Victron Instant Readout key (from VictronConnect) and validate it
//  against a live advertisement. The key is stored only in the Keychain, is
//  never echoed back, and is cleared from the field after a successful save.
//

import SwiftUI

struct EncryptionKeyView: View {
    @Environment(BluetoothManager.self) private var bluetooth
    @Environment(AppState.self) private var appState

    @State private var hexInput = ""
    @State private var outcome: KeyTestOutcome?

    private let keyService = VictronKeyService()

    var body: some View {
        Form {
            if let device = bluetooth.selectedDevice {
                Section("Device") {
                    LabeledContent("Name", value: device.name ?? "Unknown")
                    LabeledContent("Victron", value: device.isVictron ? "Yes" : "No")
                }

                Section("Instant Readout key") {
                    TextField("32 hex characters", text: $hexInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                        .privacySensitive()

                    Button("Save and Test") {
                        let result = keyService.saveAndTest(hex: hexInput, device: device)
                        outcome = result
                        if result.isSuccess {
                            hexInput = ""   // never keep the key in the UI
                            // Switch telemetry to this real BMV.
                            appState.startLiveTelemetry(deviceID: device.id, name: device.name ?? "BMV")
                        }
                    }
                    .disabled(hexInput.isEmpty)
                }

                if let outcome {
                    Section {
                        Label(outcome.message,
                              systemImage: outcome.isSuccess ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(outcome.isSuccess ? .green : .orange)
                    }
                }

                Section {
                    Text("Find the key in VictronConnect: your device > settings (gear) > Product info > Instant readout via Bluetooth > Show encryption data.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    Text("Select a device in Discover first.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Encryption Key")
    }
}
