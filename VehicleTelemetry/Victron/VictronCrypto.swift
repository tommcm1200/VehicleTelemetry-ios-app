//
//  VictronCrypto.swift
//  VehicleTelemetry
//
//  AES-128-CTR decryption for Victron Instant Readout payloads. CryptoKit does
//  not expose AES-CTR, so this uses Apple's CommonCrypto (a system library, not
//  a third-party dependency). This layer is independent of Core Bluetooth.
//

import Foundation
import CommonCrypto

enum VictronCryptoError: Error, Equatable {
    case invalidKeyLength(Int)
    case invalidIVLength(Int)
    case emptyCiphertext
    case keyMismatch
    case decryptionFailed(Int32)
}

enum VictronCrypto {
    static let keyLength = 16   // AES-128
    static let blockSize = kCCBlockSizeAES128   // 16

    /// Core AES-128-CTR transform with an explicit 16-byte initial counter (IV).
    /// CTR is symmetric, so this both encrypts and decrypts.
    static func crypt(_ input: Data, key: Data, iv: Data) throws -> Data {
        guard key.count == keyLength else { throw VictronCryptoError.invalidKeyLength(key.count) }
        guard iv.count == blockSize else { throw VictronCryptoError.invalidIVLength(iv.count) }
        guard !input.isEmpty else { throw VictronCryptoError.emptyCiphertext }

        let keyBytes = [UInt8](key)
        let ivBytes = [UInt8](iv)
        let inBytes = [UInt8](input)
        var outBytes = [UInt8](repeating: 0, count: inBytes.count)

        var cryptor: CCCryptorRef?
        let createStatus = CCCryptorCreateWithMode(
            CCOperation(kCCDecrypt),
            CCMode(kCCModeCTR),
            CCAlgorithm(kCCAlgorithmAES),
            CCPadding(ccNoPadding),
            ivBytes,
            keyBytes, keyBytes.count,
            nil, 0, 0,
            CCModeOptions(kCCModeOptionCTR_BE),
            &cryptor
        )
        guard createStatus == kCCSuccess, let cryptor else {
            throw VictronCryptoError.decryptionFailed(createStatus)
        }
        defer { CCCryptorRelease(cryptor) }

        var moved = 0
        let updateStatus = CCCryptorUpdate(
            cryptor, inBytes, inBytes.count, &outBytes, outBytes.count, &moved
        )
        guard updateStatus == kCCSuccess else {
            throw VictronCryptoError.decryptionFailed(updateStatus)
        }
        return Data(outBytes.prefix(moved))
    }

    /// Decrypt a payload using a 16-bit Victron nonce. The nonce occupies the
    /// first two bytes of the 16-byte counter (little-endian), rest zero.
    static func decrypt(ciphertext: Data, key: Data, nonce: UInt16) throws -> Data {
        var iv = Data(repeating: 0, count: blockSize)
        iv[0] = UInt8(nonce & 0xFF)
        iv[1] = UInt8((nonce >> 8) & 0xFF)
        return try crypt(ciphertext, key: key, iv: iv)
    }

    /// Decrypt a parsed record, first checking the quick key-match byte.
    static func decrypt(record: VictronInstantReadoutRecord, key: Data) throws -> Data {
        guard key.count == keyLength else { throw VictronCryptoError.invalidKeyLength(key.count) }
        guard let first = key.first, first == record.keyCheckByte else {
            throw VictronCryptoError.keyMismatch
        }
        return try decrypt(ciphertext: record.ciphertext, key: key, nonce: record.nonce)
    }

    /// Parse a 32-hex-character Instant Readout key into 16 bytes. Returns nil
    /// if the string is not exactly 32 hex digits (whitespace is ignored).
    static func key(fromHex hex: String) -> Data? {
        let cleaned = hex.filter { !$0.isWhitespace }
        guard cleaned.count == keyLength * 2 else { return nil }
        var data = Data(capacity: keyLength)
        var index = cleaned.startIndex
        for _ in 0..<keyLength {
            let next = cleaned.index(index, offsetBy: 2)
            guard let byte = UInt8(cleaned[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }
}
