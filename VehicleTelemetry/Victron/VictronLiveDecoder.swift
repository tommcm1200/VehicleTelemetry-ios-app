//
//  VictronLiveDecoder.swift
//  VehicleTelemetry
//
//  Convenience: decrypt + decode a device's latest advertisement using the key
//  stored in the Keychain. Used to show decoded values for comparison against
//  VictronConnect before the full live pipeline (Milestone 5) is wired.
//

import Foundation

struct VictronLiveDecoder {
    let keyStore: SecureKeyStore

    init(keyStore: SecureKeyStore = SecureKeyStore()) {
        self.keyStore = keyStore
    }

    /// Decode the device's most recent Battery Monitor advertisement, or nil if
    /// there is no stored key, no advertisement, or it is not a battery monitor.
    func decodeLatest(for device: DiscoveredDevice) -> BatteryState? {
        guard let key = (try? keyStore.load(for: device.id.uuidString)) ?? nil else { return nil }
        guard let record = VictronInstantReadoutRecord.parse(manufacturerData: device.manufacturerData),
              record.deviceType == .batteryMonitor,
              let plaintext = try? VictronCrypto.decrypt(record: record, key: key)
        else { return nil }
        return VictronBMVDecoder.decode(
            decrypted: plaintext,
            deviceID: device.id.uuidString,
            timestamp: device.lastSeen
        )
    }
}
