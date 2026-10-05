//
//  SharedTelemetryStoreTests.swift
//  VehicleTelemetryTests
//

import XCTest
@testable import VehicleTelemetry

final class SharedTelemetryStoreTests: XCTestCase {

    private var fileURL: URL!

    override func setUpWithError() throws {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("snapshot-\(UUID().uuidString).json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func makeSnapshot() -> TelemetrySnapshot {
        TelemetrySnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            battery: BatteryState(
                deviceID: "BMV-712",
                timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                stateOfCharge: 82, voltage: 13.24, current: -4.2,
                power: -56, consumedAh: -37, timeRemainingMinutes: 860
            )
        )
    }

    func testWriteThenReadReturnsEqualSnapshot() throws {
        let store = SharedTelemetryStore(fileURL: fileURL)
        let snapshot = makeSnapshot()
        try store.save(snapshot)
        let loaded = try store.load()
        XCTAssertEqual(loaded, snapshot)
    }

    func testLoadMissingSnapshotReturnsNil() throws {
        let store = SharedTelemetryStore(fileURL: fileURL)
        XCTAssertNil(try store.load())
    }

    func testSaveOverwritesPreviousSnapshot() throws {
        let store = SharedTelemetryStore(fileURL: fileURL)
        try store.save(makeSnapshot())

        let newer = TelemetrySnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_100),
            battery: BatteryState(
                deviceID: "BMV-712",
                timestamp: Date(timeIntervalSince1970: 1_700_000_100),
                stateOfCharge: 50
            )
        )
        try store.save(newer)
        XCTAssertEqual(try store.load(), newer)
    }

    func testMalformedSnapshotThrows() throws {
        try Data("not json".utf8).write(to: fileURL)
        let store = SharedTelemetryStore(fileURL: fileURL)
        XCTAssertThrowsError(try store.load())
    }
}
