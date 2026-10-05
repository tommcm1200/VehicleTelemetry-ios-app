//
//  SecureKeyStore.swift
//  VehicleTelemetry
//
//  Stores the Victron Instant Readout encryption key in the Keychain, keyed by
//  device identifier. The key must NEVER appear in UserDefaults, the App Group,
//  the widget, logs, diagnostics, or crash messages - only here.
//

import Foundation
import Security

enum SecureKeyStoreError: Error, Equatable {
    case unexpectedStatus(OSStatus)
}

nonisolated struct SecureKeyStore {
    /// Keychain service namespace for Victron keys.
    let service: String

    init(service: String = "com.tommcmeekin.VehicleTelemetry.victronKey") {
        self.service = service
    }

    private func baseQuery(for deviceID: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID
        ]
    }

    /// Save (or replace) the key for a device.
    func save(_ key: Data, for deviceID: String) throws {
        var query = baseQuery(for: deviceID)
        // Available in the background (for BLE decryption) but never synced.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let deleteStatus = SecItemDelete(query as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw SecureKeyStoreError.unexpectedStatus(deleteStatus)
        }

        query[kSecValueData as String] = key
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw SecureKeyStoreError.unexpectedStatus(addStatus)
        }
    }

    /// Load the key for a device, or nil if none is stored.
    func load(for deviceID: String) throws -> Data? {
        var query = baseQuery(for: deviceID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw SecureKeyStoreError.unexpectedStatus(status)
        }
    }

    /// Delete the key for a device (no error if absent).
    func delete(for deviceID: String) throws {
        let status = SecItemDelete(baseQuery(for: deviceID) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureKeyStoreError.unexpectedStatus(status)
        }
    }

    /// Whether a key is stored for a device.
    func hasKey(for deviceID: String) -> Bool {
        (try? load(for: deviceID)) != nil
    }
}
