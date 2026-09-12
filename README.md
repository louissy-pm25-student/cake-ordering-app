# Sweet Studio — Flutter cake ordering and admin

## Run
From this folder run flutter pub get, then flutter run.
In Android Studio select an Android emulator/device and run lib/main.dart.
Build Android with flutter build apk --debug.

## Admin
Open Staff / admin login on Home/Menu (or open Profile).
- Username: admin
- Password: admin123

These are the initial owner credentials. Open the top-left hamburger menu to navigate between admin sections. Admin accounts can only be created from the protected Admin accounts section. Profile lets each administrator change their own username/password after entering their current password. Changes are saved on this device and replace the previous login. The admin bottom bar has been removed. The menu starts empty; choose Menu in the drawer, then Add at the bottom-right. Saved cakes appear in the customer menu.

## Features
- Dashboard: daily/weekly/monthly order counts, best sellers, peak order hour and alerts.
- Orders: customer/date/status search, phone/walk-in orders, edit pending manual orders, scheduling/driver changes, pending → baking → ready → delivered status and cancellations.
- Products: cakes, description/photos/prices, categories/tags, size/flavor/filling variants and price adjustments, availability, custom-design/dietary requests.
- Customers: contact/address, history, loyalty points, discount codes, delivered-order reviews and staff replies.
- Scheduling: fulfilment calendar, delivery zones/fees and drivers.
- Security: role checks in ViewModels, hashed passwords, verified customer registration/password recovery and local notifications.

Owner and admin roles have administrator permissions. Manager handles operations but cannot edit admin accounts. Baker handles production status and requests. Staff handles orders and customers. A signed-out user cannot call the admin-account creation action.

Configure delivery zones before accepting delivery orders. Points are earned on delivery; codes can require a points threshold. Special designs can be handled as customer requests.

## Customer flow
Guests browse Home/Menu. Adding items, Customize, Orders and Profile require login/register. Registration collects full name, username, email, a Malaysian mobile number, gender and matching passwords, then sends a code using the selected email or phone channel. Malaysian numbers are normalized to the `+60` international format. Login uses username and password. Forgot password verifies the selected saved contact before accepting a new password. Customer and admin sessions remain signed in across app restarts until the user explicitly logs out. Checkout checks availability, variants/prices and delivery fees.

## Verification service
Without configuration, the app uses development verification and shows the generated code on the verification page. A ready-to-configure sender service is included in `backend/`; it generates expiring six-digit codes and supports SendGrid email and Twilio SMS. Configure it using `backend/.env.example`, deploy it behind HTTPS, then run or build Flutter with:

`flutter run --dart-define=VERIFICATION_API_URL=https://your-api.example.com`

The HTTPS backend must provide:

- `POST /auth/send-code` with `channel`, `purpose`, and `destination`; return `challengeId` and `maskedDestination`.
- `POST /auth/verify-code` with `challengeId` and `code`; return `verified: true` or `false`.

SMS/email provider credentials belong on that backend, never in the Flutter app. Inbox placement cannot be guaranteed by app code. Configure an authenticated sending domain (SPF, DKIM and DMARC), a reputable transactional email provider, consent-compliant SMS sender IDs, and non-promotional verification templates to improve delivery.

## Local prototype limits
Records are cached in SharedPreferences and synchronized to Supabase when a connection is available. Failed cloud writes remain marked for retry. Admin and customer records, menu items, orders, profiles, credentials, settings and signed-in session state are stored inside the protected JSON snapshot. There is no payment gateway or courier integration. Real verification delivery requires the configured API above.

## Supabase storage

The app connects with the Supabase publishable key and signs the installation in anonymously. The `cake_app_state` table uses row-level security so an installation can access only the row belonging to its Supabase user ID. Never place a Supabase service-role key in this app.

Run [the database migration](supabase/migrations/20260912000000_create_cake_app_state.sql) once in the Supabase SQL Editor and enable **Allow anonymous sign-ins** under Authentication → Sign In / Providers. The local cache is uploaded on the first successful connection.

Default admin credentials are for this requested local setup. Customer/staff passwords use salted PBKDF2-HMAC-SHA256 hashes. Local role checks and persisted sessions are not a server security boundary. Existing Flutter profiles/orders are retained; static demo cakes have been removed.

## Structure
- lib/model: data types; model/admin: records and form definitions.
- lib/viewmodel: customer state; viewmodel/admin: admin rules and permissions.
- lib/screen: customer pages; screen/admin: management screens/forms.
- lib/nav: destinations and navigation.
- lib/data: repository and local storage.
- lib/ui: theme and reusable widgets.

## Checks
Run flutter analyze and flutter test. Tests cover authentication, customer ordering/persistence, admin login/forms, cancellation, delivery fees and role permissions.
