# Vehicle Telemetry

A native iOS app that receives Victron BMV battery telemetry broadcast over BLE
Instant Readout, decodes it locally on the iPhone, and displays the battery
state in the app, in a WidgetKit widget, and on a native CarPlay screen.

## Scope (V1)

- Receive Victron BMV Instant Readout BLE advertisements.
- Decode and decrypt them **locally on the device**. No backend, no cloud, no analytics.
- Show state of charge, voltage, current, power, consumed Ah and time remaining.
- Share a simplified battery snapshot with a `.systemSmall` widget via an App Group.

### Explicitly out of scope for V1

VRM cloud, Cerbo GX, multiple BMV devices, MPPT / Orion / OBD-II / TPMS / fridge
/ water tanks, historical charts, accounts, Apple Watch, Siri, and any generic
BLE profile builder. See the build plan for the full list. (A native CarPlay app
was added after V1, see "CarPlay" below.)

## CarPlay

A native CarPlay app (CarPlay **Driving Task** category; entitlement approved by
Apple on 2026-10-06) shows the battery readout on the car display, reusing the
same on-device Instant Readout pipeline through a shared `AppEnvironment`. The UI
is a `CPTabBarTemplate` (one "Battery" tab today, with room for future modules
such as TPMS as additional tabs) containing a `CPGridTemplate` of colored icon
tiles, titled with the device name. CarPlay is template-only, so there is no
custom gauge on the car screen.

**Screen-asleep limitation (important):** telemetry updates live while the
phone's **screen is awake** and CarPlay is connected, the phone may stay
**locked** (waking the screen is enough; unlocking is not required). When the
phone's **screen sleeps**, iOS treats the app as backgrounded for Bluetooth and
stops delivering manufacturer-data (Instant Readout) advertisement scans (which
have no service UUID to filter on), so no new reading arrives until the screen
wakes again. The CarPlay screen then holds the **last-known values** (seeded from
the shared snapshot) with a Stale / Unavailable status, and resumes live the
instant the screen wakes. This is the same iOS advertisement-scanning limitation
that affects the widget; live updates with the screen asleep would require a GATT
*connection*, which this BMV does not support (see the GATT spike notes).

Gotchas worth knowing (all handled in the code):

- The CarPlay entitlement is a *managed* capability: device builds fail to sign
  until Apple grants it and it is in the provisioning profile. See
  `CARPLAY_ENTITLEMENT_REQUEST.md`.
- The scene manifest is hand-authored in `Info.plist` with
  `INFOPLIST_KEY_UIApplicationSceneManifest_Generation = NO`. With generation on,
  Xcode emits an empty `UISceneConfigurations` and the CarPlay scene never
  connects ("Application does not implement CarPlay template application
  lifecycle methods").
- The CarPlay scene-delegate methods are `nonisolated` so UIKit can see them via
  `respondsToSelector:` under the project's `MainActor` default isolation.
- Xcode 27's Device Hub can't render CarPlay in the Simulator; validate on a
  physical iPhone via **CarPlay Simulator.app** (Additional Tools for Xcode).

## Background behaviour (important)

Victron Instant Readout is an *advertisement* broadcast (manufacturer data, no
service UUID). iOS only delivers advertisements to a backgrounded app when the
scan is filtered by a service UUID, so this design cannot receive telemetry while
the app is suspended. The app updates live while foreground / CarPlay-active; the
widget shows the **last known value with a freshness label** (fresh → stale →
unavailable) and refreshes when the app is next active. Telemetry is never
fabricated. True real-time background updates would require connecting to the BMV
over GATT, which is outside V1's Instant Readout scope.

## Privacy and security

- All BLE processing, cryptography, configuration and telemetry handling happen on device.
- The Victron Instant Readout encryption key is stored only in the Keychain. It is
  never written to UserDefaults, the App Group, the widget, logs, or diagnostics.
- The widget only ever receives already-decoded, non-secret telemetry.

## Project layout

- `VehicleTelemetry/` - the iOS app (SwiftUI).
- `VehicleTelemetryWidget/` - the WidgetKit extension (`.systemSmall`).
- `VehicleTelemetryTests/` - XCTest unit tests.
- `VehicleTelemetryUITests/` - XCTest UI tests (created by the template).

## Targets and identifiers

| Target | Bundle identifier |
| --- | --- |
| App | `com.tommcmeekin.VehicleTelemetry` |
| Widget | `com.tommcmeekin.VehicleTelemetry.Widget` |
| App Group | `group.com.tommcmeekin.VehicleTelemetry` |

## Requirements

- Xcode 27, iOS 17.0+ deployment target.
- A physical iPhone and a Victron BMV are required to validate the real BLE path
  (milestones 2 onward). The simulated path (milestone 1) needs only the Simulator.

## Victron protocol source

Authoritative source: Victron Energy, **"Extra Manufacturer Data" / BLE Instant
Readout advertising specification**, dated 2022-12-14
(`extra-manufacturer-data-2022-12-14.pdf`, published via the Victron community
site). Company identifier cross-checked against the Bluetooth SIG Assigned
Numbers list.

Facts used so far (nothing about the wire format is invented):

- **Company identifier `0x02E1`** (Victron Energy BV), little-endian in the BLE
  manufacturer-specific data. This is how we flag a device as Victron.
- Instant Readout values are sent as a **Product Advertisement**, marked by
  manufacturer-data record type **`0x10`** (the first byte after the company id).
- The record payload is **encrypted with AES-CTR**; the Instant Readout key is
  obtained by the device owner from VictronConnect.

The exact per-record field layout (device-type enumeration, nonce bytes, the
key-match byte, and the Battery Monitor bit offsets / scaling / NA sentinels) is
**deliberately not parsed during discovery (milestone 2)**. Those offsets are
confirmed against a real captured BMV packet before decoding is implemented
(milestones 3-4), per the build plan's "do not invent byte offsets" rule.

## Build status

See `DEVELOPMENT.md` for the current milestone, build/test status, and the
manual actions required of the device owner.
