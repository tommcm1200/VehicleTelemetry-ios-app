//
//  SharedTelemetryStore.swift
//  VehicleTelemetry
//
//  Persists the latest TelemetrySnapshot into the App Group container so the
//  widget can read it. Only normalised, non-secret telemetry is stored here.
//  The Victron encryption key must NEVER be written through this store.
//

import Foundation

/// Reads and writes the latest telemetry snapshot.
protocol TelemetrySnapshotStore {
    /// Persist the latest snapshot, replacing any previous one.
    func save(_ snapshot: TelemetrySnapshot) throws
    /// Load the latest snapshot, or `nil` if none has been written yet.
    /// Throws if a snapshot exists but cannot be decoded.
    func load() throws -> TelemetrySnapshot?
    /// Remove any stored snapshot (e.g. when forgetting the device).
    func clear() throws
}

/// A `TelemetrySnapshotStore` backed by a JSON file in the App Group container.
nonisolated struct SharedTelemetryStore: TelemetrySnapshotStore {
    /// The App Group shared between the app and the widget.
    static let appGroupIdentifier = "group.com.tommcmeekin.VehicleTelemetry"
    /// File name of the snapshot inside the container.
    static let fileName = "telemetry-snapshot.json"

    /// The file the snapshot is read from and written to.
    let fileURL: URL

    private static func makeCoder() -> (JSONEncoder, JSONDecoder) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (encoder, decoder)
    }

    /// Create a store writing to an explicit file URL. Used by tests.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Create a store backed by the App Group container. Returns `nil` if the
    /// App Group is not available (e.g. entitlement missing).
    init?(
        appGroupIdentifier: String = SharedTelemetryStore.appGroupIdentifier,
        fileName: String = SharedTelemetryStore.fileName
    ) {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        else {
            return nil
        }
        self.fileURL = container.appendingPathComponent(fileName)
    }

    func save(_ snapshot: TelemetrySnapshot) throws {
        let (encoder, _) = Self.makeCoder()
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    func load() throws -> TelemetrySnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        let (_, decoder) = Self.makeCoder()
        return try decoder.decode(TelemetrySnapshot.self, from: data)
    }

    func clear() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
