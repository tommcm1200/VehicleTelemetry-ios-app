# Development Log

## Current milestone

**Milestone 8 - TestFlight Readiness** (readiness checks done; **final archive /
upload is a manual step via your Apple account** - see TESTFLIGHT.md).

## Gates passed (all on real hardware)

- **M1 - CarPlay:** widget rendered live in CarPlay.
- **M2 - scan capture:** real BMV advertisement captured.
- **M3 - decryption:** real VictronConnect key decrypted a Battery Monitor record.
- **M4 - decode comparison:** app matched VictronConnect exactly.
- **M5 - live telemetry:** real data drives dashboard + widget + CarPlay;
  auto-reconnects on relaunch. (Background goes stale by design - see limitation.)

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

## Build status

- Debug + **Release** build succeed, **0 warnings** (iPhone simulator, iOS 27.0).
- App icon installed and showing on the Home Screen.

## Tests

- **39 unit tests pass, 0 failed** across: BatteryState, TelemetryFreshness,
  SharedTelemetryStore, VictronAdvertisement, VictronCrypto (incl. NIST vector),
  VictronInstantReadoutRecord (real packet), VictronBMVDecoder, DeviceConfiguration.
- Keychain + live BLE source validated on-device via the gates above.

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
