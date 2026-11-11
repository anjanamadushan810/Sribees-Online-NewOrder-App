# Sribees New Orders — branch order-management app (PLAN)

Owner brief (2026-11-10): today a new order is only seen if someone sits on the
admin web. Build a mobile app — **Sribees New Orders** — that does what the
admin web **Orders** page does, user-friendly, scoped by login (branch staff
see their branch, super admin sees all), and **alerts the phone the moment a
new order arrives**. The backend stays as-is except for the staff push alert.

Work is split into **phases**. Each phase is small, ends with its own
pass/fail check, and is committed on `development` before the next starts.

## Owner decisions (interview 2026-11-10)

| # | Question | Decision |
|---|---|---|
| 1 | Where | New standalone Flutter app, repo `anjanamadushan810/Sribees-Online-NewOrder-App` |
| 2 | Name | **Sribees New Orders** |
| 3 | Who gets the push | Every active admin/staff of the order's branch who holds `orders:read`, plus every super admin |
| 4 | When | When the order is really workable: COD/wallet at placement; card/bank only after payment is confirmed. Never for `awaiting_payment` |
| 5 | Sound | Dedicated "New orders" Android channel with its own sound (phone's silent mode still respected) |
| 6 | v1 scope | Daily work: list (tabs + counts + search), detail, status change, cancel, courier pickup + label, call customer. Returns / escalations / override / export stay on admin web for now |
| 7 | Language | Sinhala (default) + English switch; push text follows the device's choice |
| 8 | Login | Anyone the admin web lets see orders; buttons follow the same permissions |
| 9 | Release | Signed Android APK built by CI (manual dispatch), side-loaded; Play Store later |
| 10 | Delivery | Built phase by phase, each phase checked before the next |

## Guardrails (all phases)

- **Server is the only judge of scope.** `BranchScope` / `inject_branch_filter`
  already pins a branch admin to their branch; the app never filters for
  security, only for display.
- No change to order money logic, status rules, cancellation or courier
  booking — the app calls the same `/admin/orders` endpoints as the admin web.
- Staff alert must **never** break or slow checkout or payment confirmation:
  sent after commit, fire-and-forget, errors only logged.
- One alert per order, even if payment confirm races the reconciliation sweep.
- Times shown in Asia/Colombo; "x min ago" from the server `Date` header.
- Nothing hard-wired to Matugama — branch comes from the order.
- Dev first (`development` + dev API). `main`/prod only after the owner says yes.
- No test SMS, no paid AI calls. Test orders on dev only.
- App version == pubspec == Settings screen == APK file name.

## Phases

| Phase | What | Repo | Risk |
|---|---|---|---|
| P0 | Project setup + CI APK | app | low |
| P1 | Login, Settings, language | app | medium |
| P2 | Orders list | app | high (scope) |
| P3 | Order detail + status actions | app | medium |
| P4 | Staff push — backend | backend | high |
| P5 | Push in the app | app | medium |
| P6 | Courier panel | app | medium |
| P7 | Release to prod | both | high |

The core value (a phone that rings on a new order) lands at P5; P6 can move
after P7 if the owner wants alerts live sooner.

---

### P0 — Project setup + CI APK

- `flutter create`, name "Sribees New Orders", id `com.sribeesonline.sribees_new_orders`.
- Copy from Sribees Price: `lib/core/*` (Dio client, JWT refresh, secure
  storage, theme), Riverpod setup. Flavors `dev` (dev API) and `prod`.
- New release keystore in `Desktop/Sribees-Firebase-Backup/android-signing/sribees-new-orders/`;
  CI secrets `NEWORDERS_KEYSTORE_*`; workflow `build-apk.yml` (manual dispatch)
  producing `sribees-new-orders-<flavor>-<version>.apk`.
- `si` + `en` ARB files wired, Sinhala default.

**Done:** CI run green and the dev APK installs on an emulator and opens to a
placeholder screen showing the version; `flutter analyze` 0 issues.

### P1 — Login, Settings, language

- Login with admin web email + password (`/admin/auth/login`), token refresh,
  logout (`/admin/auth/logout`). Super admin picks a branch filter (optional);
  branch staff are fixed to their branch (shown, not changeable).
- Store `permissions` from login; a helper `can('orders','update')`.
- Settings: language si/en, signed-in name/role/branch, version, logout.
- Clear errors: wrong password, inactive account, "no branch assigned".

**Done:** on dev, a branch-manager login and a super-admin login both work;
Settings shows the right role + branch; logout returns to Login and a
restart stays logged out; widget tests for the login form pass.

### P2 — Orders list

- Status tabs mirroring admin web `ORDER_TABS` with badges from
  `status_counts`; search; date range; branch filter only when
  `scope.is_super_admin`; pull-to-refresh; infinite scroll (20/page).
- Card: order no., customer, item count, total, COD/Paid chip, branch,
  "placed 12 min ago" (amber > 15 min unprocessed, red > 30 min), NEW dot until
  opened on this device.
- Refresh on resume, on pull, and every 60 s only while this screen is
  visible in the foreground.
- Skeleton loading, empty state per tab, offline banner.

**Done:** `tools/scope_check.py` (dev API) passes — a branch-B login gets 0
branch-A orders in every tab and `GET /admin/orders/{A-order}` is refused;
super admin sees both. Tab counts in the app equal the admin web for the same
login and date range (screenshot pair).

### P3 — Order detail + status actions

- Status chip + horizontal stepper; one big primary action from
  `/next-statuses` (e.g. "Start packing" → "Packed" → "Ready for pickup")
  with a confirm sheet; Cancel with reason (same server rules as admin web).
- Customer block: tap-to-call, WhatsApp. Address: open in Maps.
- Items: photo, qty, weight option, line total. Payment: COD amount to collect
  in large type, Paid badge for card/wallet.
- Status history timeline. Buttons only when permissions allow; restrictions
  as a quiet ⓘ tap-to-reveal (owner tone). Haptic on success.

**Done:** a dev COD test order is moved Confirmed → Packing → Packed from the
app and the admin web shows the same status + history entries; a staff login
without `orders:update` sees no action buttons.

### P4 — Staff push — backend (`fastapi_backend`, `development` worktree)

1. **Migration 109_admin_push_tokens.sql** (107/108 were taken by then) (replay-safe, `IF NOT EXISTS`):
   - `admin_push_tokens(token_id, admin_id FK admins ON DELETE CASCADE, token UNIQUE,
     device_id, platform, app_name default 'new_orders', language 'si'|'en',
     is_active, created_at, updated_at, last_seen_at)`.
   - `admin_order_alerts(order_id PK FK orders, sent_at, recipients int)` —
     the idempotency latch (`INSERT … ON CONFLICT DO NOTHING`; send only if inserted).
2. **Endpoints** `/admin/push-tokens` (any logged-in admin):
   - `POST` register/refresh `{token, device_id, platform, language}` — upsert
     by token, re-bound to the *current* admin (a shared phone that changes
     user stops alerting the previous one).
   - `DELETE /{device_id}` on logout — deactivates that device for this admin.
3. **`StaffOrderAlertService.notify_new_order(db, order)`** called next to both
   existing `NotificationService.notify_order_placed(...)` calls in
   `order_service.py` (creation for COD/wallet; `update_payment_status` when an
   awaiting-payment order becomes confirmed).
   - Recipients: `admins.is_active` AND (`role = super_admin` OR
     (`branch_id = order.branch_id` AND effective permissions include `orders:read`)).
   - FCM via `FCMService.send_to_tokens`; Android `channel_id = new_orders`,
     `sound = new_order`, high priority; data `{type: new_order, order_id,
     order_number, branch_id}`. Title "Sribees New Orders"; body per token
     language (si/en): order no., item count, total, COD/paid, branch.
   - Tokens FCM reports as unregistered → `is_active = false`.
4. Tests `tests/test_staff_order_alerts.py`: branch A manager alerted, branch B
   not; super admin always; inactive admin / staff without `orders:read` not;
   `awaiting_payment` → none, then paid → exactly one; called twice → one;
   FCM raising → order still created; token re-bind on another admin's login.

**Done:** new tests + full suite green on Python 3.11, `ruff check .` clean,
migration 109 replays twice on a throwaway Postgres 18; fresh-context
reviewer agent signs off (max 3 rounds); deployed to dev.

### P5 — Push in the app

- Add the Android app to the Firebase project the backend sends from (owner's
  `npx firebase` login); register SHA-1/256; `google-services.json` per flavor.
- `firebase_messaging` + `flutter_local_notifications`; channel `new_orders`
  (importance max, `res/raw/new_order.mp3`); Android 13+ permission prompt
  with a one-line why.
- Register token after login + on `onTokenRefresh` + on language change;
  delete on logout.
- Foreground: in-app banner + sound + list refresh. Tap (background or
  closed app) → opens that order. Settings: "test the sound" (local only).

**Done:** with the dev APK, a COD test order on dev → notification with the
`new_orders` sound within 10 s → tap opens that order. A card order left in
`awaiting_payment` → no notification. After logout → no notification.

### P6 — Courier panel

- Request pickup (when `can_request_pickup`), view / share / print label,
  refresh tracking, COD-collected status — same endpoints as admin web
  `CourierPanel`.

**Done:** a dev order at Ready for pickup → Request pickup from the app →
label opens and shares as PDF; admin web shows the same booking.

### P7 — Release to prod (ask the owner first)

- Owner MCQ: promote backend `development` → `main` (migration 109 + alert
  hook) and deploy prod; build the prod-flavor APK.
- Install on the branch phones; first real order watched live.

**Done:** prod deploy run green; one real (or owner-placed COD) prod order
rings every branch phone and the super admin's; APK version check passes.

### P8 — Ring until accepted (owner interview 2026-11-11)

Owner decisions:
- **Accepted** = the order leaves `pending` (Confirm, or any later status,
  or cancelled), from the app OR the admin web. Opening it is not enough.
- One person accepting stops the ringing on **every** phone.
- Not accepted: ring again **every 2 min for 30 min** (max 15 rings), then stop.
- **Night 22:00–07:00 Colombo**: ring once on arrival only; at **07:00** every
  order still `pending` starts ringing again (same 2 min / 30 min rule).

Backend (`fastapi_backend`, development first):
1. Migration 110 (next free; re-check): `admin_order_alerts` gains
   `rings INT`, `next_ring_at TIMESTAMPTZ`, `stopped_at TIMESTAMPTZ`.
2. A scheduler job every minute: orders with an alert row, `stopped_at IS NULL`,
   `next_ring_at <= now()` → if status is no longer `pending` → stop; else
   re-send (same recipients rule) and schedule the next ring (or stop after 30
   min / 15 rings; inside night hours push `next_ring_at` to 07:00 Colombo).
   Multi-worker safe: `FOR UPDATE SKIP LOCKED`.
3. On accept (status leaves pending): stop + a silent data push
   `{type: order_accepted, order_id}` so phones clear the notification.
4. Tests on the real schema: re-ring cadence, stop on confirm (app and admin
   web path), 30-min cap, night hold + 07:00 restart, two workers ring once.

App:
- Each ring replaces the previous notification for that order (same tag), so
  the shade holds one per order. `order_accepted` data push clears it.

**Done:** on dev, a COD order not confirmed rings the emulator 3 times in
~5 min; confirming it from the admin web stops the next ring and clears the
notification; a night-time order rings once and again at 07:00 (tested with a
fake clock); full suite + migration replay x2 green; fresh reviewer signs off.

## Out of v1 (later)

Returns approve/reject, escalations, status override, CSV/PDF export, iOS,
Play Store listing, Bluetooth label printer.
