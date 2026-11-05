# Fetching API (Mobile) — AI Agent Reference

Required guide for agents / developers who add or change HTTP calls from the
Flutter app to the DermaScan backend.

> **Do not guess** paths, body fields, status codes, or property names.
> Source of truth = OpenAPI, then implement under `services/`.

---

## 1. Workflow (follow in order)

Before writing any fetching code, complete these steps **in order**:

### Step A — Read the OpenAPI contract

| Source | Path |
|---|---|
| Snapshot (committed) | [`backend/openapi.json`](../backend/openapi.json) |
| Live Swagger | https://api-docs-pbl.trialdyk.my.id/ |
| Live schema | https://api-docs-pbl.trialdyk.my.id/openapi.json |

From `openapi.json`, extract:

1. **`paths`** → HTTP method + path (`POST /auth/login`, etc.).
2. **`requestBody` → `content` → `application/json` → `schema`**
   (often a `$ref` to `#/components/schemas/...`).
3. **`components.schemas.<SchemaName>`** → **properties**, types,
   `required`, `minLength` / `maxLength` / `pattern`, and `description`.
4. **`responses`** → success statuses (`200` / `201`) and errors (`400`,
   `401`, `409`, `422`). Read the response schema (e.g. `AuthResponse`).
5. Notes in `info.description` or the operation description: whether the
   endpoint is **public** or **protected** (requires Bearer).

### Step B — Decide auth

| Kind | Header | Examples |
|---|---|---|
| Public | No Bearer | `POST /auth/login`, `/auth/register`, `/auth/google`, `GET /health` |
| Protected | `Authorization: Bearer <access_token>` | `/users/*`, `/items/*`, future scan endpoints |

The token comes from the `access_token` field in the auth response (login /
register / google).

### Step C — Implement under `services/`

Mobile fetching code **only** lives in:

```text
mobile/lib/data/services/
```

Folder layout **per domain**:

```text
mobile/lib/data/services/
├── api_client.dart          # shared HTTP + Bearer header
├── auth/                    # auth domain
│   ├── auth.dart            # barrel export
│   ├── auth_service.dart    # facade
│   ├── auth_login.dart      # 1 file ≈ 1 endpoint
│   ├── auth_register.dart
│   ├── auth_google.dart
│   └── auth_exception.dart
└── scan/                    # scan / protected example
    ├── scan.dart
    ├── scan_service.dart
    └── scan_status.dart
```

Naming rules:

- Folder = domain (`auth/`, `scan/`, …).
- Endpoint file = `<domain>_<action>.dart` (e.g. `auth_login.dart`).
- Facade = `<domain>_service.dart` (used by repository / cubit).
- Barrel = `<domain>.dart` (exports the domain files).

### Step D — Wire the UI

Service → Repository → Cubit → Screen. Do **not** call `http` directly from
widgets or cubits.

---

## 2. Base URL & config

| Item | Location / value |
|---|---|
| Mobile config | [`mobile/lib/core/api_config.dart`](../mobile/lib/core/api_config.dart) |
| Default production | `https://pbl.trialdyk.my.id` |
| Run override | `flutter run --dart-define=API_BASE_URL=...` |
| HTTP client | [`mobile/lib/data/services/api_client.dart`](../mobile/lib/data/services/api_client.dart) |

Default headers from `ApiClient`:

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <token>   # only when auth: true and a token is set
```

---

## 3. How to read an OpenAPI schema (login example)

In `backend/openapi.json`:

1. Open `paths["/auth/login"].post`.
2. Check `requestBody` → `$ref` to `LoginRequest`.
3. Open `components.schemas.LoginRequest` — required properties typically:

| Property | Type | Notes |
|---|---|---|
| `email` | string | Trimmed & lowercased on the server |
| `password` | string | min/max per schema |
| `accepted_terms` | boolean | must be `true` |
| `accepted_privacy` | boolean | must be `true` |

4. Success response `200` → `AuthResponse`:

| Property | Meaning |
|---|---|
| `access_token` | JWT for Bearer |
| `token_type` | usually `bearer` |
| `expires_in` | seconds |
| `user` | user object (`id`, `email`, `full_name`, …) |

**Always match JSON field names to the schema** (`accepted_terms`, not
`acceptedTerms` on the wire). Dart model mapping is separate (see
`UserModel.fromAuthJson`).

If the schema changes: update `openapi.json` on the backend first
(`python scripts/export_openapi.py`), then change the mobile service.

---

## 4. ApiClient — fetch pattern

```dart
final api = ApiClient();

// Public (no Bearer)
final res = await api.post('/auth/login', body: {
  'email': 'pengguna@gmail.com',
  'password': 'skinscan123',
  'accepted_terms': true,
  'accepted_privacy': true,
});

// After login: store the token
api.accessToken = decoded['access_token'] as String;

// Protected (sends Authorization: Bearer …)
final status = await api.get('/users/status', auth: true);
```

Agent rules:

- Paths are relative to the base URL (`/auth/login`); **do not** hardcode the host in endpoint files.
- Body = a `Map` whose keys match OpenAPI **exactly** (snake_case).
- Protected → `auth: true`.
- Share one `ApiClient` between auth and other services so the token is reused.

---

## 5. Full example — `auth/` domain

### Import

```dart
import 'package:pbl_skin_problem_detector/data/services/auth/auth.dart';
```

### Login (`auth_login.dart` → `POST /auth/login`)

Public. See `LoginRequest` / `AuthResponse` in OpenAPI.

```dart
final auth = AuthService();

final user = await auth.login(
  email: 'pengguna@gmail.com',
  password: 'skinscan123',
  acceptedTerms: true, // facade checks consent before hitting the API
);

// JWT is already on auth.api.accessToken
print(user.accessToken);
```

Body sent to the server (from `AuthLogin`):

```json
{
  "email": "pengguna@gmail.com",
  "password": "skinscan123",
  "accepted_terms": true,
  "accepted_privacy": true
}
```

### Register (`auth_register.dart` → `POST /auth/register`)

Public. Schema: `RegisterRequest`. Response: `AuthResponse` (`201`).

```dart
final user = await auth.register(
  email: 'budi@gmail.com',
  password: 'rahasia123',
  fullName: 'Budi Santoso',
  acceptedTerms: true,
);
```

### Google (`auth_google.dart` → `POST /auth/google`)

Public. Schema: `GoogleLoginRequest` (`id_token` + consent).

```dart
final user = await auth.loginWithGoogle(acceptedTerms: true);
```

### Facade & token

`AuthService` calls the endpoint files above, then:

- `setAccessToken(user.accessToken)` after success
- `clearAccessToken()` on logout

Repository: [`mobile/lib/data/repositories/auth_repository.dart`](../mobile/lib/data/repositories/auth_repository.dart).

Demo account (seed / docs): `pengguna@gmail.com` / `skinscan123`.

---

## 6. Protected example — `scan/` domain

```dart
import 'package:pbl_skin_problem_detector/data/services/scan/scan.dart';

// Reuse the same ApiClient after login
final scan = ScanService(apiClient: auth.api);
final status = await scan.status(); // GET /users/status + Bearer
```

Reference file: `scan_status.dart` (`auth: true` on `api.get`).

---

## 7. Agent checklist for a new endpoint

1. [ ] Read `paths` + request/response schemas in `backend/openapi.json`.
2. [ ] Note public vs protected; note success and error status codes.
3. [ ] Create / pick a domain folder under `mobile/lib/data/services/<domain>/`.
4. [ ] Add `<domain>_<action>.dart` (one endpoint per file).
5. [ ] Use `ApiClient` (`post`/`get`, `auth: true` if protected).
6. [ ] JSON body keys = OpenAPI snake_case; parse the response into a Dart model.
7. [ ] Export from barrel `<domain>.dart`; wire via `<domain>_service.dart` → repository → cubit.
8. [ ] Do not duplicate the base URL; do not hardcode secrets (`JWT`, DB, Google client secret).
9. [ ] Errors: throw a domain exception (e.g. `AuthException`) using `detail` when it is a string.
10. [ ] If the backend changed: re-export OpenAPI first, then update mobile.

---

## 8. Anti-patterns (do not)

- Inventing body fields from memory or from Python code without checking `openapi.json`.
- Putting `http.get` / `http.post` in a screen or cubit.
- Creating a new `ApiClient` per call without copying `accessToken` (Bearer is missing).
- Sending `Authorization` to public endpoints that do not need it (harmless, but unnecessary).
- Documenting API fields in other markdown files as a substitute for OpenAPI.

---

## 9. Related references

| Document | Contents |
|---|---|
| [`api.md`](api.md) | Base URL context, public vs protected, security |
| [`backend/openapi.json`](../backend/openapi.json) | Official contract |
| [`backend/AGENTS.md`](../backend/AGENTS.md) | How to change the backend + export OpenAPI |
| [`struktur-folder.md`](struktur-folder.md) | Mobile folder map |
| [`panduan-pengembangan.md`](panduan-pengembangan.md) | Conventions for new features |
