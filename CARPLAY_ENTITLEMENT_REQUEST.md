# CarPlay Entitlement Request (Driving Task)

Vehicle Telemetry needs the **CarPlay Driving Task** entitlement
(`com.apple.developer.carplay-driving-task`) to show live battery telemetry on
the car display. This is the same CarPlay category VictronConnect uses for its
in-car Instant Readout.

## Why Driving Task

The app displays a driver-glanceable, read-only battery status (state of charge,
voltage, current, power, consumed Ah, time remaining) for a Victron battery
monitor in the vehicle. It is not navigation, audio, communication, EV-charging,
parking, or food ordering. "Driving Task" is Apple's category for apps that let a
driver complete a short, driving-related task or glance at vehicle-related
status, which is exactly this use.

## How to request (Apple Developer account holder)

CarPlay entitlements are granted by Apple per app. You must request the specific
entitlement and sign the CarPlay Entitlement Addendum; Apple reviews it before
enabling the managed capability on the App ID.

1. Go to the CarPlay entitlement request page:
   https://developer.apple.com/contact/carplay/
2. Sign in with the Account Holder Apple ID for the developer account.
3. Select the **Driving Task** app category.
4. Paste the description below (edit to taste).
5. Submit and sign the CarPlay addendum when prompted.
6. After approval, enable the capability on the App ID, regenerate the
   provisioning profile, and keep `com.apple.developer.carplay-driving-task` in
   `VehicleTelemetry/VehicleTelemetry.entitlements` (already present).

## Suggested description to paste

> Vehicle Telemetry is a private battery-monitor companion app for a Victron
> battery monitor installed in my vehicle. On the car display it presents a
> single, read-only CarPlay information template showing current battery state:
> state of charge, voltage, current, power, consumed amp-hours, and estimated
> time remaining, plus a freshness indicator. Data is read locally over
> Bluetooth Low Energy (Victron Instant Readout advertisements) and decoded on
> device; there is no cloud service. The CarPlay interface uses only standard
> templates (CPInformationTemplate), is non-interactive beyond viewing, and
> updates a few times per minute so the driver can glance at battery status
> while driving (for example, in a camper/van or boat power system). This is the
> same category and purpose as VictronConnect's CarPlay readout.

## Notes

- Until Apple grants the entitlement, the CarPlay scene runs only in the
  **CarPlay Simulator** (Simulator does not enforce the managed entitlement).
- A real car (device build / TestFlight) will not show the app on CarPlay until
  the entitlement is approved and in the provisioning profile.
- The CarPlay UI is template-only by Apple policy, so the in-app SwiftUI gauge is
  not shown on the car display; the car shows labelled value rows instead.
