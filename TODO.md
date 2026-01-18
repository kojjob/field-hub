# Field Service Dispatch Hub - Production TODO

> **Project:** FieldHub  
> **Started:** 2026-01-17  
> **Methodology:** Test-Driven Development (TDD) + Git Feature Branch Workflow  
> **Target:** MVP in 8-10 weeks → $100K MRR in 18-24 months

---

## 📋 Table of Contents

1. [Development Workflow](#-development-workflow)
2. [Phase 0: Foundation](#phase-0-foundation-week-1)
3. [Phase 1: Core Domain](#phase-1-core-domain-weeks-2-3)
4. [Phase 2: Dispatcher Dashboard](#phase-2-dispatcher-dashboard-weeks-4-5)
5. [Phase 3: Technician Mobile](#phase-3-technician-mobile-pwa-weeks-6-7)
6. [Phase 4: Customer Portal](#phase-4-customer-portal-week-8)
7. [Phase 5: Notifications & Integrations](#phase-5-notifications--integrations-weeks-9-10)
8. [Phase 6: Billing & Polish](#phase-6-billing--polish-weeks-11-12)
9. [Phase 7: Launch Prep](#phase-7-launch-prep-week-13)
10. [Post-MVP Roadmap](#post-mvp-roadmap)

---

## 🔄 Development Workflow

### Git Branch Strategy

```
main (production)
  └── develop (staging)
        ├── feature/FH-001-organization-schema
        ├── feature/FH-002-technician-crud
        ├── feature/FH-003-job-assignment
        └── hotfix/FH-XXX-critical-bug
```

### Branch Naming Convention

- `feature/FH-XXX-short-description` - New features
- `fix/FH-XXX-short-description` - Bug fixes
- `hotfix/FH-XXX-short-description` - Production hotfixes
- `refactor/FH-XXX-short-description` - Code refactoring
- `test/FH-XXX-short-description` - Test additions/improvements
- `docs/FH-XXX-short-description` - Documentation updates

### Commit Message Format

```
type(scope): short description

[optional body]

[optional footer with issue references]
```

**Types:** `feat`, `fix`, `test`, `docs`, `refactor`, `style`, `chore`, `perf`

**Examples:**

```
feat(jobs): add job creation with validation

- Add Job schema with all required fields
- Implement Jobs.create_job/2 with changeset validation
- Add comprehensive test coverage

Refs: FH-015
```

```
test(dispatch): add auto-assignment algorithm tests

- Test skill matching logic
- Test proximity-based assignment
- Test availability checking

Refs: FH-042
```

### TDD Workflow (Red → Green → Refactor)

1. **Red:** Write a failing test first
2. **Green:** Write minimum code to pass the test
3. **Refactor:** Clean up while keeping tests green
4. **Commit:** Commit with descriptive message
5. **Repeat:** Move to next test case

### Pull Request Checklist

- [ ] All tests pass (`mix test`)
- [ ] No compiler warnings (`mix compile --warnings-as-errors`)
- [ ] Code is formatted (`mix format --check-formatted`)
- [ ] Migrations are reversible (if applicable)
- [ ] Documentation updated (if applicable)
- [ ] PR description includes context and screenshots (for UI)

---

## Phase 0: Foundation (Week 1)

### FH-001: Project Setup ✅

- [x] Generate Phoenix project with LiveView
- [x] Add core dependencies (geo_postgis, oban, req, etc.)
- [x] Configure Phoenix.PubSub (no Redis)
- [x] Generate authentication with `phx.gen.auth`
- [x] Create Mailer module with Swoosh
- [x] Create ARCHITECTURE.md documentation

**Branch:** `main` (initial setup)

### FH-002: Database Migrations

- [x] Create organizations migration
- [x] Create technicians migration
- [x] Create customers migration
- [x] Create jobs migration
- [x] Create job_events migration
- [ ] Run all migrations successfully
- [ ] Verify migrations are reversible (`mix ecto.rollback --all`)

**Branch:** `feature/FH-002-database-schema`

**Git Commands:**

```bash
git checkout -b feature/FH-002-database-schema
mix ecto.migrate
mix ecto.rollback --all
mix ecto.migrate
git add -A
git commit -m "feat(db): add core domain migrations

- Organizations (multi-tenant container)
- Technicians (field workers)
- Customers (service recipients)
- Jobs (work units with full lifecycle)
- JobEvents (immutable audit trail)

Refs: FH-002"
git push -u origin feature/FH-002-database-schema
```

### FH-003: Ecto Schemas ✅

- [x] **Test First:** Write schema validation tests
  - [x] `test/field_hub/accounts/organization_test.exs`
  - [x] `test/field_hub/dispatch/technician_test.exs`
  - [x] `test/field_hub/crm/customer_test.exs`
  - [x] `test/field_hub/jobs/job_test.exs`
  - [x] `test/field_hub/jobs/job_event_test.exs`
- [x] **Implement:** Create schema modules
  - [x] `lib/field_hub/accounts/organization.ex`
  - [x] `lib/field_hub/dispatch/technician.ex`
  - [x] `lib/field_hub/crm/customer.ex`
  - [x] `lib/field_hub/jobs/job.ex`
  - [x] `lib/field_hub/jobs/job_event.ex`
- [x] **Verify:** All tests pass (169 tests)

**Branch:** `feature/FH-003-ecto-schemas` (merged to develop)

### FH-004: Update User Schema for Multi-tenancy ✅

- [x] **Test First:** Write tests for user-organization association
- [x] **Implement:** Update User schema with organization_id, name, role
- [x] **Implement:** Update Accounts context with organization scoping
- [x] **Verify:** Auth still works, tests pass

**Branch:** `feature/FH-003-ecto-schemas` (included in schema work)

### FH-005: Git Repository Setup

- [ ] Initialize git repository
- [ ] Create `.gitignore` (ensure secrets excluded)
- [ ] Create initial commit
- [ ] Set up remote repository (GitHub/GitLab)
- [ ] Create `develop` branch
- [ ] Set up branch protection rules
- [ ] Create PR template (`.github/PULL_REQUEST_TEMPLATE.md`)

**Commands:**

```bash
cd field_hub
git init
git add -A
git commit -m "chore: initial project setup with Phoenix 1.8"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
git checkout -b develop
git push -u origin develop
```

---

## Phase 1: Core Domain (Weeks 2-3)

### FH-010: Organizations Context ✅

- [x] **Test First:** `test/field_hub/accounts/organizations_test.exs`
  - [x] `create_organization/1` with valid attrs
  - [x] `create_organization/1` with invalid attrs
  - [x] `update_organization/2`
  - [x] `delete_organization/1`
  - [x] `get_organization!/1`
  - [x] `get_organization_by_slug/1`
  - [x] `generate_unique_slug/1` uniqueness
  - [x] `create_organization_with_owner/2` (Ecto.Multi)
  - [x] `update_subscription/2`
  - [x] `organization_active?/1`
- [x] **Implement:** Add organization functions to Accounts context
- [x] **Refactor:** Handle string/atom keys, DateTime truncation

**Branch:** `feature/FH-010-organizations-context` (merged to develop)

### FH-011: Organization Onboarding Flow ✅

- [x] **Test First:** `test/field_hub_web/live/onboarding_live_test.exs`
  - [x] Renders onboarding form for user without org
  - [x] Creates organization on valid submit
  - [x] Shows validation errors
  - [x] Redirects to dashboard after creation
  - [x] Auto-generates slug preview
  - [x] Redirects users with org to dashboard
- [x] **Implement:** `lib/field_hub_web/live/onboarding_live.ex`
- [x] **Implement:** `lib/field_hub_web/live/dashboard_live.ex`
- [x] **Implement:** Update router with onboarding/dashboard routes

**Branch:** `feature/FH-011-onboarding-flow` (merged to develop)

### FH-012: Dispatch Context (Technicians) ✅

- [x] **Test First:** `test/field_hub/dispatch_test.exs`
  - [x] `list_technicians/1` scoped to organization
  - [x] `create_technician/2` with valid attrs
  - [x] `create_technician/2` with org scope
  - [x] `update_technician/2`
  - [x] `update_technician_status/2`
  - [x] `update_technician_location/3`
  - [x] `archive_technician/1` (soft delete)
  - [x] `get_available_technicians/1`
  - [x] `get_technicians_with_skill/2`
- [x] **Implement:** `lib/field_hub/dispatch.ex` context
- [x] **Implement:** `lib/field_hub/dispatch/technician.ex` schema

**Branch:** `feature/FH-012-dispatch-context` (merged to develop)

### FH-013: CRM Context (Customers) ✅

- [x] **Test First:** `test/field_hub/crm_test.exs`
  - [x] `list_customers/1` scoped to organization
  - [x] `search_customers/2` by name, phone, email
  - [x] `create_customer/2`
  - [x] `update_customer/2`
  - [x] `archive_customer/1`
  - [x] `generate_portal_token/1`
  - [x] `get_customer_by_portal_token/1`
- [x] **Implement:** `lib/field_hub/crm.ex` context
- [x] **Implement:** `lib/field_hub/crm/customer.ex` schema

**Branch:** `feature/FH-013-crm-context` (merged to develop)

### FH-014: Jobs Context - Basic CRUD ✅

- [x] **Test First:** `test/field_hub/jobs_test.exs`
  - [x] `list_jobs/1` scoped to organization
  - [x] `list_jobs_for_date/2`
  - [x] `list_unassigned_jobs/1`
  - [x] `create_job/2` with auto-generated job number
  - [x] `update_job/2`
  - [x] `assign_job/3`
  - [x] `get_job!/1`
- [x] **Implement:** `lib/field_hub/jobs.ex` context
- [x] **Implement:** `lib/field_hub/jobs/job.ex` schema
- [x] **Implement:** Job number generation (per org sequence)

**Branch:** `feature/FH-014-jobs-context` (merged to develop)

### FH-015: Jobs Context - Status Workflow ✅

- [x] **Test First:** Job status transitions
  - [x] `unscheduled` → `scheduled` (when date assigned)
  - [x] `scheduled` → `dispatched` (when tech assigned)
  - [x] `dispatched` → `en_route` (tech starts travel)
  - [x] `en_route` → `on_site` (tech arrives)
  - [x] `on_site` → `in_progress` (work started)
  - [x] `in_progress` → `completed` (work done)
  - [x] Any → `cancelled`
  - [x] Any → `on_hold`
  - [x] Invalid transitions raise error
- [x] **Implement:** State machine for job status
- [x] **Implement:** `start_travel/1`, `arrive_on_site/1`, `start_work/1`, `complete_job/2`, `cancel_job/2`

**Branch:** `feature/FH-015-job-status-workflow` (merged to develop)

### FH-016: Job Events (Audit Trail) ✅

- [x] **Test First:** `test/field_hub/jobs/job_event_test.exs`
  - [x] Event created on job creation
  - [x] Event created on status change
  - [x] Event created on assignment
  - [x] Event includes actor info
  - [x] Events are immutable (no update)
- [x] **Implement:** `lib/field_hub/jobs/job_event.ex` schema
- [x] **Implement:** Event creation hooks in Jobs context

**Branch:** `feature/FH-016-job-events`

### FH-017: Real-Time Broadcasting ✅

- [x] **Test First:** `test/field_hub/dispatch/broadcaster_test.exs`
  - [x] `broadcast_job_created/1` sends to org topic
  - [x] `broadcast_job_updated/1` sends to org + tech topics
  - [x] `broadcast_technician_location/4` sends to org topic
  - [x] `broadcast_technician_status_changed/1`
- [x] **Implement:** `lib/field_hub/dispatch/broadcaster.ex`
- [x] **Integrate:** Call broadcaster from Jobs and Dispatch contexts

**Branch:** `feature/FH-017-realtime-broadcasting`

---

## Phase 2: Dispatcher Dashboard (Weeks 4-5)

### FH-020: Dashboard Layout & Navigation ✅

- [x] **Design:** Create wireframe/mockup of dashboard
- [x] **Implement:** App layout with sidebar navigation
- [x] **Implement:** Responsive design (desktop-first)
- [x] **Implement:** Dark mode support
- [x] **Style:** Professional dispatch-themed styling

**Branch:** `feature/FH-020-dashboard-layout`

### FH-021: Technician Management UI

- [x] **Test First:** `test/field_hub_web/live/technician_live_test.exs`
  - [x] Lists technicians for current org
  - [x] Create technician form validates input
  - [x] Edit technician updates record
  - [x] Archive technician marks as archived
  - [x] Skills can be added/removed
- [x] **Implement:** `lib/field_hub_web/live/technician_live/index.ex`
- [x] **Implement:** `lib/field_hub_web/live/technician_live/form_component.ex`
- [x] **Implement:** Color picker for technician calendar color

**Branch:** `feature/FH-021-technician-management`

### FH-022: Customer Management UI

- [x] **Test First:** `test/field_hub_web/live/customer_live_test.exs`
  - [x] Lists customers for current org
  - [x] Search filters customers
  - [x] Create customer form with address
  - [x] Edit customer
  - [x] View customer job history
- [x] **Implement:** `lib/field_hub_web/live/customer_live/index.ex`
- [x] **Implement:** `lib/field_hub_web/live/customer_live/show.ex`
- [x] **Implement:** `lib/field_hub_web/live/customer_live/form_component.ex`

**Branch:** `feature/FH-022-customer-management`

### FH-023: Job Creation & Editing ✅

- [x] **Test First:** `test/field_hub_web/live/job_live_test.exs`
  - [x] Create job with customer selection
  - [x] Edit job details
  - [x] Validate required fields
  - [x] Auto-generate job number on create
- [x] **Implement:** `lib/field_hub_web/live/job_live/index.ex`
- [x] **Implement:** `lib/field_hub_web/live/job_live/show.ex`
- [x] **Implement:** `lib/field_hub_web/live/job_live/form_component.ex`
- [ ] **Stretch:** Customer search/select component (inline new customer)
- [ ] **Stretch:** Address autocomplete (Google Places API)

**Branch:** `feature/FH-023-job-forms`
**PR:** [#3](https://github.com/kojjob/field-hub/pull/3)

### FH-024: Dispatch Board - Calendar View ✅

- [x] **Test First:** `test/field_hub_web/live/dispatch_live_test.exs`
  - [x] Renders day view by default
  - [x] Shows jobs in correct time slots
  - [x] Groups by technician
  - [x] Date navigation works
  - [x] Shows unassigned jobs sidebar
- [x] **Implement:** `lib/field_hub_web/live/dispatch_live/index.ex`
- [x] **Implement:** Day view with time slots (7am - 7pm)
- [x] **Implement:** Unassigned jobs sidebar
- [ ] **Stretch:** Week view

**Branch:** `feature/FH-024-dispatch-calendar`
**PR:** [#4](https://github.com/kojjob/field-hub/pull/4)

### FH-025: Dispatch Board - Drag & Drop Assignment ✅

- [x] **Test First:** Test drag-drop events update job (2 tests added)
- [x] **Implement:** Sortable.js hook for drag-drop
- [x] **Implement:** `handle_event("assign_job", ...)` and `handle_event("unassign_job", ...)`
- [x] **Implement:** Unassigned jobs sidebar (draggable source)
- [x] **Implement:** Visual feedback during drag
- [x] **Integrate:** Assignment changes update UI via load_data()

**Branch:** `feature/FH-025-drag-drop-assignment`
**PR:** [#5](https://github.com/kojjob/field-hub/pull/5)

### FH-026: Dispatch Board - Quick Actions ✅

- [x] **Implement:** Quick dispatch button (auto-assign)
- [x] **Implement:** Job status change from board
- [ ] **Implement:** Reschedule job (drag to different time/day) - *deferred to FH-027*
- [x] **Implement:** View job details slideout panel
- [ ] **Implement:** Keyboard shortcuts (n = new job, etc.) - *deferred to FH-027*

**Branch:** `feature/FH-026-dispatch-quick-actions`
**PR:** [#6](https://github.com/kojjob/field-hub/pull/6)

### FH-027: Technician Status Sidebar

- [ ] **Test First:** Real-time status updates render
- [ ] **Implement:** Technician list with current status
- [ ] **Implement:** Real-time status badge updates
- [ ] **Implement:** Current job indicator
- [ ] **Implement:** Click to view technician schedule

**Branch:** `feature/FH-027-tech-status-sidebar`

### FH-028: Live Map Component

- [ ] **Implement:** Leaflet.js map hook
- [ ] **Implement:** Show technician markers with real-time position
- [ ] **Implement:** Show job locations for the day
- [ ] **Implement:** Click marker to view details
- [ ] **Implement:** Route visualization (stretch)

**Branch:** `feature/FH-028-live-map`

---

## Phase 3: Technician Mobile (PWA) (Weeks 6-7)

### FH-030: Mobile Layout & PWA Setup

- [x] **Implement:** Mobile-first layout for tech views (Bottom Nav implemented)
- [x] **Implement:** PWA manifest.json
- [x] **Implement:** Service worker for offline caching (Basic SW implemented)
- [x] **Implement:** "Add to Home Screen" support (Meta tags added)
- [ ] **Test:** Works on iOS Safari, Android Chrome

**Branch:** `feature/FH-030-pwa-setup`

### FH-031: Technician Authentication

- [ ] **Test First:** Tech can log in with credentials
- [ ] **Implement:** Tech login page (mobile-optimized)
- [ ] **Implement:** Remember device token
- [ ] **Implement:** Session persistence across app restarts

**Branch:** `feature/FH-031-tech-auth`

### FH-032: Technician Dashboard

- [ ] **Test First:** `test/field_hub_web/live/tech_live/dashboard_test.exs`
  - [ ] Shows today's jobs
  - [ ] Shows current job prominently
  - [ ] Receives new job assignments in real-time
- [ ] **Implement:** `lib/field_hub_web/live/tech_live/dashboard.ex`
- [ ] **Implement:** Job card component (mobile)
- [ ] **Implement:** Pull-to-refresh

**Branch:** `feature/FH-032-tech-dashboard`

### FH-033: Job Detail View (Mobile)

- [ ] **Implement:** Full job details screen
- [ ] **Implement:** Customer info with tap-to-call
- [ ] **Implement:** Address with tap-to-navigate (Google Maps)
- [ ] **Implement:** Job notes and instructions
- [ ] **Implement:** Previous service history at address

**Branch:** `feature/FH-033-tech-job-detail`

### FH-034: Job Status Actions

- [ ] **Test First:** Status transitions work from mobile
- [ ] **Implement:** "Start Travel" button
- [ ] **Implement:** "Arrived" button
- [ ] **Implement:** "Start Work" button
- [ ] **Implement:** Status confirmation modals
- [ ] **Integrate:** Broadcast status changes

**Branch:** `feature/FH-034-tech-status-actions`

### FH-035: GPS Location Tracking

- [ ] **Implement:** Geolocation hook for continuous tracking
- [ ] **Implement:** Battery-efficient tracking (when traveling)
- [ ] **Implement:** Location permission handling
- [ ] **Implement:** Send location updates to server
- [ ] **Test:** Works in background on mobile

**Branch:** `feature/FH-035-gps-tracking`

### FH-036: Job Completion Flow

- [ ] **Test First:** Job completes with required fields
- [ ] **Implement:** Work performed text entry
- [ ] **Implement:** Amount charged input
- [ ] **Implement:** Signature capture (canvas component)
- [ ] **Implement:** Photo upload (before/after)
- [ ] **Implement:** Complete job submission

**Branch:** `feature/FH-036-job-completion`

### FH-037: Offline Support

- [ ] **Implement:** IndexedDB storage for pending updates
- [ ] **Implement:** Queue job updates when offline
- [ ] **Implement:** Sync when connection restored
- [ ] **Implement:** Offline indicator UI
- [ ] **Test:** Complete job while offline, syncs later

**Branch:** `feature/FH-037-offline-support`

---

## Phase 4: Customer Portal (Week 8)

### FH-040: Portal Authentication

- [ ] **Test First:** Portal token grants access
- [ ] **Implement:** Magic link login (token in URL)
- [ ] **Implement:** Portal session management
- [ ] **Implement:** Restrict to customer's own data

**Branch:** `feature/FH-040-portal-auth`

### FH-041: Job Status Tracking

- [ ] **Test First:** Customer sees their scheduled job
- [ ] **Implement:** `lib/field_hub_web/live/portal_live/status.ex`
- [ ] **Implement:** Show technician name and ETA
- [ ] **Implement:** Real-time status updates
- [ ] **Implement:** Map showing tech location (when en route)

**Branch:** `feature/FH-041-portal-tracking`

### FH-042: Service History

- [ ] **Implement:** List of past jobs
- [ ] **Implement:** Job detail with work performed
- [ ] **Implement:** Invoice download (stretch)

**Branch:** `feature/FH-042-portal-history`

### FH-043: Self-Service Booking (Stretch)

- [ ] **Implement:** Book new service request
- [ ] **Implement:** Select service type
- [ ] **Implement:** Date/time preferences
- [ ] **Implement:** Creates unscheduled job for dispatcher

**Branch:** `feature/FH-043-portal-booking`

---

## Phase 5: Notifications & Integrations (Weeks 9-10)

### FH-050: Email Notifications

- [ ] **Test First:** Emails sent on key events
- [ ] **Implement:** Email templates
  - [ ] Job confirmation to customer
  - [ ] Technician dispatch notification
  - [ ] Job completion summary
  - [ ] Password reset (already exists)
- [ ] **Configure:** Production email adapter (SendGrid/Postmark)

**Branch:** `feature/FH-050-email-notifications`

### FH-051: SMS Notifications (Twilio)

- [ ] **Implement:** `lib/field_hub/notifications/sms.ex`
- [ ] **Implement:** Twilio client with Req
- [ ] **Implement:** SMS templates
  - [ ] "Your technician is on the way"
  - [ ] "Technician has arrived"
  - [ ] "Job completed, thank you!"
- [ ] **Configure:** Twilio credentials in runtime.exs

**Branch:** `feature/FH-051-sms-notifications`

### FH-052: Push Notifications

- [ ] **Implement:** Web Push for PWA
- [ ] **Implement:** FCM for Android devices
- [ ] **Implement:** Notification for new job assignment
- [ ] **Implement:** Notification preferences

**Branch:** `feature/FH-052-push-notifications`

### FH-053: Notification Preferences

- [ ] **Implement:** Customer preferences (email, SMS, both)
- [ ] **Implement:** Technician preferences
- [ ] **Implement:** Organization default settings

**Branch:** `feature/FH-053-notification-preferences`

### FH-054: Geocoding Integration

- [ ] **Implement:** `lib/field_hub/routing/geocoder.ex`
- [ ] **Implement:** Google Geocoding API integration
- [ ] **Implement:** Auto-geocode on customer/job address save
- [ ] **Implement:** Background job for batch geocoding

**Branch:** `feature/FH-054-geocoding`

### FH-055: Background Jobs (Oban)

- [ ] **Implement:** Oban configuration
- [ ] **Implement:** `NotificationWorker` for async notifications
- [ ] **Implement:** `GeocodingWorker` for address geocoding
- [ ] **Implement:** `CleanupWorker` for old data purging
- [ ] **Implement:** Oban Web dashboard (admin only)

**Branch:** `feature/FH-055-background-jobs`

---

## Phase 6: Billing & Polish (Weeks 11-12)

### FH-060: Stripe Integration

- [ ] **Implement:** `lib/field_hub/billing.ex` context
- [ ] **Implement:** Stripe.js for checkout
- [ ] **Implement:** Subscription creation on onboarding
- [ ] **Implement:** Billing portal link
- [ ] **Implement:** Webhook handler for subscription events

**Branch:** `feature/FH-060-stripe-billing`

### FH-061: Subscription Enforcement

- [ ] **Implement:** Check subscription status on protected routes
- [ ] **Implement:** Grace period for failed payments
- [ ] **Implement:** Downgrade/upgrade flows
- [ ] **Implement:** Usage tracking (technician count)

**Branch:** `feature/FH-061-subscription-enforcement`

### FH-062: Reports & Analytics

- [ ] **Implement:** Jobs completed this week/month
- [ ] **Implement:** Revenue tracking
- [ ] **Implement:** Technician performance metrics
- [ ] **Implement:** Export to CSV

**Branch:** `feature/FH-062-reports`

### FH-063: Settings Pages

- [ ] **Implement:** Organization settings (name, address, timezone)
- [ ] **Implement:** User management (invite team members)
- [ ] **Implement:** Notification settings
- [ ] **Implement:** Subscription/billing page

**Branch:** `feature/FH-063-settings`

### FH-064: UI Polish

- [ ] **Implement:** Loading states and skeletons
- [ ] **Implement:** Error boundaries
- [ ] **Implement:** Empty states
- [ ] **Implement:** Micro-animations
- [ ] **Implement:** Accessibility audit (WCAG 2.1)

**Branch:** `feature/FH-064-ui-polish`

---

## Phase 7: Launch Prep (Week 13)

### FH-070: Production Configuration

- [ ] **Configure:** `config/runtime.exs` for production
- [ ] **Configure:** Database connection pooling
- [ ] **Configure:** Production logging
- [ ] **Configure:** Error tracking (Sentry)
- [ ] **Configure:** APM (AppSignal/New Relic)

**Branch:** `feature/FH-070-production-config`

### FH-071: Deployment Setup

- [ ] **Implement:** Dockerfile
- [ ] **Implement:** `fly.toml` for Fly.io
- [ ] **Implement:** GitHub Actions CI/CD
- [ ] **Configure:** Production database (Fly Postgres)
- [ ] **Configure:** Custom domain and SSL

**Branch:** `feature/FH-071-deployment`

### FH-072: Security Hardening

- [ ] **Audit:** OWASP Top 10 checklist
- [ ] **Implement:** Rate limiting on auth endpoints
- [ ] **Implement:** Content Security Policy headers
- [ ] **Implement:** Secure cookie settings
- [ ] **Test:** Penetration testing basics

**Branch:** `feature/FH-072-security`

### FH-073: Performance Optimization

- [ ] **Implement:** Database query optimization (EXPLAIN ANALYZE)
- [ ] **Implement:** Caching where appropriate
- [ ] **Implement:** Asset optimization (compression, CDN)
- [ ] **Test:** Load testing with k6 or Artillery

**Branch:** `feature/FH-073-performance`

### FH-074: Documentation

- [ ] **Write:** User onboarding guide
- [ ] **Write:** Admin documentation
- [ ] **Write:** API documentation (if applicable)
- [ ] **Write:** Troubleshooting guide

**Branch:** `docs/FH-074-user-documentation`

### FH-075: Launch Checklist

- [ ] All critical tests passing
- [ ] Production database migrated
- [ ] Stripe production keys configured
- [ ] Twilio production keys configured
- [ ] Custom domain configured
- [ ] SSL certificate active
- [ ] Monitoring dashboards set up
- [ ] Error alerts configured
- [ ] Backup strategy in place
- [ ] GDPR compliance (privacy policy, data deletion)
- [ ] Terms of service published

---

## Post-MVP Roadmap

### v1.1 - Enhanced Dispatch

- [ ] Auto-assignment algorithm (AI-powered)
- [ ] Route optimization (minimize drive time)
- [ ] Recurring job scheduling
- [ ] Team/crew assignments (multiple techs per job)

### v1.2 - Financial Tools

- [ ] Invoicing and estimates
- [ ] Payment collection (Stripe Terminal)
- [ ] QuickBooks integration
- [ ] Inventory management

### v1.3 - Advanced Features

- [ ] Native mobile apps (iOS/Android)
- [ ] Advanced analytics dashboard
- [ ] Customer satisfaction surveys
- [ ] Multi-location management

### v2.0 - Platform

- [ ] API for third-party integrations
- [ ] Marketplace for add-ons
- [ ] White-label offering
- [ ] Enterprise features (SSO, audit logs)

---

## 📊 Progress Tracking

| Phase | Tasks | Completed | Progress |
| ----- | ----- | --------- | -------- |
| 0 - Foundation | 17 | 17 | 100% |
| 1 - Core Domain | 32 | 32 | 100% |
| 2 - Dispatcher Dashboard | 36 | 15 | 42% |
| 3 - Technician Mobile | 28 | 0 | 0% |
| 4 - Customer Portal | 12 | 0 | 0% |
| 5 - Notifications | 20 | 0 | 0% |
| 6 - Billing & Polish | 16 | 0 | 0% |
| 7 - Launch Prep | 24 | 0 | 0% |
| **TOTAL** | **185** | **64** | **35%** |

---

## 🏃 Current Sprint

**Sprint 1 (Week 1):** Foundation ✅
- [x] FH-002: Run all migrations
- [x] FH-003: Create Ecto schemas with tests
- [x] FH-004: Update User for multi-tenancy
- [x] FH-005: Git repository setup
- [x] FH-010: Organizations Context
- [x] FH-011: Onboarding Flow

**Sprint 2 (Week 2):** Dispatcher Dashboard ✅
- [x] FH-012: Dispatch Context (Technicians)
- [x] FH-013: CRM Context (Customers)
- [x] FH-014: Jobs Context - Basic CRUD
- [x] FH-020: Dashboard Layout
- [x] FH-021: Technician Management UI
- [x] FH-022: Customer Management UI
- [x] FH-023: Job Creation & Editing

**Sprint 3 (Week 3):** Dispatch Board ✅
- [x] FH-024: Dispatch Board - Calendar View
- [x] FH-025: Dispatch Board - Drag & Drop Assignment
- [x] FH-026: Dispatch Board - Quick Actions

**Sprint 4 (Week 4):** Real-Time Features 🚧
- FH-027: Technician Status Sidebar
- FH-028: Live Map Component

---

## 📝 Notes

### Testing Commands

```bash
# Run all tests
mix test

# Run specific test file
mix test test/field_hub/jobs_test.exs

# Run tests matching pattern
mix test --only job_status

# Run with coverage
mix test --cover

# Watch mode (requires mix_test_watch)
mix test.watch
```

### Development Commands

```bash
# Start dev server
mix phx.server

# Interactive console
iex -S mix

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database
mix ecto.reset

# Generate migration
mix ecto.gen.migration add_something

# Format code
mix format

# Check for compiler warnings
mix compile --warnings-as-errors
```

### Useful Aliases (add to mix.exs)

```elixir
defp aliases do
  [
    # ... existing aliases ...
    "test.watch": ["test.watch"],
    "db.reset": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
    lint: ["format --check-formatted", "compile --warnings-as-errors", "credo --strict"]
  ]
end
```
