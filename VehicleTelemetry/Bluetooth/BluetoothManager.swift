//
//  BluetoothManager.swift
//  VehicleTelemetry
//
//  Owns Core Bluetooth. Scans for advertisements, identifies Victron devices,
//  and exposes discovery results plus diagnostics counters. The widget never
//  touches this - only the main app owns Bluetooth.
//
//  Milestone 2 scope: discovery and diagnostics only. No connection, no
//  decryption, no decoding yet.
//

import Foundation
import CoreBluetooth
import Observation
import os

@MainActor
@Observable
final class BluetoothManager: NSObject {
    // MARK: Published state

    private(set) var state: CBManagerState = .unknown
    private(set) var isScanning = false
    private(set) var devices: [DiscoveredDevice] = []
    private(set) var selectedDeviceID: UUID?

    // MARK: Diagnostics counters

    private(set) var advertisementsReceived = 0
    private(set) var victronAdvertisementsIdentified = 0
    private(set) var lastAdvertisementAt: Date?
    private(set) var lastVictronAdvertisementAt: Date?

    @ObservationIgnored private var central: CBCentralManager!
    @ObservationIgnored private var indexByID: [UUID: Int] = [:]

    /// Called whenever a device is seen/updated. The live telemetry source uses
    /// this to decode advertisements for the configured device.
    @ObservationIgnored var onDeviceUpdate: ((DiscoveredDevice) -> Void)?

    /// When true, `stopScanning()` is ignored so continuous telemetry keeps
    /// flowing even as discovery views come and go.
    @ObservationIgnored var keepScanning = false

    /// Identifier for Core Bluetooth state restoration.
    static let restoreIdentifier = "VehicleTelemetryCentral"

    override init() {
        super.init()
        central = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionRestoreIdentifierKey: Self.restoreIdentifier]
        )
    }

    var selectedDevice: DiscoveredDevice? {
        guard let selectedDeviceID else { return nil }
        return devices.first { $0.id == selectedDeviceID }
    }

    /// Human-readable Bluetooth state for the UI.
    var stateDescription: String {
        switch state {
        case .poweredOn: return "Powered on"
        case .poweredOff: return "Powered off"
        case .unauthorized: return "Unauthorized"
        case .unsupported: return "Unsupported"
        case .resetting: return "Resetting"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }

    // MARK: Scanning

    func startScanning() {
        guard central.state == .poweredOn else { return }
        isScanning = true
        // Victron Instant Readout data rides in general advertisements'
        // manufacturer data, so we scan without a service filter. Duplicates
        // are allowed so RSSI and manufacturer data stay current.
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stopScanning() {
        // Keep scanning when a live telemetry source needs it.
        if keepScanning { return }
        if central.state == .poweredOn { central.stopScan() }
        isScanning = false
    }

    func clear() {
        devices.removeAll()
        indexByID.removeAll()
    }

    /// Select a device. We never auto-select; this is always user-driven.
    func select(_ id: UUID) {
        selectedDeviceID = id
    }

    // MARK: Ingestion (called on the main actor)

    fileprivate func ingest(_ ad: BLEAdvertisement) {
        advertisementsReceived += 1
        lastAdvertisementAt = ad.timestamp
        if ad.victron != nil {
            victronAdvertisementsIdentified += 1
            lastVictronAdvertisementAt = ad.timestamp
        }

        let device: DiscoveredDevice
        if let i = indexByID[ad.identifier] {
            devices[i].update(with: ad)
            device = devices[i]
        } else {
            indexByID[ad.identifier] = devices.count
            let new = DiscoveredDevice(advertisement: ad)
            devices.append(new)
            device = new
        }
        onDeviceUpdate?(device)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    // Core Bluetooth calls these on the queue we created the manager with
    // (the main queue), so hopping onto the main actor is safe.

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MainActor.assumeIsolated {
            self.state = central.state
            Log.bluetooth.notice("Bluetooth state: \(self.stateDescription, privacy: .public)")
            if central.state == .poweredOn, self.isScanning || self.keepScanning {
                self.startScanning()
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        // Core Bluetooth relaunched us. Resume scanning if a live source wanted it.
        MainActor.assumeIsolated {
            if self.keepScanning { self.startScanning() }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name
        let identifier = peripheral.identifier
        let rssi = RSSI.intValue
        let ad = BLEAdvertisement(
            identifier: identifier,
            name: name,
            rssi: rssi,
            manufacturerData: manufacturerData,
            timestamp: Date()
        )
        MainActor.assumeIsolated {
            self.ingest(ad)
        }
    }
}
