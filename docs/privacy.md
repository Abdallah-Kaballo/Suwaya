# Privacy Policy for Suwaya (سُويعَة)

**Last updated: September 11, 2026**

Abdallah Kaballo ("we", "our", or "us") develops and maintains Suwaya, an open-source Flutter application for astronomical prayer times, virtual Suwaya time, tasks, routines, and focus sessions. This policy explains what information the current version of the application accesses, how it is used, and where it is stored.

## 1. Scope and Current Data Model

The current application is local-first. It does not currently provide user accounts, authentication, cloud synchronization, or a configured remote database. The application does not include Firebase Crashlytics or Supabase in its current dependency configuration.

Most application data is stored on the device in an Isar Community database. The current database contains data for settings, tasks, routines, and saved geographic information. The application may also copy its bundled read-only city database to the device for local city search and location matching.

## 2. Information the Application Uses

### Location information

When you choose automatic location, Suwaya requests location permission and may use the device's last known position or a current position. Latitude and longitude are used locally to:

- Calculate prayer and astronomical times.
- Select a timezone-aware calculation context.
- Find an approximate nearest city and country using the bundled local city database.
- Suggest calculation method and Madhab defaults for the selected country.

The current location implementation does not send these coordinates to a Suwaya server. Suwaya does not use location to track movement in the background, build a movement history, or sell location data.

You can instead choose a location manually, where supported, and deny location permission. Some automatic-location functionality will then be unavailable.

### Application data

Depending on the features you use, Suwaya stores locally:

- Calculation preferences, language, theme, and notification settings.
- Selected or saved location details, such as coordinates, city, country, and timezone.
- Tasks, task dates, completion status, period/Suwaya context, and reminder settings.
- Routines and their scheduling information.

This data is used only to provide the corresponding application features and is not currently uploaded to a Suwaya cloud service.

### Notifications and alarms

If you enable them, Suwaya schedules notifications and alarms through the operating system. Notification titles, bodies, timing, sound, vibration, and alarm settings are used locally to deliver reminders. Suwaya does not receive a copy of these scheduled notifications from a remote notification server.

## 3. Information We Do Not Currently Collect

The current application does not intentionally collect or transmit:

- Account details or authentication identifiers.
- Advertising identifiers or behavioral analytics.
- Crash reports through Firebase Crashlytics.
- Location history or background movement data.
- Task, routine, or settings data through Supabase or another Suwaya cloud backend.
- Payment information.

The operating system, app store, and platform services may process technical information under their own privacy policies. This policy covers the Suwaya application code and its configured services.

## 4. Data Storage, Retention, and Deletion

Local data remains on the device until you delete it through an application feature, clear the application's storage, uninstall the application, or otherwise remove the relevant platform data. The exact behavior of uninstalling or clearing storage is controlled by the operating system.

Suwaya does not currently retain a server-side copy of local tasks, routines, settings, or locations. Before sharing a device or uninstalling the application, use the operating system's application-data controls as appropriate.

## 5. Permissions

Suwaya may request the following permissions depending on the features you use:

| Permission | Purpose |
|---|---|
| Location | Automatic location and location-aware prayer calculations |
| Notifications | Local task, routine, and prayer reminders |
| Exact alarms | Time-sensitive alarm scheduling where supported |
| Vibration | Local notification and alarm feedback |
| Internet | Platform or package operations that may require network access; no Suwaya cloud synchronization is currently configured |

Permissions are requested when the related feature needs them. You can deny or revoke permissions through the operating system settings, although related features may stop working.

## 6. Third-Party Libraries and Platform Services

Suwaya uses open-source libraries for Flutter, local persistence, prayer calculations, geolocation, geocoding, localization, notifications, alarms, and related UI functionality. These libraries may interact with operating-system APIs as required for their documented functions.

The current Suwaya project does not configure an advertising SDK, Firebase Crashlytics, Supabase authentication, or Supabase synchronization. Platform providers such as Android, iOS, desktop operating systems, and app stores may process data independently under their own terms.

## 7. Security

Local data protection depends partly on the security of the device and operating system. Keep your device protected with its normal security controls, and do not use a rooted or otherwise compromised device for sensitive data if that is a concern.

Although the project is designed to avoid sending ordinary application data to a Suwaya server, no software or device can guarantee absolute security. Report suspected security issues privately rather than publishing sensitive details in a public issue.

## 8. Children

Suwaya is not designed to knowingly collect personal information from children. Because the current application does not provide accounts or a Suwaya cloud data service, it does not intentionally create child user profiles or collect child data remotely.

## 9. Changes to This Policy

This policy may be updated when the application's data practices or enabled services change. The "Last updated" date at the top of this page indicates the latest revision. Material changes should be reflected in the project documentation and release information where appropriate.

## 10. Contact

For questions, corrections, or privacy concerns, contact the project maintainer by reporting an issue through the Suwaya GitHub repository:

<https://github.com/Abdallah-Kaballo/Suwaya>

Suwaya is open source and licensed under the GNU General Public License v3.0. Its source code is available for review in the repository.
