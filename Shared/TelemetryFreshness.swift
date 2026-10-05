//
//  TelemetryFreshness.swift
//  VehicleTelemetry
//
//  How recent a telemetry reading is. Shared between the app and the widget
//  so both present the same semantics. Never show stale telemetry as live.
//

import Foundation

/// Freshness of a telemetry reading relative to now.
nonisolated enum TelemetryFreshness: Equatable {
    case fresh
    case stale
    case unavailable
}

/// Centrally configurable thresholds for `TelemetryFreshness`.
///
/// - `fresh`:       age `< freshBelow`
/// - `stale`:       `freshBelow ... staleBelow` (inclusive on both ends)
/// - `unavailable`: age `> staleBelow`
nonisolated struct TelemetryFreshnessThresholds: Equatable {
    /// Readings younger than this are `fresh`. Default 30 seconds.
    var freshBelow: TimeInterval
    /// Readings at or below this (but not fresh) are `stale`. Default 5 minutes.
    var staleBelow: TimeInterval

    static let `default` = TelemetryFreshnessThresholds(freshBelow: 30, staleBelow: 5 * 60)
}

nonisolated extension TelemetryFreshness {
    /// Evaluate freshness from a reading's age in seconds.
    ///
    /// A negative age (a timestamp in the future, e.g. clock skew) is treated
    /// as `fresh`.
    static func evaluate(
        age: TimeInterval,
        thresholds: TelemetryFreshnessThresholds = .default
    ) -> TelemetryFreshness {
        if age < thresholds.freshBelow {
            return .fresh
        } else if age <= thresholds.staleBelow {
            return .stale
        } else {
            return .unavailable
        }
    }

    /// Evaluate freshness of a timestamp relative to `now`.
    static func of(
        timestamp: Date,
        now: Date = Date(),
        thresholds: TelemetryFreshnessThresholds = .default
    ) -> TelemetryFreshness {
        evaluate(age: now.timeIntervalSince(timestamp), thresholds: thresholds)
    }
}
