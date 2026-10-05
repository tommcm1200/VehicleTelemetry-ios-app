//
//  CarPlaySceneDelegate.swift
//  VehicleTelemetry
//
//  CarPlay "Driving Task" scene. Shows live battery telemetry on the car
//  display using a template-based information view (custom views are not
//  permitted in CarPlay). While this scene is active the system keeps the app
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
import os

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var refreshTimer: Timer?

    /// A single reused template; we update its `items` in place so the car
    /// display refreshes without rebuilding the root template.
    private let infoTemplate = CPInformationTemplate(
        title: "Battery",
        layout: .leading,
        items: [],
        actions: []
    )

    /// How often to refresh the car display. Covers both new readings and
    /// freshness aging (fresh -> stale). Kept modest; CarPlay throttles updates.
    private let refreshInterval: TimeInterval = 3

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        // Make sure telemetry is running even if the phone UI never appeared
        // (e.g. the user plugged into CarPlay with the phone locked).
        AppEnvironment.shared.startIfNeeded()
        AppEnvironment.shared.appState.resumeTelemetry()

        updateTemplate()
        interfaceController.setRootTemplate(infoTemplate, animated: false, completion: nil)
        startRefreshTimer()
        Log.widget.notice("CarPlay scene connected")
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        refreshTimer?.invalidate()
        refreshTimer = nil
        self.interfaceController = nil
        Log.widget.notice("CarPlay scene disconnected")
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

    private func updateTemplate() {
        let appState = AppEnvironment.shared.appState
        let now = Date()
        let battery = appState.battery
        let freshness = appState.freshness(now: now)

        // When unavailable, don't present stale numbers as if they were live.
        let showValues = freshness != .unavailable

        let items: [CPInformationItem] = [
            CPInformationItem(title: "State of Charge",
                              detail: showValues ? TelemetryFormatting.stateOfCharge(battery?.stateOfCharge) : TelemetryFormatting.placeholder),
            CPInformationItem(title: "Voltage",
                              detail: showValues ? TelemetryFormatting.voltage(battery?.voltage) : TelemetryFormatting.placeholder),
            CPInformationItem(title: "Current",
                              detail: showValues ? TelemetryFormatting.current(battery?.current) : TelemetryFormatting.placeholder),
            CPInformationItem(title: "Power",
                              detail: showValues ? TelemetryFormatting.power(battery?.power) : TelemetryFormatting.placeholder),
            CPInformationItem(title: "Consumed",
                              detail: showValues ? TelemetryFormatting.consumedAh(battery?.consumedAh) : TelemetryFormatting.placeholder),
            CPInformationItem(title: "Remaining",
                              detail: showValues ? TelemetryFormatting.timeRemaining(battery?.timeRemainingMinutes) : TelemetryFormatting.placeholder),
            CPInformationItem(title: "Status", detail: statusText(battery: battery, freshness: freshness, now: now))
        ]

        // Only reassign when something changed, to avoid a redundant display
        // refresh (and to stay well under CarPlay's update throttle).
        if infoTemplate.items.map(\.detail) != items.map(\.detail) {
            infoTemplate.items = items
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
