//
//  DeviceConfiguration.swift
//  VehicleTelemetry
//
//  Remembers which BMV the app is configured to read, so it reconnects on
//  launch. Contains no secrets (the key lives in the Keychain, keyed by the
//  same device id).
//

import Foundation

struct DeviceConfiguration: Codable, Equatable {
    let deviceID: UUID
    let name: String

    private static let defaultsKey = "configuredDevice"

    static func load(from defaults: UserDefaults = .standard) -> DeviceConfiguration? {
        guard let data = defaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(DeviceConfiguration.self, from: data)
    }

    func save(to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    static func clear(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: defaultsKey)
    }
}
