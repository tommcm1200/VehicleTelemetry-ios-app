//
//  BLEAdvertisement.swift
//  VehicleTelemetry
//
//  A single BLE advertisement observation, decoupled from Core Bluetooth types
//  so it is easy to test and reason about.
//

import Foundation

struct BLEAdvertisement: Equatable {
    /// Core Bluetooth peripheral identifier (stable per device, per iPhone).
    let identifier: UUID
    /// Advertised local name or peripheral name, if any.
    let name: String?
    /// Signal strength in dBm.
    let rssi: Int
    /// Raw manufacturer-specific data, if present (company id + payload).
    let manufacturerData: Data?
    /// When this advertisement was observed.
    let timestamp: Date

    /// Victron identification derived from the manufacturer data, if any.
    var victron: VictronAdvertisement? {
        VictronAdvertisement.identify(manufacturerData: manufacturerData)
    }
}
