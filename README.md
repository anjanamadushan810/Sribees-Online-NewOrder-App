# Sribees New Orders

Android app for Sribees Online branch staff: see and manage the branch's
orders, and get a loud alert the moment a new order arrives. It uses the same
`/admin/orders` API as the admin web; the server decides which branch a login
may see. Plan and phases: [PLAN.md](PLAN.md).

## Flavors

| Flavor | Backend | App id | Name on phone |
|---|---|---|---|
| `dev` | `devapionline.sribees.com` | `com.sribeesonline.sribees_new_orders.dev` | Sribees New Orders DEV |
| `prod` | `api.sribeesonline.com` | `com.sribeesonline.sribees_new_orders` | Sribees New Orders |

Anything that is not the `prod` flavor (including `flutter test`) talks to dev.

## Build

- CI: Actions → **Build Sribees New Orders APK** → pick `dev` or `prod`
  (manual only). Signs with the release key from the `NEWORDERS_*` secrets
  and fails if the APK version differs from `pubspec.yaml`.
- Local (Windows): `cd android && gradlew assembleDevRelease -Pkotlin.incremental=false`
  (the flag avoids a Kotlin incremental-cache crash on Windows).
- Version: change `version:` in `pubspec.yaml` only; never pass
  `--build-name` / `--build-number`.

## Language

Sinhala (default) and English, in `lib/l10n/app_si.arb` / `app_en.arb`.
`flutter pub get` regenerates `lib/l10n/generated/`.
