# Privacy Policy

**Product:** Galactic Calendar (Albancal)  
**Applies to:** Private Beta / TestFlight builds that store data on-device only  
**Last updated:** 2026-07-30  

> This document describes the shipped private-beta build. Have counsel review before a public App Store release.  
> Host the published HTML at `GCPrivacyPolicyURL` in `Resources/ConfigFiles/Info.plist`.

## Overview

Galactic Calendar is a personal calendar for iPhone, iPad, and macOS. In this beta, calendar data and reminders stay on your device.

## Data processed on device

| Data | Purpose | Leaves the device? |
|------|---------|--------------------|
| Events you create (title, notes, schedule, tags, preferences) | Core calendar features | **No** — local SwiftData store |
| Local notification schedules | Remind you of upcoming events | **No** — UserNotifications on device |
| Favorite / history state for Universe Messages | In-app inspiration features | **No** |

## Data we do not collect in this build

- No account or sign-in  
- No analytics or advertising identifiers  
- No cross-app or cross-site tracking (`NSPrivacyTracking` = false)  
- No CloudKit / iCloud event sync  
- No EventKit access to Apple Calendar  
- No widgets or Apple Watch companion  

## Notifications

The app may ask for permission to show **local** alerts, sounds, and badges. You can change this anytime in system Settings.

## Third parties

This build does not embed third-party analytics or advertising SDKs. System frameworks (SwiftUI, SwiftData, UserNotifications) operate under Apple’s policies.

## Contact

Privacy questions: [privacy@albancal.com](mailto:privacy@albancal.com)  
Support: [support@albancal.com](mailto:support@albancal.com)
