//
//  TelemetryFormatting.swift
//  VehicleTelemetry
//
//  Presentation-only formatting for telemetry values. Kept out of the
//  decoding layer. Shared so the app and widget render values identically.
//  A nil value renders as a neutral placeholder, never as a fabricated zero.
//

import Foundation

nonisolated enum TelemetryFormatting {
    static let placeholder = "--"

    static func stateOfCharge(_ value: Double?) -> String {
        guard let value else { return placeholder }
        return "\(Int(value.rounded()))%"
    }

    static func voltage(_ value: Double?) -> String {
        guard let value else { return placeholder }
        return String(format: "%.2f V", value)
    }

    static func current(_ value: Double?) -> String {
        guard let value else { return placeholder }
        return String(format: "%.1f A", value)
    }

    static func power(_ value: Double?) -> String {
        guard let value else { return placeholder }
        return "\(Int(value.rounded())) W"
    }

    static func consumedAh(_ value: Double?) -> String {
        guard let value else { return placeholder }
        return String(format: "%.1f Ah", value)
    }

    static func timeRemaining(_ minutes: Int?) -> String {
        guard let minutes, minutes >= 0 else { return placeholder }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours) h \(String(format: "%02d", mins)) m"
        }
        return "\(mins) m"
    }

    /// A short relative age such as "8s ago" or "2m ago".
    static func shortAge(since timestamp: Date, now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(timestamp).rounded()))
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }

    /// A longer relative age such as "8 seconds ago" or "2 minutes ago".
    static func longAge(since timestamp: Date, now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(timestamp).rounded()))
        if seconds < 60 {
            return "\(seconds) second\(seconds == 1 ? "" : "s") ago"
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        }
        let hours = minutes / 60
        return "\(hours) hour\(hours == 1 ? "" : "s") ago"
    }
}
