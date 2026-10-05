//
//  DataHex.swift
//  VehicleTelemetry
//
//  Hex formatting for diagnostics. DEBUG use shows raw manufacturer data; this
//  is never used for secret material.
//

import Foundation

extension Data {
    /// Uppercase hex string, optionally space-separated per byte.
    func hexString(spaced: Bool = true) -> String {
        map { String(format: "%02X", $0) }
            .joined(separator: spaced ? " " : "")
    }
}
