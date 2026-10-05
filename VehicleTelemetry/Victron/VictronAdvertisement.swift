//
//  VictronAdvertisement.swift
//  VehicleTelemetry
//
//  Identification-only view of a Victron BLE advertisement. For discovery we
//  rely ONLY on facts confirmed from the official Victron "Extra Manufacturer
//  Data" spec (2022-12-14): the company identifier 0x02E1 and the 0x10
//  product-advertisement marker. The internal record layout (device type,
//  nonce, key-match byte, encrypted payload) is intentionally NOT parsed here;
//  those byte offsets are confirmed against a real captured packet before
//  decoding is implemented (milestones 3-4).
//

import Foundation

/// What we can say about a BLE advertisement from Victron-specific markers,
/// without decrypting or trusting unconfirmed byte offsets.
struct VictronAdvertisement: Equatable {
    /// Victron Energy BV Bluetooth company identifier (little-endian on the wire).
    static let companyIdentifier: UInt16 = 0x02E1
    /// Manufacturer-data record type marking an Instant Readout Product Advertisement.
    static let productAdvertisementRecordType: UInt8 = 0x10

    /// The full manufacturer-specific data as delivered by Core Bluetooth,
    /// including the leading 2-byte company identifier.
    let rawManufacturerData: Data

    /// True when the first byte after the company id is the 0x10 product
    /// advertisement marker (i.e. this likely carries Instant Readout data).
    let isProductAdvertisement: Bool

    /// Identify a Victron advertisement from Core Bluetooth manufacturer data.
    /// Returns `nil` when the data is not Victron (company id mismatch / too short).
    static func identify(manufacturerData: Data?) -> VictronAdvertisement? {
        guard let data = manufacturerData, data.count >= 2 else { return nil }
        // First two bytes are the company identifier, little-endian.
        let company = UInt16(data[data.startIndex]) | (UInt16(data[data.startIndex + 1]) << 8)
        guard company == companyIdentifier else { return nil }

        let isProductAd = data.count >= 3
            && data[data.startIndex + 2] == productAdvertisementRecordType

        return VictronAdvertisement(
            rawManufacturerData: data,
            isProductAdvertisement: isProductAd
        )
    }
}
