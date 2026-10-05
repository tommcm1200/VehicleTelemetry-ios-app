//
//  TelemetryFreshnessTests.swift
//  VehicleTelemetryTests
//

import XCTest
@testable import VehicleTelemetry

final class TelemetryFreshnessTests: XCTestCase {

    // Default thresholds: fresh < 30s, stale 30s...300s, unavailable > 300s.

    func testZeroSecondsIsFresh() {
        XCTAssertEqual(TelemetryFreshness.evaluate(age: 0), .fresh)
    }

    func testTwentyNineSecondsIsFresh() {
        XCTAssertEqual(TelemetryFreshness.evaluate(age: 29), .fresh)
    }

    func testThirtySecondsIsStale() {
        XCTAssertEqual(TelemetryFreshness.evaluate(age: 30), .stale)
    }

    func testFiveMinutesIsStale() {
        XCTAssertEqual(TelemetryFreshness.evaluate(age: 5 * 60), .stale)
    }

    func testJustOverFiveMinutesIsUnavailable() {
        XCTAssertEqual(TelemetryFreshness.evaluate(age: 5 * 60 + 1), .unavailable)
    }

    func testFutureTimestampIsFresh() {
        // Clock skew producing a negative age must not be treated as stale.
        XCTAssertEqual(TelemetryFreshness.evaluate(age: -5), .fresh)
    }

    func testOfTimestampUsesAgeRelativeToNow() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fresh = now.addingTimeInterval(-10)
        let stale = now.addingTimeInterval(-120)
        let gone = now.addingTimeInterval(-600)
        XCTAssertEqual(TelemetryFreshness.of(timestamp: fresh, now: now), .fresh)
        XCTAssertEqual(TelemetryFreshness.of(timestamp: stale, now: now), .stale)
        XCTAssertEqual(TelemetryFreshness.of(timestamp: gone, now: now), .unavailable)
    }

    func testCustomThresholds() {
        let thresholds = TelemetryFreshnessThresholds(freshBelow: 5, staleBelow: 10)
        XCTAssertEqual(TelemetryFreshness.evaluate(age: 4, thresholds: thresholds), .fresh)
        XCTAssertEqual(TelemetryFreshness.evaluate(age: 5, thresholds: thresholds), .stale)
        XCTAssertEqual(TelemetryFreshness.evaluate(age: 10, thresholds: thresholds), .stale)
        XCTAssertEqual(TelemetryFreshness.evaluate(age: 11, thresholds: thresholds), .unavailable)
    }
}
