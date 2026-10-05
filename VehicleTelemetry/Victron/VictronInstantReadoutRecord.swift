//
//  VictronInstantReadoutRecord.swift
//  VehicleTelemetry
//
//  Parses the Victron Instant Readout "product advertisement" container into its
//  header fields and the still-encrypted payload. Byte offsets follow the
//  official "Extra Manufacturer Data" spec (2022-12-14) and were confirmed
//  against a real captured BMV packet. Decryption/decoding happen elsewhere.
//
//  Layout (manufacturer data including the leading 2-byte company id):
//    [0..1] company id 0x02E1 (LE)
//    [2]    0x10 product-advertisement record type
//    [3..4] model id (LE)
//    [5]    readout type
//    [6]    device/record type (0x02 = Battery Monitor)
//    [7..8] nonce / data counter (LE)
//    [9]    key-check byte (first byte of the AES key)
//    [10..] AES-128-CTR ciphertext
//

import Foundation

struct VictronInstantReadoutRecord: Equatable {
    let modelId: UInt16
    let readoutType: UInt8
    let deviceTypeRaw: UInt8
    let deviceType: VictronRecordType?
    /// 16-bit data counter used as the AES-CTR nonce.
    let nonce: UInt16
    /// First byte of the AES key, for a quick wrong-key check.
    let keyCheckByte: UInt8
    /// The still-encrypted payload.
    let ciphertext: Data

    static func parse(manufacturerData: Data?) -> VictronInstantReadoutRecord? {
        guard let d = manufacturerData, d.count >= 10 else { return nil }
        let s = d.startIndex
        let company = UInt16(d[s]) | (UInt16(d[s + 1]) << 8)
        guard company == VictronAdvertisement.companyIdentifier else { return nil }
        guard d[s + 2] == VictronAdvertisement.productAdvertisementRecordType else { return nil }

        let modelId = UInt16(d[s + 3]) | (UInt16(d[s + 4]) << 8)
        let readoutType = d[s + 5]
        let deviceRaw = d[s + 6]
        let nonce = UInt16(d[s + 7]) | (UInt16(d[s + 8]) << 8)
        let keyCheck = d[s + 9]
        let ciphertext = d.count > 10 ? Data(d[(s + 10)...]) : Data()

        return VictronInstantReadoutRecord(
            modelId: modelId,
            readoutType: readoutType,
            deviceTypeRaw: deviceRaw,
            deviceType: VictronRecordType(rawValue: deviceRaw),
            nonce: nonce,
            keyCheckByte: keyCheck,
            ciphertext: ciphertext
        )
    }
}
