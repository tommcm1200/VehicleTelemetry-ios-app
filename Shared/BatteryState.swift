//
//  BatteryState.swift
//  VehicleTelemetry
//
//  The core telemetry model. Shared between the app and the widget.
//  Missing values stay nil - never manufacture telemetry that was not
//  present in the Victron payload.
//

import Foundation

/// A single decoded battery reading from a telemetry source.
///
/// Every optional stays `nil` when the source did not report that field.
/// Presentation and formatting live outside this type.
nonisolated struct BatteryState: Codable, Equatable {
    /// Stable identifier of the device this reading came from.
    let deviceID: String
    /// When this reading was produced (device clock).
    let timestamp: Date

    /// State of charge, percent (0...100).
    let stateOfCharge: Double?
    /// Battery voltage, volts.
    let voltage: Double?
    /// Current, amps. Negative means discharge.
    let current: Double?
    /// Power, watts. Negative means discharge.
    let power: Double?
    /// Consumed energy, amp-hours. Typically negative or zero.
    let consumedAh: Double?
    /// Estimated time remaining, minutes.
    let timeRemainingMinutes: Int?

    init(
        deviceID: String,
        timestamp: Date,
        stateOfCharge: Double? = nil,
        voltage: Double? = nil,
        current: Double? = nil,
        power: Double? = nil,
        consumedAh: Double? = nil,
        timeRemainingMinutes: Int? = nil
    ) {
        self.deviceID = deviceID
        self.timestamp = timestamp
        self.stateOfCharge = stateOfCharge
        self.voltage = voltage
        self.current = current
        self.power = power
        self.consumedAh = consumedAh
        self.timeRemainingMinutes = timeRemainingMinutes
    }
}
