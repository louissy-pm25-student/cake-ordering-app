# Sweet Studio — Flutter cake ordering and admin

## Run
From this folder run flutter pub get, then flutter run.
In Android Studio select an Android emulator/device and run lib/main.dart.
Build Android with flutter build apk --debug.

## Admin
Open Staff / admin login on Home/Menu (or open Profile).
- Username: admin
- Password: admin123

These are the initial owner credentials. Open the top-left hamburger menu to navigate between admin sections. Profile lets each staff member change their own username/password after entering their current password. Changes are saved on this device and replace the previous login. The admin bottom bar has been removed. The menu starts empty; choose Menu in the drawer, then Add at the bottom-right. Saved cakes appear in the customer menu.

## Features
- Dashboard: daily/weekly/monthly figures, best sellers, booked revenue, net collected payments, peak order hour and alerts.
- Orders: customer/date/status search, phone/walk-in orders, edit unpaid pending manual orders, scheduling/driver changes, pending → baking → ready → delivered status, cancellations and partial/full refund records.
- Products: cakes, description/photos/prices, categories/tags, size/flavor/filling variants and price adjustments, availability, custom-design/dietary requests.
- Inventory: ingredient stock, thresholds, suppliers and recipes. Catalog orders deduct recipes transactionally; edits adjust stock, pending cancellations restore it once, baking cancellations do not restore consumed ingredients.
- Customers: contact/address, history, loyalty points, discount codes, delivered-order reviews and staff replies.
- Scheduling: calendar, daily capacity, pickup/delivery slots, delivery zones/fees and drivers.
- Finance: cash/card/transfer payment records, refunds, tax setting, text receipt/invoice copy/export, sales summaries.
- Security: role checks in ViewModels, hashed staff passwords, activity logs and local notifications.

Owner has all permissions. Manager handles operations/finance but cannot edit staff/settings. Baker handles production status, inventory and requests, without finance or marking delivered. Staff handles orders/customers without finance or staff administration. Owner creates staff accounts.

Configure capacity/tax, slots/zones, ingredients and recipes before accepting orders. Points are earned on delivery; codes can require a points threshold. Recipe deductions apply to catalog products; special designs can be handled as customer requests.

## Customer flow
Guests browse Home/Menu. Adding items, Customize, Orders and Profile require login/register. Checkout checks availability, variants/prices, capacity, fees and tax. Customers see local order notifications, request updates and review replies.

## Local prototype limits
Records persist in SharedPreferences on this app installation. Admin and customers share records on the same device only. There is no backend, cross-device synchronization, push/email/SMS service, payment gateway, bank refund or courier integration. Payment/refund actions record transactions performed outside the app. Receipts are text files; reports use local records.

Default admin credentials are for this requested local setup. Customer/staff passwords use salted PBKDF2-HMAC-SHA256 hashes. Each launch starts as a guest. Local role checks are not a server security boundary. Existing Flutter profiles/orders are retained; static demo cakes have been removed.

## Structure
- lib/model: data types; model/admin: records and form definitions.
- lib/viewmodel: customer state; viewmodel/admin: admin rules and permissions.
- lib/screen: customer pages; screen/admin: management screens/forms.
- lib/nav: destinations and navigation.
- lib/data: repository and local storage.
- lib/ui: theme and reusable widgets.

## Checks
Run flutter analyze and flutter test. Tests cover authentication, customer ordering/persistence, admin login/forms, stock rollback, cancellation, tax/fees, capacity, payment/refund limits and role permissions.
