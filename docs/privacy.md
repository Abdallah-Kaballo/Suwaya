# Privacy Policy for Suwaya (سُويعَة)

**Last updated: October 2026**

Abdallah Kaballo ("we", "our", or "us") develops and maintains Suwaya, an open-source Flutter application for astronomical prayer times, virtual Suwaya time, tasks, routines, and focus sessions. This policy explains what information the current version of the application accesses, how it is used, and where it is stored.

## 1. Scope and Current Data Model

The current application operates on a **local-first** basis. It does not provide user accounts, authentication, cloud synchronization, or a configured remote database. 

Most application data is stored exclusively on your device within an Isar Community database. The current database contains your customized settings, tasks, habits, routines, and saved geographic information. The application also bundles a read-only SQLite database for local offline city search and location matching.

## 2. Information the Application Uses

### Location Information
When you opt to use automatic location detection, Suwaya requests location permissions and uses your device's coordinates locally to:
- Calculate precise prayer and astronomical times.
- Select the correct timezone context.
- Find your approximate nearest city and country via the bundled offline city database.
- Suggest accurate calculation methods and Madhab defaults.

**These coordinates are never sent to a Suwaya server.** Suwaya does not track your movement in the background, build a location history, or sell location data. You may alternatively choose a location manually and deny location permissions entirely.

### Application Data
Depending on the features you use, Suwaya stores locally:
- Calculation preferences, UI language, visual themes, and notification settings.
- Tasks, task schedules, completion history, streaks, and Suwaya contexts.
- Focus routines and their associated parameters.

### Notifications and Alarms
If enabled, Suwaya schedules local notifications and full-screen exact alarms through the operating system. Suwaya uses these to deliver time-sensitive reminders but does not transmit notification histories to any remote server.

## 3. Information We Do Not Collect & Supporter Purchases

The application does not collect or transmit:
- Personal authentication identifiers or account details.
- Advertising identifiers or behavioral analytics tracking.
- Task or routine data to any cloud backend.

If you optionally choose to purchase a Supporter Badge, Suwaya utilizes Google Play Billing (or Apple App Store) alongside the RevenueCat SDK to verify your entitlement via an anonymous app user ID. Financial and payment details are processed exclusively by the platform store and are never accessed, captured, or stored by Suwaya.

## 4. Data Storage, Retention, and Deletion

Local data remains on your device until you delete it through the app's interface, clear the application’s storage via your OS settings, or uninstall the application. Suwaya does not retain a server-side copy of your local tasks, routines, or settings.

## 5. Permissions

Suwaya may request the following system permissions to function correctly:

| Permission | Purpose |
|---|---|
| **Location** | For automatic location detection and location-aware prayer calculations. |
| **Notifications** | To deliver local task, routine, and prayer reminders. |
| **Exact Alarms** | To schedule time-sensitive, full-screen lockscreen alarms. |
| **Vibration** | To provide haptic feedback during local notifications and alarms. |
| **Internet** | To fetch Markdown documentation updates (FAQ/Privacy), check for app updates, and process optional Supporter badge purchases. |

You can deny or revoke these permissions at any time through your operating system settings.

## 6. Third-Party Libraries and Network Services

Suwaya uses open-source libraries for Flutter, local persistence (`isar_community`, `sqflite`), astronomical calculations (`adhan`), geolocation, localization, and notifications. Network access is strictly limited to:
- Fetching FAQ and Privacy Policy JSON updates directly from the official GitHub repository.
- Checking for in-app updates via official store APIs (`in_app_update`).
- Verifying optional supporter badge entitlements via Google Play Billing and RevenueCat.

## 7. Security

Local data protection depends on the security of your device and operating system. We strongly recommend keeping your device protected with standard security controls (PIN/Biometrics) and advise against using rooted or compromised devices if you store sensitive personal schedules.

## 8. Children

Suwaya is not designed to knowingly collect personal information from children. Because the application operates offline-first and provides no cloud account system, it does not intentionally create child user profiles or collect data remotely.

## 9. Changes to This Policy

This policy may be updated if the application's data practices evolve. The "Last updated" date at the top of this page indicates the latest revision. Material changes will be reflected in the project documentation and release notes.

## 10. Contact

For questions, corrections, or privacy concerns, please contact the project maintainer by opening an issue on the official Suwaya GitHub repository:

<https://github.com/Abdallah-Kaballo/Suwaya>

Suwaya is open-source and licensed under the GNU General Public License v3.0. Its source code is publicly available for review in the repository.

```