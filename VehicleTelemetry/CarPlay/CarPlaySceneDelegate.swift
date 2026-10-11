//
//  CarPlaySceneDelegate.swift
//  VehicleTelemetry
//
//  CarPlay "Driving Task" scene. Shows live battery telemetry on the car
//  display using template-based views (a tab bar containing a battery grid;
//  custom views are not permitted in CarPlay). The tab bar leaves room for
//  future modules (e.g. TPMS) as additional tabs. While this scene is active
//  the system keeps the app
//  running, so the existing Instant Readout advertisement scanning continues to
//  deliver live data even while the phone is locked. This is the same approach
//  VictronConnect uses for its CarPlay readout.
//
//  Requires the `com.apple.developer.carplay-driving-task` entitlement, which
//  Apple grants per app on request. The entitlement is present for simulator
//  testing; shipping to a real car requires Apple's approval (see
//  CARPLAY_ENTITLEMENT_REQUEST.md).
//

import CarPlay
import Foundation
import UIKit
import os

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var refreshTimer: Timer?

    /// The Battery tab's grid (icon + value tiles), rebuilt as telemetry
    /// arrives. Created on connect so its title can be the device name. The
    /// root is a CPTabBarTemplate so future modules (e.g. TPMS) slot in as more
    /// tabs. CarPlay chooses the grid's column count and caps buttons at 8.
    private var gridTemplate: CPGridTemplate?

    /// How often to refresh the car display. Covers both new readings and
    /// freshness aging (fresh -> stale). Kept modest; CarPlay throttles updates.
    private let refreshInterval: TimeInterval = 3

    // These delegate methods are `nonisolated` so Swift emits plain Objective-C
    // thunks that UIKit can see via `respondsToSelector:`. Under this project's
    // `MainActor` default isolation, a main-actor-isolated witness is not
    // recognised by CarPlay and the scene connection throws "Application does
    // not implement CarPlay template application lifecycle methods". CarPlay
    // calls these on the main thread, so hopping onto the main actor is safe.
    // (Same pattern as `BluetoothManager`'s Core Bluetooth delegate.)

    nonisolated func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        MainActor.assumeIsolated {
            self.interfaceController = interfaceController

            // Make sure telemetry is running even if the phone UI never appeared
            // (e.g. the user plugged into CarPlay with the phone locked).
            AppEnvironment.shared.startIfNeeded()
            AppEnvironment.shared.appState.resumeTelemetry()
            // Show last-known values immediately (esp. when launched locked,
            // where live scanning can't run until unlock).
            AppEnvironment.shared.appState.seedFromStoreIfNeeded()

            let grid = self.makeBatteryTab()
            self.gridTemplate = grid
            self.updateTemplate()

            // A tab bar lets future modules (TPMS, etc.) slot in as more tabs.
            let tabBar = CPTabBarTemplate(templates: [grid])
            interfaceController.setRootTemplate(tabBar, animated: false, completion: nil)
            self.startRefreshTimer()
            Log.widget.notice("CarPlay scene connected")
        }
    }

    nonisolated func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        MainActor.assumeIsolated {
            self.refreshTimer?.invalidate()
            self.refreshTimer = nil
            self.interfaceController = nil
            Log.widget.notice("CarPlay scene disconnected")
        }
    }

    /// On a cold launch straight into CarPlay, `didConnect` can start the scan
    /// before this scene is foreground-active (and before Bluetooth powers on),
    /// so the first scan happens in a momentary background state and returns
    /// nothing. When the CarPlay scene actually becomes active, (re)start the
    /// scan in the foreground, this is the CarPlay equivalent of the phone app's
    /// `scenePhase == .active` resume, and fixes "no metrics until I open the
    /// phone app".
    nonisolated func sceneDidBecomeActive(_ scene: UIScene) {
        MainActor.assumeIsolated {
            AppEnvironment.shared.startIfNeeded()
            AppEnvironment.shared.appState.resumeTelemetry()
            AppEnvironment.shared.appState.seedFromStoreIfNeeded()
            self.updateTemplate()
        }
    }

    // MARK: Rendering

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateTemplate()
            }
        }
    }

    /// Build the Battery tab's grid. Its CarPlay title is the device name (as
    /// shown in the app, e.g. "SmartBMV HQ…"); the tab itself is "Battery".
    private func makeBatteryTab() -> CPGridTemplate {
        let deviceName = AppEnvironment.shared.appState.sourceName ?? "Battery"
        let grid = CPGridTemplate(title: deviceName, gridButtons: [])
        grid.tabTitle = "Battery"
        grid.tabImage = UIImage(systemName: "minus.plus.batteryblock.fill")
        return grid
    }

    private func updateTemplate() {
        let appState = AppEnvironment.shared.appState
        let now = Date()
        let battery = appState.battery
        let freshness = appState.freshness(now: now)

        // When unavailable, don't present stale numbers as if they were live.
        let showValues = freshness != .unavailable
        let soc = showValues ? battery?.stateOfCharge : nil
        let current = showValues ? battery?.current : nil
        let power = showValues ? battery?.power : nil

        func value(_ formatted: String) -> String { showValues ? formatted : TelemetryFormatting.placeholder }

        // Order defines the grid flow; CarPlay lays these out across columns
        // (one row on this wide simulator, ~two rows on a real head unit).
        let buttons: [CPGridButton] = [
            tile(value(TelemetryFormatting.stateOfCharge(battery?.stateOfCharge)),
                 socSymbol(soc), socColor(soc)),
            tile(value(TelemetryFormatting.voltage(battery?.voltage)),
                 "bolt.fill", .systemBlue),
            tile(value(TelemetryFormatting.current(battery?.current)),
                 "arrow.left.arrow.right", flowColor(current)),
            tile(value(TelemetryFormatting.power(battery?.power)),
                 "bolt.horizontal.fill", flowColor(power)),
            tile(value(TelemetryFormatting.consumedAh(battery?.consumedAh)),
                 "minus.plus.batteryblock.fill", .systemTeal),
            tile(value(TelemetryFormatting.timeRemaining(battery?.timeRemainingMinutes)),
                 "clock.fill", .systemBlue),
            tile(statusText(battery: battery, freshness: freshness, now: now),
                 statusSymbol(freshness), statusColor(freshness))
        ]

        gridTemplate?.updateGridButtons(buttons)
    }

    // MARK: Tile + icon helpers

    /// A read-only grid tile: a colored icon above a single value label. We show
    /// value-only (no metric name) so every tile reads consistently; the icon
    /// identifies the metric. The handler is a no-op (the UI is informational).
    private func tile(_ value: String, _ symbolName: String, _ color: UIColor) -> CPGridButton {
        let image = symbol(symbolName, color) ?? UIImage()
        return CPGridButton(titleVariants: [value], image: image) { _ in }
    }

    /// A colour-preserving SF Symbol icon for a CarPlay list row.
    ///
    /// CarPlay treats a list item's SF Symbol as a *template* and re-tints it
    /// with the system label colour (which lands near-black on the dark CarPlay
    /// theme, so our colour is lost). To keep our colour we resolve it in the
    /// dark appearance, bake it into the symbol, then rasterise to a plain
    /// bitmap. A bitmap is not a template symbol, so CarPlay renders it as-is.
    private func symbol(_ name: String, _ color: UIColor) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        guard let base = UIImage(systemName: name, withConfiguration: config) else { return nil }
        let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        let tinted = base.withTintColor(resolved, renderingMode: .alwaysOriginal)
        let renderer = UIGraphicsImageRenderer(size: tinted.size)
        return renderer.image { _ in
            tinted.draw(in: CGRect(origin: .zero, size: tinted.size))
        }.withRenderingMode(.alwaysOriginal)
    }

    private func socSymbol(_ soc: Double?) -> String {
        guard let soc else { return "battery.0percent" }
        switch soc {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    private func socColor(_ soc: Double?) -> UIColor {
        guard let soc else { return .systemGray }
        switch soc {
        case ..<20: return .systemRed
        case ..<50: return .systemOrange
        default: return .systemGreen
        }
    }

    /// Green when energy flows into the battery (charging), amber when it flows
    /// out (discharging), grey at rest. Matches the app's sign convention.
    private func flowColor(_ value: Double?) -> UIColor {
        guard let value else { return .systemGray }
        if value > 0.05 { return .systemGreen }
        if value < -0.05 { return .systemOrange }
        return .systemGray
    }

    private func statusSymbol(_ freshness: TelemetryFreshness) -> String {
        switch freshness {
        case .fresh: return "dot.radiowaves.left.and.right"
        case .stale: return "exclamationmark.triangle.fill"
        case .unavailable: return "antenna.radiowaves.left.and.right.slash"
        }
    }

    private func statusColor(_ freshness: TelemetryFreshness) -> UIColor {
        switch freshness {
        case .fresh: return .systemGreen
        case .stale: return .systemOrange
        case .unavailable: return .systemGray
        }
    }

    private func statusText(battery: BatteryState?, freshness: TelemetryFreshness, now: Date) -> String {
        guard let battery else { return "Waiting for telemetry" }
        let age = TelemetryFormatting.shortAge(since: battery.timestamp, now: now)
        switch freshness {
        case .fresh: return "Live · \(age)"
        case .stale: return "Stale · \(age)"
        case .unavailable: return "Unavailable · last \(age)"
        }
    }
}
