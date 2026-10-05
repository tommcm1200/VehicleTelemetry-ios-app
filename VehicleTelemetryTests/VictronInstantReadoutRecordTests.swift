//
//  VictronInstantReadoutRecordTests.swift
//  VehicleTelemetryTests
//
//  Parses the real BMV advertisement captured on device (public BLE broadcast;
//  the payload is encrypted and contains no key, so it is safe as a fixture).
//

import XCTest
@testable import VehicleTelemetry

final class VictronInstantReadoutRecordTests: XCTestCase {

    // Captured 2026-10-03 from "SmartBMV HQ2442RZTKQ".
    private let capturedManufacturerData = Data([
        0xE1, 0x02, 0x10, 0x02, 0x83, 0xA3, 0x02, 0x46, 0x32, 0x4D,
        0xFD, 0x31, 0xC2, 0x47, 0x1B, 0xED, 0x0B, 0x89, 0xAF, 0xA0,
        0xBE, 0x7E, 0x1E, 0x66, 0x23
    ])

    func testParsesCapturedBatteryMonitorRecord() throws {
        let record = try XCTUnwrap(
            VictronInstantReadoutRecord.parse(manufacturerData: capturedManufacturerData)
        )
        XCTAssertEqual(record.modelId, 0x8302)
        XCTAssertEqual(record.readoutType, 0xA3)
        XCTAssertEqual(record.deviceTypeRaw, 0x02)
        XCTAssertEqual(record.deviceType, .batteryMonitor)
        XCTAssertEqual(record.nonce, 0x3246)
        XCTAssertEqual(record.keyCheckByte, 0x4D)
        XCTAssertEqual(record.ciphertext.count, 15)
        XCTAssertEqual(
            record.ciphertext,
            Data([0xFD, 0x31, 0xC2, 0x47, 0x1B, 0xED, 0x0B, 0x89,
                  0xAF, 0xA0, 0xBE, 0x7E, 0x1E, 0x66, 0x23])
        )
    }

    func testNonVictronReturnsNil() {
        XCTAssertNil(VictronInstantReadoutRecord.parse(manufacturerData: Data([0x4C, 0x00, 0x10, 0x02, 0x83, 0xA3, 0x02, 0x46, 0x32, 0x4D])))
    }

    func testTooShortReturnsNil() {
        XCTAssertNil(VictronInstantReadoutRecord.parse(manufacturerData: Data([0xE1, 0x02, 0x10, 0x02])))
    }
}
