//
//  VictronAdvertisementTests.swift
//  VehicleTelemetryTests
//

import XCTest
@testable import VehicleTelemetry

final class VictronAdvertisementTests: XCTestCase {

    func testIdentifiesVictronProductAdvertisement() throws {
        // Company id 0x02E1 little-endian (E1 02), then 0x10 product-advert marker.
        let data = Data([0xE1, 0x02, 0x10, 0x02, 0x11, 0x22, 0x33])
        let ad = try XCTUnwrap(VictronAdvertisement.identify(manufacturerData: data))
        XCTAssertTrue(ad.isProductAdvertisement)
        XCTAssertEqual(ad.rawManufacturerData, data)
    }

    func testIdentifiesVictronNonProductAdvertisement() throws {
        // Victron company id but not a 0x10 product advertisement.
        let data = Data([0xE1, 0x02, 0x09, 0x00])
        let ad = try XCTUnwrap(VictronAdvertisement.identify(manufacturerData: data))
        XCTAssertFalse(ad.isProductAdvertisement)
    }

    func testNonVictronCompanyIdReturnsNil() {
        // Apple's company id 0x004C.
        let data = Data([0x4C, 0x00, 0x10, 0x02])
        XCTAssertNil(VictronAdvertisement.identify(manufacturerData: data))
    }

    func testTooShortReturnsNil() {
        XCTAssertNil(VictronAdvertisement.identify(manufacturerData: Data([0xE1])))
    }

    func testNilReturnsNil() {
        XCTAssertNil(VictronAdvertisement.identify(manufacturerData: nil))
    }

    func testCompanyIdIsLittleEndian() {
        // Bytes 02 E1 would be company 0xE102, not Victron; must not match.
        let data = Data([0x02, 0xE1, 0x10])
        XCTAssertNil(VictronAdvertisement.identify(manufacturerData: data))
    }
}
