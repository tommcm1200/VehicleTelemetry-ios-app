//
//  VictronBMVDecoderTests.swift
//  VehicleTelemetryTests
//
//  Decoder tests use synthetic payloads packed with the documented bit layout,
//  so they are deterministic without needing the (device-only) encryption key.
//

import XCTest
@testable import VehicleTelemetry

final class VictronBMVDecoderTests: XCTestCase {

    /// Packs bitfields LSB-first, mirroring the reader.
    private struct BitWriter {
        private(set) var bytes: [UInt8] = []
        private var bitPos = 0
        mutating func write(_ value: UInt32, _ count: Int) {
            for i in 0..<count {
                let p = bitPos + i
                let byteIndex = p >> 3
                while bytes.count <= byteIndex { bytes.append(0) }
                if (value >> i) & 1 != 0 { bytes[byteIndex] |= UInt8(1 << (p & 7)) }
            }
            bitPos += count
        }
    }

    private func payload(
        ttg: UInt32, voltage: UInt32, current: UInt32, consumed: UInt32, soc: UInt32,
        alarm: UInt32 = 0, aux: UInt32 = 0, auxMode: UInt32 = 0
    ) -> Data {
        var w = BitWriter()
        w.write(ttg, 16)
        w.write(voltage, 16)
        w.write(alarm, 16)
        w.write(aux, 16)
        w.write(auxMode, 2)
        w.write(current, 22)
        w.write(consumed, 20)
        w.write(soc, 10)
        var data = Data(w.bytes)
        while data.count < 15 { data.append(0) }   // 118 bits -> 15 bytes
        return data
    }

    func testDecodesTypicalReading() {
        // -4.2 A as 22-bit two's complement.
        let currentRaw = UInt32((1 << 22) - 4200)
        let data = payload(ttg: 860, voltage: 1324, current: currentRaw, consumed: 370, soc: 820)
        let b = VictronBMVDecoder.decode(decrypted: data, deviceID: "X", timestamp: Date())

        XCTAssertEqual(b.timeRemainingMinutes, 860)
        XCTAssertEqual(b.voltage!, 13.24, accuracy: 0.0001)
        XCTAssertEqual(b.current!, -4.2, accuracy: 0.0001)
        XCTAssertEqual(b.consumedAh!, -37.0, accuracy: 0.0001)
        XCTAssertEqual(b.stateOfCharge!, 82.0, accuracy: 0.0001)
        // Derived power = V * I.
        XCTAssertEqual(b.power!, 13.24 * -4.2, accuracy: 0.001)
    }

    func testPositiveCurrentCharging() {
        let data = payload(ttg: 0xFFFF, voltage: 1360, current: 10_000, consumed: 0, soc: 1000)
        let b = VictronBMVDecoder.decode(decrypted: data, deviceID: "X", timestamp: Date())
        XCTAssertEqual(b.current!, 10.0, accuracy: 0.0001)   // +10 A
        XCTAssertEqual(b.stateOfCharge!, 100.0, accuracy: 0.0001)
        XCTAssertNil(b.timeRemainingMinutes)                 // 0xFFFF = NA
    }

    func testNASentinelsBecomeNil() {
        let data = payload(
            ttg: 0xFFFF, voltage: 0x7FFF, current: 0x3FFFFF, consumed: 0xFFFFF, soc: 0x3FF
        )
        let b = VictronBMVDecoder.decode(decrypted: data, deviceID: "X", timestamp: Date())
        XCTAssertNil(b.timeRemainingMinutes)
        XCTAssertNil(b.voltage)
        XCTAssertNil(b.current)
        XCTAssertNil(b.consumedAh)
        XCTAssertNil(b.stateOfCharge)
        XCTAssertNil(b.power)   // no voltage/current -> no derived power
    }

    func testConsumedAhIsNegated() {
        let data = payload(ttg: 100, voltage: 1300, current: 0, consumed: 125, soc: 500)
        let b = VictronBMVDecoder.decode(decrypted: data, deviceID: "X", timestamp: Date())
        XCTAssertEqual(b.consumedAh!, -12.5, accuracy: 0.0001)
    }
}
