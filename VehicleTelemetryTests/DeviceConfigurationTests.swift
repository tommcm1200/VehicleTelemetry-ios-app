//
//  DeviceConfigurationTests.swift
//  VehicleTelemetryTests
//

import XCTest
@testable import VehicleTelemetry

final class DeviceConfigurationTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        defaults = UserDefaults(suiteName: "DeviceConfigurationTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: defaults.description)
    }

    func testSaveLoadRoundTrip() {
        let config = DeviceConfiguration(deviceID: UUID(), name: "SmartBMV")
        config.save(to: defaults)
        XCTAssertEqual(DeviceConfiguration.load(from: defaults), config)
    }

    func testLoadWhenAbsentReturnsNil() {
        XCTAssertNil(DeviceConfiguration.load(from: defaults))
    }

    func testClearRemovesConfiguration() {
        let config = DeviceConfiguration(deviceID: UUID(), name: "SmartBMV")
        config.save(to: defaults)
        DeviceConfiguration.clear(from: defaults)
        XCTAssertNil(DeviceConfiguration.load(from: defaults))
    }
}
