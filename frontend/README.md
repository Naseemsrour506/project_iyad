# Safe Kid App — Flutter Frontend

Hebrew, right-to-left parent-facing client for the **SafeChat AI** backend.

A parent can register, log in, manage child profiles, submit a Hebrew message
for analysis, and review the resulting category, risk level, confidence and
explanation — plus dashboard statistics, message history and alerts.

The client talks **only** to the FastAPI backend. It never contacts the
database or the AI module directly.

---

## Requirements

| Tool | Version |
|---|---|
| Flutter SDK | 3.41.4 (stable) or newer |
| Dart SDK | 3.11.1 (bundled with Flutter) |

Verify with:

```bash
flutter --version
```

---

## Installing dependencies

```bash
cd frontend
flutter pub get
```

### Packages used

| Package | Purpose |
|---|---|
| `http` | HTTP client for the REST API |
| `provider` | State management (`ChangeNotifier`) |
| `flutter_secure_storage` | Secure persistence of the JWT access token |
| `intl` | Date formatting |

No code-generation packages are used.

---

## Running the app

### Chrome (web)

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Android emulator

An Android emulator cannot reach the host machine through `127.0.0.1`, because
that address points at the emulator itself. Use the special alias
**`10.0.2.2`** instead:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For a physical Android device on the same Wi-Fi network, use the host
machine's LAN address, for example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

### Supplying `API_BASE_URL`

The base URL is read at compile time via `String.fromEnvironment`:

```bash
--dart-define=API_BASE_URL=http://127.0.0.1:8000
```

If the flag is omitted, the app falls back to the development default
`http://127.0.0.1:8000` (see [lib/core/api_constants.dart](lib/core/api_constants.dart)).

The same flag works for `flutter build`:

```bash
flutter build web --dart-define=API_BASE_URL=https://api.example.com
```

---

## Running the tests

```bash
flutter test
```

All tests are self-contained: HTTP is mocked with `package:http/testing.dart`
and services are replaced with in-memory fakes, so **no running backend is
required**.

Coverage includes model JSON parsing, `ApiException` / FastAPI `detail`
extraction, `ApiService` headers and error mapping, `AuthProvider` and
`AlertsProvider` behaviour, form validators, login-screen validation,
registration password confirmation, dashboard stats parsing and app startup /
session restoration.

Also useful before committing:

```bash
dart format .
flutter analyze
```

---

## Backend

Development base URL:

```text
http://127.0.0.1:8000
```

Every application endpoint is prefixed with `/api`. Endpoints consumed by this
client:

```text
GET    /api/health
POST   /api/auth/register
POST   /api/auth/login
GET    /api/auth/me
POST   /api/children
GET    /api/children
GET    /api/children/{child_id}
POST   /api/analyze
GET    /api/messages
GET    /api/messages?child_id={id}
GET    /api/dashboard/stats
GET    /api/alerts
GET    /api/alerts?unread_only=true
GET    /api/alerts/unread-count
PATCH  /api/alerts/{alert_id}/read
```

The planned endpoints (`/api/analyze/batch`, `/api/messages/upload`,
`/api/reports`, `/api/reports/export`) are **not** implemented in this client,
because they are not yet available on the backend.

Start the backend from the repository root:

```bash
cd backend
uvicorn app.main:app --reload
```

---

## ⚠️ Known backend requirement: CORS

**The backend does not currently register `CORSMiddleware`.** Running the
frontend in Chrome will therefore fail on every API call with a browser CORS
error, which this client surfaces as
*"לא ניתן להתחבר לשרת"* (cannot reach the server).

This is a backend change and has intentionally **not** been made from the
frontend branch. The backend owner needs to add the following to
`backend/app/main.py`:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # development only
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

Notes:

- `allow_origins=["*"]` is fine for local development. For a deployed build,
  list the real origins instead.
- `allow_methods` must include `PATCH`, which is used to mark alerts as read.
- Android and desktop builds are unaffected — CORS is a browser-only
  restriction — so the app can be demonstrated on an Android emulator even
  before this change lands.

---

## JWT handling

1. On startup the app shows a splash screen and reads the stored token through
   `TokenStorageService`.
2. If no token exists, the login screen opens.
3. If a token exists, the app calls `GET /api/auth/me` to validate it.
   - Success → the authenticated shell opens with the restored user.
   - `401` / `403` → the token is deleted and the login screen opens.
4. `POST /api/auth/login` returns `access_token`; it is written to secure
   storage immediately.
5. Every protected request sends:

   ```http
   Authorization: Bearer <access_token>
   Content-Type: application/json
   ```

6. A `401` / `403` from **any** request triggers a central callback
   (`ApiService.onUnauthorized`) that clears the session and returns the user
   to login, so an expired token cannot leave the UI in a broken state.
7. Logging out deletes the token and resets all feature providers, so data
   never leaks between accounts on a shared device.

Security rules enforced in the code:

- The user's password is **never** stored — it is passed to the login/register
  call and discarded.
- The JWT is **never** logged or printed. Secure-storage failures log a generic
  message only.
- No secrets or tokens are committed in source.

`flutter_secure_storage` is wrapped behind the `TokenStorageService`
abstraction ([lib/services/token_storage_service.dart](lib/services/token_storage_service.dart)),
so no other file depends on the package directly. If the secure backend is
unavailable (for example a browser with storage disabled), the service falls
back to a session-only in-memory token rather than crashing.

---

## Folder structure

```text
frontend/lib/
├── main.dart                       # entry point
├── app.dart                        # service graph, providers, MaterialApp, AuthGate
│
├── core/
│   ├── api_constants.dart          # base URL (dart-define) + endpoint paths
│   ├── api_exception.dart          # single exception type, FastAPI "detail" extraction
│   ├── app_theme.dart              # Material 3 theme + risk colours
│   ├── app_routes.dart             # named routes
│   └── app_localization.dart       # Hebrew labels for API enums, date/percent formatting
│
├── models/                         # null-safe models with fromJson
│   ├── json_parsing.dart           # shared defensive parsing helpers
│   ├── user_model.dart
│   ├── child_model.dart
│   ├── analysis_result_model.dart
│   ├── message_model.dart
│   ├── dashboard_stats_model.dart
│   └── alert_model.dart
│
├── services/                       # one class per API area
│   ├── api_service.dart            # the only place HTTP is spoken
│   ├── token_storage_service.dart
│   ├── auth_service.dart
│   ├── children_service.dart
│   ├── analysis_service.dart
│   ├── messages_service.dart
│   ├── dashboard_service.dart
│   └── alerts_service.dart
│
├── providers/                      # ChangeNotifier state
│   ├── auth_provider.dart
│   ├── children_provider.dart
│   ├── dashboard_provider.dart
│   ├── messages_provider.dart      # history + analysis
│   └── alerts_provider.dart
│
├── screens/
│   ├── splash/splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── auth_scaffold.dart      # shared centered card layout
│   │   └── auth_validators.dart    # shared form rules
│   ├── dashboard/dashboard_screen.dart
│   ├── children/
│   │   ├── children_screen.dart
│   │   └── add_child_screen.dart
│   ├── analysis/analyze_message_screen.dart
│   ├── history/message_history_screen.dart
│   └── alerts/alerts_screen.dart
│
└── widgets/
    ├── main_navigation.dart        # NavigationBar (mobile) / NavigationRail (web)
    ├── app_loading_indicator.dart
    ├── app_error_view.dart         # full-screen error + inline banner
    ├── empty_state.dart
    ├── dashboard_stat_card.dart    # stat card + proportional bar row
    ├── risk_badge.dart             # risk badge + neutral info chip
    └── responsive_content.dart     # readable max-width wrapper
```

UI widgets never call the API directly — they read from providers, and
providers call services.

---

## Design notes

- **Material 3**, calm teal palette; strong colours are reserved for actual
  risk indicators (green / orange / red for Low / Medium / High).
- **Right-to-left**: the whole app is wrapped in `Directionality.rtl`.
- **Responsive**: below 900 px the shell uses a `NavigationBar`; at or above
  900 px it switches to a `NavigationRail`. Grids reflow by available width and
  page content is capped at a readable max width.
- **No charting package**: the dashboard uses proportional bars, which keeps
  the dependency list small.
- Every list screen has explicit loading, empty, error and refresh states.

---

## Validation rules

Applied on the client to match the backend contract:

| Field | Rule |
|---|---|
| Full name (register / child) | 2–120 characters |
| Email | valid address format |
| Password (register) | 8–128 characters |
| Confirm password | must match |
| Child age | 1–18 |
| Message | must not be empty |
| Analysis | a child must be selected |

Login only requires a non-empty password, so an existing account is never
locked out by a client-side length rule.

## Error handling

`ApiException` extracts FastAPI's `detail` field (including the list form used
by `422` responses) and maps it to a friendly Hebrew message:

| Status | Behaviour |
|---|---|
| 200 / 201 | success |
| 401 / 403 | session cleared, redirect to login |
| 404 | "not found or not yours" |
| 409 | duplicate email |
| 422 | "some fields are invalid" |
| 500 | generic server error |
| network / timeout | connection guidance |
