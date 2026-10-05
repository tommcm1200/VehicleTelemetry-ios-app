//
//  TelemetrySnapshot.swift
//  VehicleTelemetry
//
//  The normalised telemetry handed across the App Group boundary to the
//  widget. Contains only decoded, non-secret values.
//

import Foundation

/// A point-in-time snapshot of battery telemetry suitable for sharing with
/// the widget via the App Group container.
nonisolated struct TelemetrySnapshot: Codable, Equatable {
    /// When this snapshot was produced by the app.
    let generatedAt: Date
    /// The decoded battery reading.
    let battery: BatteryState
}
