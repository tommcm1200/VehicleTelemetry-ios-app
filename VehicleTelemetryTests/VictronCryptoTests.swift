//
//  VictronCryptoTests.swift
//  VehicleTelemetryTests
//

import XCTest
@testable import VehicleTelemetry

final class VictronCryptoTests: XCTestCase {

    private func hex(_ s: String) -> Data {
        var d = Data()
        var it = s.makeIterator()
        while let a = it.next(), let b = it.next() {
            d.append(UInt8(String([a, b]), radix: 16)!)
        }
        return d
    }

    // NIST SP 800-38A F.5 CTR-AES128 test vectors. Validates AES-128-CTR with a
    // big-endian counter incrementing across a block boundary.
    func testNISTVectorTwoBlocks() throws {
        let key = hex("2b7e151628aed2a6abf7158809cf4f3c")
        let iv = hex("f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")
        let ciphertext = hex("874d6191b620e3261bef6864990db6ce"
                             + "9806f66b7970fdff8617187bb9fffdff")
        let expected = hex("6bc1bee22e409f96e93d7e117393172a"
                          + "ae2d8a571e03ac9c9eb76fac45af8e51")
        let plaintext = try VictronCrypto.crypt(ciphertext, key: key, iv: iv)
        XCTAssertEqual(plaintext, expected)
    }

    func testCTRIsSymmetricRoundTrip() throws {
        let key = hex("000102030405060708090a0b0c0d0e0f")
        let plaintext = hex("deadbeefcafef00dba5eba11")
        let encrypted = try VictronCrypto.decrypt(ciphertext: plaintext, key: key, nonce: 0x3246)
        let decrypted = try VictronCrypto.decrypt(ciphertext: encrypted, key: key, nonce: 0x3246)
        XCTAssertEqual(decrypted, plaintext)
        XCTAssertNotEqual(encrypted, plaintext)
    }

    func testInvalidKeyLengthThrows() {
        let shortKey = Data(repeating: 0, count: 15)
        XCTAssertThrowsError(try VictronCrypto.crypt(Data([1, 2, 3]), key: shortKey, iv: Data(repeating: 0, count: 16))) { error in
            XCTAssertEqual(error as? VictronCryptoError, .invalidKeyLength(15))
        }
    }

    func testInvalidIVLengthThrows() {
        let key = Data(repeating: 0, count: 16)
        XCTAssertThrowsError(try VictronCrypto.crypt(Data([1, 2, 3]), key: key, iv: Data(repeating: 0, count: 8))) { error in
            XCTAssertEqual(error as? VictronCryptoError, .invalidIVLength(8))
        }
    }

    func testEmptyCiphertextThrows() {
        let key = Data(repeating: 0, count: 16)
        XCTAssertThrowsError(try VictronCrypto.crypt(Data(), key: key, iv: Data(repeating: 0, count: 16))) { error in
            XCTAssertEqual(error as? VictronCryptoError, .emptyCiphertext)
        }
    }

    func testKeyMismatchThrows() {
        // Record expects key[0] == 0xAA; supply a key starting with 0x01.
        let record = VictronInstantReadoutRecord(
            modelId: 0, readoutType: 0, deviceTypeRaw: 0x02,
            deviceType: .batteryMonitor, nonce: 0x3246, keyCheckByte: 0xAA,
            ciphertext: Data(repeating: 0, count: 15)
        )
        var key = Data(repeating: 0, count: 16)
        key[0] = 0x01
        XCTAssertThrowsError(try VictronCrypto.decrypt(record: record, key: key)) { error in
            XCTAssertEqual(error as? VictronCryptoError, .keyMismatch)
        }
    }

    func testKeyFromHexValid() {
        let key = VictronCrypto.key(fromHex: "000102030405060708090A0B0C0D0E0F")
        XCTAssertEqual(key, Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]))
    }

    func testKeyFromHexWrongLengthReturnsNil() {
        XCTAssertNil(VictronCrypto.key(fromHex: "0001020304"))
    }

    func testKeyFromHexNonHexReturnsNil() {
        XCTAssertNil(VictronCrypto.key(fromHex: "zz0102030405060708090a0b0c0d0e0f"))
    }
}
