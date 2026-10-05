//
//  DashboardView.swift
//  VehicleTelemetry
//
//  The main battery dashboard. Prioritises state of charge, then voltage,
//  current, power, consumed Ah, time remaining, and freshness. Stale telemetry
//  is never presented as live.
//

import SwiftUI
import Combine

struct DashboardView: View {
    @Environment(AppState.self) private var appState

    // Drives the "updated N seconds ago" text and freshness re-evaluation.
    @State private var now = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let battery = appState.battery
        let freshness = appState.freshness(now: now)

        VStack(spacing: 24) {
            Text(appState.sourceName ?? "No source")
                .font(.headline)
                .foregroundStyle(.secondary)

            if freshness == .unavailable {
                unavailableView(battery: battery)
            } else {
                liveView(battery: battery, freshness: freshness)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onReceive(tick) { now = $0 }
    }

    @ViewBuilder
    private func liveView(battery: BatteryState?, freshness: TelemetryFreshness) -> some View {
        BatteryGaugeView(
            stateOfCharge: battery?.stateOfCharge,
            isDimmed: freshness == .stale
        )

        MetricView(label: "Voltage", value: TelemetryFormatting.voltage(battery?.voltage))

        HStack(spacing: 16) {
            MetricView(label: "Current", value: TelemetryFormatting.current(battery?.current))
            MetricView(label: "Power", value: TelemetryFormatting.power(battery?.power))
        }

        HStack(spacing: 16) {
            MetricView(label: "Consumed", value: TelemetryFormatting.consumedAh(battery?.consumedAh))
            MetricView(label: "Remaining", value: TelemetryFormatting.timeRemaining(battery?.timeRemainingMinutes))
        }

        freshnessFooter(battery: battery, freshness: freshness)
    }

    @ViewBuilder
    private func freshnessFooter(battery: BatteryState?, freshness: TelemetryFreshness) -> some View {
        VStack(spacing: 4) {
            if let battery {
                Text("Updated \(TelemetryFormatting.longAge(since: battery.timestamp, now: now))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Waiting for telemetry")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if freshness == .stale {
                Text("STALE")
                    .font(.caption).bold()
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Telemetry is stale")
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func unavailableView(battery: BatteryState?) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Battery telemetry unavailable")
                .font(.title3).fontWeight(.medium)
                .multilineTextAlignment(.center)
            if let battery {
                Text("Last received \(TelemetryFormatting.longAge(since: battery.timestamp, now: now))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 48)
    }
}

#Preview {
    DashboardView()
        .environment(AppState(store: nil))
}
