# FieldHub Deployment Guide

This guide covers deployment procedures for FieldHub, focusing on production configuration, environment variables, and third-party service integration.

## 🚀 Prerequisites

- **Elixir/Erlang**: Same versions as `.tool-versions`
- **Postgres**: Version 14+
- **Node.js**: LTS version (for asset building)

## 🌍 Environment Variables

FieldHub uses `config/runtime.exs` to load configuration from environment variables at runtime.

### Essential Variables

| Variable          | Description                     | Example                      |
| ----------------- | ------------------------------- | ---------------------------- |
| `PHX_SERVER`      | Start Phoenix server            | `true`                       |
| `SECRET_KEY_BASE` | Session signing key (64+ chars) | `mix phx.gen.secret` output  |
| `DATABASE_URL`    | Postgres connection string      | `ecto://user:pass@host/db`   |
| `PHX_HOST`        | Production domain name          | `fieldhub.app`               |

### Email Configuration (Swoosh)

Select ONE provider by setting `MAIL_PROVIDER`.

| Variable            | Description                                             |
| ------------------- | ------------------------------------------------------- |
| `MAIL_PROVIDER`     | `sendgrid`, `postmark`, `resend`, `mailgun`, or `smtp`  |
| `MAIL_FROM_ADDRESS` | Sender address (e.g., `noreply@fieldhub.app`)           |

**Provider-Specific Keys:**

- **SendGrid**: `SENDGRID_API_KEY`
- **Postmark**: `POSTMARK_API_KEY`
- **Resend**: `RESEND_API_KEY`
- **Mailgun**: `MAILGUN_API_KEY`, `MAILGUN_DOMAIN`
- **SMTP**: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`

### SMS (Twilio)

Required for technician notifications.

- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_PHONE_NUMBER`

### Push Notifications (VAPID)

Required for PWA and Mobile push notifications. Use `mix run scripts/gen_vapid.exs` to generate keys.

- `VAPID_PUBLIC_KEY`
- `VAPID_PRIVATE_KEY`
- `VAPID_SUBJECT` (e.g. `mailto:admin@yourdomain.com`)

### Payments (Stripe)

- `STRIPE_SECRET_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `STRIPE_WEBHOOK_SECRET`

## 📦 Docker Deployment

A `Dockerfile` is provided for containerized deployment (e.g., Fly.io, Gigalixir, K8s).

```bash
# Build the image
docker build -t fieldhub .

# Run container (ensure env vars are passed)
docker run -p 4000:4000 --env-file .env fieldhub
```

## 🛠️ Validation Steps

After deploying, verify critical services:

1. **Email**: Trigger a password reset or invite a user.
2. **SMS**: Dispatch a job to a technician (ensure phone number is valid).
3. **Offline Sync**: Test the PWA offline mode (as verified by `TechSyncControllerTest`).

## 🚨 Troubleshooting

- **"Connection Refused" (DB)**: Check `DATABASE_URL` and ensure Postgres is accepting connections.
- **"Missing API Key"**: Check logs for missing environment variable warnings.
- **Assets 404**: Ensure `mix assets.deploy` ran during build.
