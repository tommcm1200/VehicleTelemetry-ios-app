//
//  VictronKeyService.swift
//  VehicleTelemetry
//
//  "Save and Test" for the Instant Readout key: validate the key format, verify
//  it against a real advertisement from the device, and store it in the
//  Keychain only on success. The key is never logged or echoed back.
//

import Foundation
import os

enum KeyTestOutcome: Equatable {
    case success(deviceType: String)
    case invalidKeyFormat
    case noAdvertisement
    case notVictronProductAdvertisement
    case keyMismatch
    case decryptionFailed

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .success(let type): return "Key valid. Decrypted a \(type) advertisement."
        case .invalidKeyFormat: return "Enter the 32-character key from VictronConnect (hex)."
        case .noAdvertisement: return "No recent advertisement from this device. Move closer and try again."
        case .notVictronProductAdvertisement: return "This device is not broadcasting Victron Instant Readout data."
        case .keyMismatch: return "That key does not match this device. Check the Instant Readout key in VictronConnect."
        case .decryptionFailed: return "Decryption failed. Check the key and try again."
        }
    }
}

struct VictronKeyService {
    let keyStore: SecureKeyStore

    init(keyStore: SecureKeyStore = SecureKeyStore()) {
        self.keyStore = keyStore
    }

    /// Validate `hex` against the device's latest advertisement and, on success,
    /// persist the key in the Keychain. Returns the outcome for display.
    func saveAndTest(hex: String, device: DiscoveredDevice) -> KeyTestOutcome {
        guard let key = VictronCrypto.key(fromHex: hex) else { return .invalidKeyFormat }
        guard let manufacturerData = device.manufacturerData else { return .noAdvertisement }
        guard let record = VictronInstantReadoutRecord.parse(manufacturerData: manufacturerData) else {
            return .notVictronProductAdvertisement
        }
        guard let first = key.first, first == record.keyCheckByte else { return .keyMismatch }

        do {
            _ = try VictronCrypto.decrypt(record: record, key: key)
        } catch VictronCryptoError.keyMismatch {
            return .keyMismatch
        } catch {
            return .decryptionFailed
        }

        do {
            try keyStore.save(key, for: device.id.uuidString)
        } catch {
            return .decryptionFailed
        }

        Log.crypto.notice("Instant Readout key validated and stored")
        let typeName = record.deviceType?.displayName ?? "Victron"
        return .success(deviceType: typeName)
    }
}
