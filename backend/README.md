# Verification backend

This Node.js service generates random six-digit codes, stores only a salted hash in memory, expires codes after ten minutes, limits attempts and sends codes through:

- SendGrid for email
- Twilio Programmable Messaging for Malaysian SMS numbers (`+60`)

## Configure and run

1. Install Node.js 20 or newer.
2. Copy `.env.example` to `.env` and fill in the provider values.
3. For local development run `npm run start:local`. In production, load the same environment variables through the deployment platform and run `npm start`.
4. Deploy behind HTTPS. Do not expose this development server directly to the internet.
5. Start Flutter with `flutter run --dart-define=VERIFICATION_API_URL=https://your-api.example.com`.

The sender email must be verified in SendGrid. Configure SPF, DKIM and DMARC for its domain. Twilio trial accounts can send only to verified recipients and Malaysian delivery depends on the account's geographic permissions and sender capabilities.

The in-memory challenge store is suitable for one server instance. Use Redis or another expiring shared store before scaling to multiple instances.
