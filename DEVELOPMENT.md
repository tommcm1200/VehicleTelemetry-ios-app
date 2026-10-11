# Development Log

## Current milestone

**Milestone 8 - TestFlight Readiness** (readiness checks done; **final archive /
upload is a manual step via your Apple account** - see TESTFLIGHT.md).

**CarPlay (post-V1):** native CarPlay "Driving Task" app shipped and validated on
hardware (entitlement approved by Apple 2026-10-06). See README "CarPlay".

## Gates passed (all on real hardware)

- **M1 - CarPlay:** widget rendered live in CarPlay.
- **M2 - scan capture:** real BMV advertisement captured.
- **M3 - decryption:** real VictronConnect key decrypted a Battery Monitor record.
- **M4 - decode comparison:** app matched VictronConnect exactly.
- **M5 - live telemetry:** real data drives dashboard + widget + CarPlay;
  auto-reconnects on relaunch. (Background goes stale by design - see limitation.)
- **CarPlay app:** native Driving Task app renders the live battery grid on the
  car display, titled with the device name (validated via CarPlay Simulator.app
  on a physical iPhone, since Xcode 27's Device Hub can't render CarPlay).

## Completed

- **M0 Foundation:** iOS-only project, 4 targets, App Group, deploy target 17.0.
- **M1 Simulated dashboard + widget:** shared telemetry layer, `@Observable`
  state, dashboard with freshness states, `.systemSmall` widget via App Group.
- **M2 BLE discovery:** `BluetoothManager`, discovery + diagnostics,
  `VictronAdvertisement.identify` (company id 0x02E1 + 0x10 marker).
- **M3 Encryption:** `VictronCrypto` AES-128-CTR (CommonCrypto, NIST-validated),
  `SecureKeyStore` (Keychain only), key onboarding + Save-and-Test.
- **M4 Decoder:** `VictronBMVDecoder` (spec bit layout, scaling, NA sentinels),
  validated against VictronConnect.
- **M5 End-to-end:** `VictronBMVSource` + `DeviceConfiguration`; live path
  scan -> decrypt -> decode -> dashboard -> App Group -> widget; simulation is
  DEBUG-only.
- **M6 Background:** `bluetooth-central` mode + state restoration; background
  snapshot flush + widget reload; foreground resume; honest freshness lifecycle.
- **M7 Production polish:** `SettingsView` (change BMV / change key / forget /
  diagnostics), release-safe `os.Logger` categories (never logs secrets),
  force-unwrap hardening, and an **app icon** (green charge gauge + bolt).
- **M8 readiness:** Release build passes; repo secret scan clean (only public
  NIST test vectors + a Keychain constant); `TESTFLIGHT.md` written.
- **CarPlay (post-V1):** native CarPlay Driving Task app. Shared `AppEnvironment`
  drives one telemetry pipeline for the phone + CarPlay scene (so CarPlay runs
  without the phone UI); `CPTabBarTemplate` ("Battery" tab, room for TPMS) with a
  `CPGridTemplate` of colored icon tiles titled with the device name. Updates
  live while the phone **screen is awake** (locked is fine); when the screen
  sleeps iOS stops delivering the advertisement scan, so it shows the last-known
  snapshot (Stale/Unavailable) until the screen wakes. Entitlement approved by
  Apple 2026-10-06. Gotchas handled:
  `INFOPLIST_KEY_UIApplicationSceneManifest_Generation = NO` (else Xcode emits an
  empty scene manifest), and `nonisolated` scene-delegate methods (else UIKit
  can't see them under `MainActor` default isolation). See README "CarPlay".

## Build status

- Debug + **Release** build succeed, **0 warnings** (iPhone simulator, iOS 27.0).
- App icon installed and showing on the Home Screen.

## Tests

- **41 tests pass, 0 failed** (39 unit + 2 UI) across: BatteryState,
  TelemetryFreshness, SharedTelemetryStore, VictronAdvertisement, VictronCrypto
  (incl. NIST vector), VictronInstantReadoutRecord (real packet),
  VictronBMVDecoder, DeviceConfiguration.
- Keychain + live BLE source + CarPlay scene validated on-device via the gates above.

## Manual actions required

### Optional on-device spot-check (M6/M7)

- Confirm the new app icon shows, Settings works (Change BMV / Change Key /
  Forget BMV), and background goes to STALE then recovers on foreground.

### >>> MILESTONE 8 - TESTFLIGHT (manual, your Apple account) <<<

Follow `TESTFLIGHT.md`: set Team on both targets, set version/build, Archive in
Xcode, Validate, and Distribute to App Store Connect > TestFlight, then install
via the TestFlight app. Xcode MCP can build/inspect but cannot drive the
interactive Organizer / App Store Connect authentication.

## Decisions / flags

- **Background is best-effort:** iOS does not deliver manufacturer-data
  advertisements to a suspended app, so the widget shows last value + freshness
  and refreshes when the app is foreground/CarPlay-active. Accepted as V1
  behaviour (true real-time background would need a GATT connection, out of
  scope). See README "Background behaviour".
- Power is derived (V x I), matching VictronConnect.
- AES-CTR via CommonCrypto; key-check byte self-validates the key.
- Shared `Shared/` synchronized folder; committed shared scheme; `@Observable`.

## Known issues

- Xcode widget *preview* rendering times out via MCP (preview-service infra);
  builds and device unaffected.

## Definition of Done (V1)

Remaining to tick are TestFlight install + on-device re-confirmation of the full
checklist in the build plan (§39). Everything build-side and decode-side is done
and validated against real hardware.
