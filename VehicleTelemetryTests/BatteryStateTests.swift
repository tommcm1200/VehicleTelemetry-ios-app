//
//  BatteryStateTests.swift
//  VehicleTelemetryTests
//

import XCTest
@testable import VehicleTelemetry

final class BatteryStateTests: XCTestCase {

    private func roundTrip(_ state: BatteryState) throws -> BatteryState {
        let data = try JSONEncoder().encode(state)
        return try JSONDecoder().decode(BatteryState.self, from: data)
    }

    func testFullReadingRoundTrips() throws {
        let original = BatteryState(
            deviceID: "BMV-712",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            stateOfCharge: 82,
            voltage: 13.24,
            current: -4.2,
            power: -56,
            consumedAh: -37,
            timeRemainingMinutes: 860
        )
        let decoded = try roundTrip(original)
        XCTAssertEqual(original, decoded)
    }

    func testMissingValuesStayNil() throws {
        // Only voltage is present; everything else must survive as nil and
        // must never be fabricated into a zero.
        let sparse = BatteryState(
            deviceID: "BMV-712",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            stateOfCharge: nil,
            voltage: 12.0,
            current: nil,
            power: nil,
            consumedAh: nil,
            timeRemainingMinutes: nil
        )
        let decoded = try roundTrip(sparse)
        XCTAssertEqual(decoded, sparse)
        XCTAssertNil(decoded.stateOfCharge)
        XCTAssertNil(decoded.current)
        XCTAssertNil(decoded.power)
        XCTAssertNil(decoded.consumedAh)
        XCTAssertNil(decoded.timeRemainingMinutes)
        XCTAssertEqual(decoded.voltage, 12.0)
    }
}
