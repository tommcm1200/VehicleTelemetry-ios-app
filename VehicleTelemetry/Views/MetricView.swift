//
//  MetricView.swift
//  VehicleTelemetry
//
//  A labelled telemetry value shown on the dashboard.
//

import SwiftUI

struct MetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .monospacedDigit()
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    MetricView(label: "Voltage", value: "13.24 V")
}
