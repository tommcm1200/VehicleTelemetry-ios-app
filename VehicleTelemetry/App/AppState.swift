//
//  AppState.swift
//  VehicleTelemetry
//
//  Owns the current battery state, persists snapshots for the widget, and
//  drives the active telemetry source. In V1 the only source is the
//  DEBUG-only simulator; real BLE arrives in later milestones.
//

import Foundation
import SwiftUI
import Observation
import WidgetKit
import os

@MainActor
@Observable
final class AppState {
    /// The most recent decoded reading, or nil if nothing has arrived yet.
    private(set) var battery: BatteryState?
    /// Human-readable name of the active source.
    private(set) var sourceName: String?

    @ObservationIgnored private var source: TelemetrySource?
    @ObservationIgnored private let store: TelemetrySnapshotStore?
    @ObservationIgnored private weak var bluetooth: BluetoothManager?
    @ObservationIgnored private let keyStore = SecureKeyStore()

    /// Coalesce widget reloads so we don't reload on every advertisement.
    @ObservationIgnored private var lastWidgetReload: Date = .distantPast
    @ObservationIgnored private let widgetReloadInterval: TimeInterval = 15

    init(store: TelemetrySnapshotStore? = SharedTelemetryStore()) {
        self.store = store
    }

    /// Freshness of the current reading relative to `now`.
    func freshness(now: Date = Date()) -> TelemetryFreshness {
        guard let battery else { return .unavailable }
        return TelemetryFreshness.of(timestamp: battery.timestamp, now: now)
    }

    /// Attach and start a telemetry source.
    func use(_ source: TelemetrySource) {
        self.source?.stop()
        source.onUpdate = { [weak self] battery in
            self?.ingest(battery)
        }
        self.source = source
        self.sourceName = source.name
        source.start()
    }

    func stop() {
        source?.stop()
    }

    /// Returning to the foreground: resume scanning so live telemetry continues.
    func resumeTelemetry() {
        bluetooth?.startScanning()
    }

    /// Entering the background: push the latest reading to the widget immediately
    /// (bypassing the reload throttle). Freshness still comes from the reading's
    /// own timestamp, so a stale reading is never presented as fresh. iOS will
    /// not deliver new advertisements while suspended, so this is the last update
    /// the widget gets until the app is foreground/CarPlay-active again.
    func enterBackground() {
        guard let battery, let store else { return }
        try? store.save(TelemetrySnapshot(generatedAt: Date(), battery: battery))
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Name of the currently configured device, if any.
    var configuredDeviceName: String? { DeviceConfiguration.load()?.name }

    /// Forget the configured BMV: stop live telemetry, delete the Keychain key,
    /// clear the remembered device and the shared snapshot.
    func forgetDevice() {
        stop()
        source = nil
        if let config = DeviceConfiguration.load() {
            try? keyStore.delete(for: config.deviceID.uuidString)
        }
        DeviceConfiguration.clear()
        try? store?.clear()
        battery = nil
        sourceName = nil
        WidgetCenter.shared.reloadAllTimelines()
        Log.telemetry.info("Forgot configured device; key and snapshot cleared")
#if DEBUG
        startSimulation()
#endif
    }

    /// Reset all configuration (same as forgetting the device in V1).
    func resetConfiguration() {
        forgetDevice()
    }

#if DEBUG
    /// Start the simulated BMV source. DEBUG builds only.
    func startSimulation() {
        use(SimulatedBMVSource())
    }
#endif

    /// Decide what drives telemetry at launch: a configured real BMV if one is
    /// set up (device remembered + key in the Keychain), otherwise - in DEBUG
    /// only - the simulator. In Release with no configured device, the dashboard
    /// stays "unavailable" until a device is set up.
    func configureTelemetry(bluetooth: BluetoothManager) {
        self.bluetooth = bluetooth
        if let config = DeviceConfiguration.load(),
           keyStore.hasKey(for: config.deviceID.uuidString) {
            startLiveTelemetry(deviceID: config.deviceID, name: config.name)
        } else {
#if DEBUG
            startSimulation()
#endif
        }
    }

    /// Start reading the real BMV and remember it for next launch.
    func startLiveTelemetry(deviceID: UUID, name: String) {
        guard let bluetooth else { return }
        DeviceConfiguration(deviceID: deviceID, name: name).save()
        use(VictronBMVSource(deviceID: deviceID, name: name, bluetooth: bluetooth, keyStore: keyStore))
    }

    /// Handle a new reading: update state, persist a snapshot, nudge the widget.
    private func ingest(_ battery: BatteryState) {
        self.battery = battery
        persist(battery)
    }

    private func persist(_ battery: BatteryState) {
        guard let store else { return }
        let snapshot = TelemetrySnapshot(generatedAt: Date(), battery: battery)
        do {
            try store.save(snapshot)
            reloadWidgetIfNeeded()
        } catch {
            // Persistence failures are non-fatal for the dashboard.
        }
    }

    private func reloadWidgetIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastWidgetReload) >= widgetReloadInterval else { return }
        lastWidgetReload = now
        WidgetCenter.shared.reloadAllTimelines()
    }
}
