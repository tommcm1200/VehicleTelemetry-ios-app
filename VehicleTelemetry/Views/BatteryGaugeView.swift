//
//  BatteryGaugeView.swift
//  VehicleTelemetry
//
//  A large, glanceable state-of-charge ring. Shows a neutral placeholder when
//  state of charge is unknown.
//

import SwiftUI

struct BatteryGaugeView: View {
    /// State of charge 0...100, or nil if unknown.
    let stateOfCharge: Double?
    /// Dim the gauge when telemetry is not fresh.
    var isDimmed: Bool = false

    private var fraction: Double {
        guard let stateOfCharge else { return 0 }
        return min(1, max(0, stateOfCharge / 100))
    }

    private var tint: Color {
        guard let stateOfCharge else { return .secondary }
        switch stateOfCharge {
        case ..<20: return .red
        case ..<50: return .orange
        default: return .green
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 14)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(tint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: fraction)
            VStack(spacing: 2) {
                Text(TelemetryFormatting.stateOfCharge(stateOfCharge))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("STATE OF CHARGE")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .opacity(isDimmed ? 0.5 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("State of charge")
        .accessibilityValue(TelemetryFormatting.stateOfCharge(stateOfCharge))
    }
}

#Preview {
    BatteryGaugeView(stateOfCharge: 82)
}
