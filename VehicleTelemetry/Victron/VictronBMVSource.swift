//
//  VictronBMVSource.swift
//  VehicleTelemetry
//
//  Live telemetry source: watches the configured device's advertisements via
//  the BluetoothManager, decrypts + decodes each one with the stored key, and
//  emits BatteryState. This is the real-hardware counterpart to
//  SimulatedBMVSource.
//

import Foundation

@MainActor
final class VictronBMVSource: TelemetrySource {
    let id: String
    let name: String
    var onUpdate: ((BatteryState) -> Void)?

    private let deviceUUID: UUID
    private let bluetooth: BluetoothManager
    private let decoder: VictronLiveDecoder

    init(
        deviceID: UUID,
        name: String,
        bluetooth: BluetoothManager,
        keyStore: SecureKeyStore = SecureKeyStore()
    ) {
        self.deviceUUID = deviceID
        self.id = deviceID.uuidString
        self.name = name
        self.bluetooth = bluetooth
        self.decoder = VictronLiveDecoder(keyStore: keyStore)
    }

    func start() {
        bluetooth.keepScanning = true
        bluetooth.onDeviceUpdate = { [weak self] device in
            guard let self, device.id == self.deviceUUID else { return }
            if let battery = self.decoder.decodeLatest(for: device) {
                self.onUpdate?(battery)
            }
        }
        bluetooth.startScanning()
    }

    func stop() {
        bluetooth.onDeviceUpdate = nil
        bluetooth.keepScanning = false
        bluetooth.stopScanning()
    }
}
