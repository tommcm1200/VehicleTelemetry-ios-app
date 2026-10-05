# TestFlight Release Process

Internal, private distribution of Vehicle Telemetry to Tom's iPhone.

## Prerequisites

- Apple Developer Program membership (for TestFlight / App Store Connect).
- Signing Team set on both targets (`VehicleTelemetry` and
  `VehicleTelemetryWidgetExtension`) with automatic signing. The App Group
  `group.com.tommcmeekin.VehicleTelemetry` must be enabled on the App ID (Xcode
  does this automatically when the capability is present and a team is set).

## Pre-flight checklist (verified in-repo where possible)

- [x] Release build succeeds (`xcodebuild ... -configuration Release`).
- [x] Unit tests pass (39).
- [x] Widget extension is embedded in the app.
- [x] Bundle identifiers: app `com.tommcmeekin.VehicleTelemetry`,
      widget `com.tommcmeekin.VehicleTelemetry.Widget`.
- [x] App Group entitlement on app + widget.
- [x] `NSBluetoothAlwaysUsageDescription` present.
- [x] `UIBackgroundModes = [bluetooth-central]` present.
- [x] No DEBUG-only functionality in Release (the simulator source is behind
      `#if DEBUG`).
- [x] No encryption key bundled; key lives only in the Keychain.
- [x] No secrets committed (only public NIST AES test vectors in tests).
- [ ] Signing Team selected (manual, in Xcode).
- [ ] Marketing version / build number set for the release.

## Steps

1. **Set version/build:** target `VehicleTelemetry` > General > set Version (e.g.
   1.0) and Build (e.g. 1). Bump Build for each upload.
2. **Signing:** target > Signing & Capabilities > select your Team (both targets).
3. **Run destination:** choose "Any iOS Device (arm64)".
4. **Archive:** Product > Archive. (Xcode-only; the MCP tools can build but not
   drive the interactive Organizer/App Store Connect auth.)
5. **Validate:** in the Organizer, Validate App.
6. **Distribute:** Distribute App > App Store Connect > Upload (TestFlight).
7. **App Store Connect:** create the app record if needed (first upload), wait for
   processing, then add yourself as an Internal Tester under TestFlight.
8. **Install:** accept the TestFlight invite on your iPhone and install.

## Notes

- Do not place Apple credentials in source or config. Interactive auth happens in
  Xcode / App Store Connect only.
- Encryption export compliance: the app uses only standard Apple cryptography
  (AES via CommonCrypto) for local decryption; set
  `ITSAppUsesNonExemptEncryption` = NO (exempt) when prompted, or add it to
  Info.plist to skip the question. Confirm this is accurate for your submission.
