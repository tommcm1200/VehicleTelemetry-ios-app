//
//  VehicleTelemetryWidget.swift
//  VehicleTelemetryWidget
//
//  A glanceable .systemSmall battery widget. It reads the latest normalised
//  snapshot from the App Group and never scans BLE itself. Freshness semantics
//  match the app: stale telemetry is never shown as live.
//

import WidgetKit
import SwiftUI

struct BatteryWidgetEntry: TimelineEntry {
    let date: Date
    let battery: BatteryState?

    var freshness: TelemetryFreshness {
        guard let battery else { return .unavailable }
        return TelemetryFreshness.of(timestamp: battery.timestamp, now: date)
    }
}

struct Provider: TimelineProvider {
    private func sampleBattery(at date: Date) -> BatteryState {
        BatteryState(
            deviceID: "SAMPLE", timestamp: date,
            stateOfCharge: 82, voltage: 13.24, current: -4.2,
            power: -56, consumedAh: -37, timeRemainingMinutes: 860
        )
    }

    func placeholder(in context: Context) -> BatteryWidgetEntry {
        BatteryWidgetEntry(date: Date(), battery: sampleBattery(at: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (BatteryWidgetEntry) -> Void) {
        let battery = loadBattery() ?? sampleBattery(at: Date())
        completion(BatteryWidgetEntry(date: Date(), battery: battery))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BatteryWidgetEntry>) -> Void) {
        let now = Date()
        guard let battery = loadBattery() else {
            // Nothing stored yet: show unavailable and check back soon.
            let entry = BatteryWidgetEntry(date: now, battery: nil)
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60))))
            return
        }

        // Schedule entries at the freshness transition points so the widget
        // moves fresh -> stale -> unavailable even without an app write.
        let thresholds = TelemetryFreshnessThresholds.default
        var dates: [Date] = [now]
        let staleAt = battery.timestamp.addingTimeInterval(thresholds.freshBelow)
        let unavailableAt = battery.timestamp.addingTimeInterval(thresholds.staleBelow)
        if staleAt > now { dates.append(staleAt) }
        if unavailableAt > now { dates.append(unavailableAt) }

        let entries = dates.sorted().map { BatteryWidgetEntry(date: $0, battery: battery) }
        // After it goes unavailable, keep refreshing to update the "ago" text.
        let refreshAfter = max(unavailableAt, now).addingTimeInterval(60)
        completion(Timeline(entries: entries, policy: .after(refreshAfter)))
    }

    private func loadBattery() -> BatteryState? {
        guard let store = SharedTelemetryStore() else { return nil }
        return (try? store.load())?.battery
    }
}

struct VehicleTelemetryWidgetEntryView: View {
    var entry: BatteryWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BATTERY")
                .font(.caption2).fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if entry.freshness == .unavailable {
                Spacer(minLength: 0)
                Text("Unavailable")
                    .font(.headline)
                if let battery = entry.battery {
                    Text(TelemetryFormatting.shortAge(since: battery.timestamp, now: entry.date))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            } else {
                Text(TelemetryFormatting.stateOfCharge(entry.battery?.stateOfCharge))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .opacity(entry.freshness == .stale ? 0.5 : 1)

                HStack {
                    Text(TelemetryFormatting.voltage(entry.battery?.voltage))
                    Spacer()
                    Text(TelemetryFormatting.current(entry.battery?.current))
                }
                .font(.caption).monospacedDigit()
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)
                footer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var footer: some View {
        if entry.freshness == .stale {
            Text("STALE")
                .font(.caption2).fontWeight(.bold)
                .foregroundStyle(.orange)
        } else if let battery = entry.battery {
            Text("Updated \(TelemetryFormatting.shortAge(since: battery.timestamp, now: entry.date))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct VehicleTelemetryWidget: Widget {
    let kind: String = "VehicleTelemetryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VehicleTelemetryWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Battery")
        .description("Vehicle battery state of charge, voltage and current.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    VehicleTelemetryWidget()
} timeline: {
    BatteryWidgetEntry(
        date: .now,
        battery: BatteryState(
            deviceID: "SAMPLE", timestamp: .now,
            stateOfCharge: 82, voltage: 13.24, current: -4.2,
            power: -56, consumedAh: -37, timeRemainingMinutes: 860
        )
    )
}
