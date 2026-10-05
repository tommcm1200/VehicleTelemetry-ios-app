//
//  BitReader.swift
//  VehicleTelemetry
//
//  Reads bitfields least-significant-bit first across a byte buffer, matching
//  the Victron Instant Readout record bit packing.
//

import Foundation

struct BitReader {
    private let bytes: [UInt8]
    private(set) var bitPosition = 0

    init(_ data: Data) {
        bytes = [UInt8](data)
    }

    /// Read `count` bits (LSB first) as an unsigned value. Bits past the end of
    /// the buffer read as 0.
    mutating func readUnsigned(_ count: Int) -> UInt32 {
        var value: UInt32 = 0
        for i in 0..<count {
            let p = bitPosition + i
            let byteIndex = p >> 3
            if byteIndex < bytes.count {
                let bit = UInt32((bytes[byteIndex] >> (p & 7)) & 1)
                value |= bit << i
            }
        }
        bitPosition += count
        return value
    }

    /// Read `count` bits (LSB first) as a two's-complement signed value.
    mutating func readSigned(_ count: Int) -> Int {
        let raw = readUnsigned(count)
        let signBit: UInt32 = 1 << (count - 1)
        if raw & signBit != 0 {
            return Int(raw) - (1 << count)
        }
        return Int(raw)
    }
}
