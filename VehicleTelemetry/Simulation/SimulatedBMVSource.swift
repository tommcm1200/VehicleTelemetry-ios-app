//
//  SimulatedBMVSource.swift
//  VehicleTelemetry
//
//  A telemetry source that produces slowly, realistically varying battery
//  readings. DEBUG-only: simulation must never ship in a Release build.
//

#if DEBUG
import Foundation

/// Produces simulated BMV telemetry that drifts slowly and stays internally
/// consistent (power tracks voltage x current).
@MainActor
final class SimulatedBMVSource: TelemetrySource {
    let id = "SIM-BMV-712"
    let name = "BMV-712 Smart (Simulated)"
    var onUpdate: ((BatteryState) -> Void)?

    /// How often a new reading is produced.
    private let interval: TimeInterval
    private var timer: Timer?

    // Slowly varying internal state, seeded at the plan's starting values.
    private var stateOfCharge: Double = 82.0      // percent
    private var voltage: Double = 13.24           // volts
    private var current: Double = -4.2            // amps (discharging)
    private var consumedAh: Double = -37.0        // amp-hours

    init(interval: TimeInterval = 2.0) {
        self.interval = interval
    }

    func start() {
        stop()
        // Emit one reading immediately so the UI is populated at once.
        emit()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.step()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Advance the simulation by one step with small, bounded random walks.
    private func step() {
        // Current wanders slowly between about -6 A and -1 A (always a load).
        current += Double.random(in: -0.3...0.3)
        current = min(-0.5, max(-6.0, current))

        // Voltage sags slightly with heavier current and jitters a little.
        voltage += Double.random(in: -0.02...0.02)
        voltage = min(13.6, max(12.0, voltage))

        // State of charge creeps down slowly while discharging. A ~5 A load on
        // a ~100 Ah bank is about 5%/hour, i.e. current/1800 per 2 s step.
        stateOfCharge += (current / 1800.0) + Double.random(in: -0.002...0.002)
        stateOfCharge = min(100.0, max(0.0, stateOfCharge))

        // Consumed amp-hours accumulates with the current draw.
        consumedAh += current * (interval / 3600.0)
        consumedAh = max(-200.0, min(0.0, consumedAh))

        emit()
    }

    private func emit() {
        // Power is derived to stay consistent with voltage x current.
        let power = (voltage * current).rounded()

        // Time remaining: a rough estimate from consumed Ah and current draw.
        let timeRemainingMinutes: Int?
        if current < -0.1 {
            // Assume a 100 Ah usable bank; remaining capacity vs. draw rate.
            let remainingAh = max(0.0, 100.0 + consumedAh)
            let hours = remainingAh / abs(current)
            timeRemainingMinutes = Int((hours * 60.0).rounded())
        } else {
            timeRemainingMinutes = nil
        }

        let battery = BatteryState(
            deviceID: id,
            timestamp: Date(),
            stateOfCharge: (stateOfCharge * 10).rounded() / 10,
            voltage: (voltage * 100).rounded() / 100,
            current: (current * 10).rounded() / 10,
            power: power,
            consumedAh: (consumedAh * 10).rounded() / 10,
            timeRemainingMinutes: timeRemainingMinutes
        )
        onUpdate?(battery)
    }
}
#endif
