//
//  Log.swift
//  VehicleTelemetry
//
//  Release-safe logging via os.Logger. NEVER log secret material (encryption
//  keys). Raw packet bytes may only be logged in DEBUG and only where safe.
//

import os

enum Log {
    private static let subsystem = "com.tommcmeekin.VehicleTelemetry"

    static let bluetooth = Logger(subsystem: subsystem, category: "Bluetooth")
    static let victron = Logger(subsystem: subsystem, category: "Victron")
    static let crypto = Logger(subsystem: subsystem, category: "Crypto")
    static let telemetry = Logger(subsystem: subsystem, category: "Telemetry")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let widget = Logger(subsystem: subsystem, category: "Widget")
}
