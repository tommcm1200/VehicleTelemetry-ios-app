//
//  AppEnvironment.swift
//  VehicleTelemetry
//
//  App-wide owner of the telemetry pipeline. Both the SwiftUI window scene and
//  the CarPlay scene share one BluetoothManager + AppState through this
//  singleton. This matters because CarPlay can be the only active scene (phone
//  locked, app projected to the car display), so the CarPlay scene must be able
//  to drive and read telemetry without the phone UI being on screen.
//

import Foundation

@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let bluetooth = BluetoothManager()
    let appState = AppState()

    private var started = false

    private init() {}

    /// Configure telemetry exactly once. Safe to call from either scene's
    /// connect path (whichever activates first wins; later calls are no-ops).
    func startIfNeeded() {
        guard !started else { return }
        started = true
        appState.configureTelemetry(bluetooth: bluetooth)
    }
}
