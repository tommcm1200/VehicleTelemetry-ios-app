//
//  DiscoveredDevice.swift
//  VehicleTelemetry
//
//  A device aggregated from one or more BLE advertisements.
//

import Foundation

struct DiscoveredDevice: Identifiable, Equatable {
    let id: UUID
    var name: String?
    var rssi: Int
    var lastSeen: Date
    /// Most recent manufacturer-specific data seen from this device.
    var manufacturerData: Data?
    /// Victron identification from the latest advertisement, if any.
    var victron: VictronAdvertisement?

    var isVictron: Bool { victron != nil }
    var hasManufacturerData: Bool { (manufacturerData?.isEmpty == false) }

    /// Fold a new advertisement into this device's aggregated state.
    mutating func update(with ad: BLEAdvertisement) {
        if let name = ad.name, !name.isEmpty { self.name = name }
        rssi = ad.rssi
        lastSeen = ad.timestamp
        if let manu = ad.manufacturerData { manufacturerData = manu }
        victron = ad.victron
    }

    init(advertisement ad: BLEAdvertisement) {
        id = ad.identifier
        name = ad.name
        rssi = ad.rssi
        lastSeen = ad.timestamp
        manufacturerData = ad.manufacturerData
        victron = ad.victron
    }
}
