//
//  TelemetrySource.swift
//  VehicleTelemetry
//
//  A minimal abstraction so future telemetry sources can be added without
//  rewriting the dashboard. This is intentionally NOT a generic plug-in
//  framework.
//

import Foundation

/// Something that produces `BatteryState` readings over time.
@MainActor
protocol TelemetrySource: AnyObject {
    /// Stable identifier for the source.
    var id: String { get }
    /// Human-readable name shown in the UI.
    var name: String { get }
    /// Called on the main actor whenever a new reading is produced.
    var onUpdate: ((BatteryState) -> Void)? { get set }

    /// Begin producing readings.
    func start()
    /// Stop producing readings.
    func stop()
}
