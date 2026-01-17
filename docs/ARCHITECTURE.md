# Field Service Dispatch Hub - Technical Architecture

> **Project Codename:** FieldHub  
> **Created:** 2026-01-17  
> **Stack:** Elixir, Phoenix, LiveView, PostgreSQL + PostGIS

---

## 🎯 Product Overview

**Field Service Dispatch Hub** is a real-time dispatch and scheduling platform for field service contractors (HVAC, plumbing, electrical, pest control). It provides:

- **Dispatcher Dashboard** - Real-time job scheduling with drag-and-drop assignment
- **Technician Mobile App** - PWA with offline support for field workers
- **Customer Portal** - Self-service booking and live technician tracking
- **AI Job Assignment** - Smart auto-assignment based on skills, location, availability

### Target Market
- **ICP:** 5-30 technician trade contractors
- **Pricing:** $99-299/month per location (vs $250-500/technician for ServiceTitan)
- **Goal:** 400-500 customers = $100K MRR

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FIELD SERVICE DISPATCH HUB                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                   │
│  │  DISPATCHER  │    │  TECHNICIAN  │    │   CUSTOMER   │                   │
│  │   DASHBOARD  │    │  MOBILE APP  │    │    PORTAL    │                   │
│  │  (LiveView)  │    │    (PWA)     │    │  (LiveView)  │                   │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘                   │
│         │                   │                   │                           │
│         └───────────────────┼───────────────────┘                           │
│                             │                                                │
│                    ┌────────▼────────┐                                       │
│                    │ PHOENIX CHANNELS │  ← Real-time WebSocket layer        │
│                    │  (PG2 PubSub)    │                                      │
│                    └────────┬─────────┘                                      │
│                             │                                                │
│         ┌───────────────────┼───────────────────┐                           │
│         │                   │                   │                           │
│  ┌──────▼───────┐   ┌───────▼───────┐   ┌──────▼───────┐                   │
│  │   DISPATCH   │   │     JOB       │   │   ROUTING    │                   │
│  │   CONTEXT    │   │   CONTEXT     │   │   SERVICE    │                   │
│  └──────────────┘   └───────────────┘   └──────────────┘                   │
│                             │                                                │
│                    ┌────────▼────────┐                                       │
│                    │   POSTGRESQL    │                                       │
│                    │   + PostGIS     │  ← Geospatial queries                │
│                    └─────────────────┘                                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Database Schema

### Core Entities

#### Organizations (Multi-tenant)
```elixir
schema "organizations" do
  field :name, :string
  field :slug, :string                    # URL-friendly identifier
  field :phone, :string
  field :timezone, :string, default: "America/New_York"
  field :subscription_tier, Ecto.Enum, values: [:starter, :growth, :pro]
  field :subscription_status, Ecto.Enum, values: [:trial, :active, :past_due, :cancelled]
  field :trial_ends_at, :utc_datetime
  field :stripe_customer_id, :string

  has_many :users, User
  has_many :technicians, Technician
  has_many :jobs, Job
  has_many :customers, Customer

  timestamps()
end
```

#### Users (Dispatchers, Admins, Office Staff)
```elixir
schema "users" do
  field :email, :string
  field :hashed_password, :string
  field :name, :string
  field :role, Ecto.Enum, values: [:owner, :admin, :dispatcher, :viewer]
  field :phone, :string
  field :confirmed_at, :utc_datetime

  belongs_to :organization, Organization

  timestamps()
end
```

#### Technicians (Field Workers)
```elixir
schema "technicians" do
  field :name, :string
  field :phone, :string
  field :email, :string
  field :status, Ecto.Enum, values: [:available, :on_job, :traveling, :break, :off_duty]
  field :skills, {:array, :string}        # ["hvac", "plumbing", "electrical"]
  field :certifications, {:array, :string}
  field :hourly_rate, :decimal
  field :color, :string                   # For calendar display
  field :avatar_url, :string

  # Real-time location (updated by mobile app)
  field :current_lat, :float
  field :current_lng, :float
  field :location_updated_at, :utc_datetime

  # Push notification tokens
  field :fcm_token, :string
  field :apns_token, :string

  belongs_to :organization, Organization
  has_many :jobs, Job

  timestamps()
end
```

#### Customers
```elixir
schema "customers" do
  field :name, :string
  field :email, :string
  field :phone, :string
  field :notes, :string

  # Service address
  field :address_line1, :string
  field :address_line2, :string
  field :city, :string
  field :state, :string
  field :zip, :string

  # Geolocation (populated via geocoding)
  field :lat, :float
  field :lng, :float

  # Customer portal access
  field :portal_token, :string
  field :portal_enabled, :boolean, default: true

  belongs_to :organization, Organization
  has_many :jobs, Job

  timestamps()
end
```

#### Jobs (Core Work Unit)
```elixir
schema "jobs" do
  field :number, :string                  # "JOB-2026-00142"
  field :title, :string                   # "AC Not Cooling"
  field :description, :string
  field :job_type, Ecto.Enum, values: [:service_call, :installation, :maintenance, :emergency, :estimate]
  field :priority, Ecto.Enum, values: [:low, :normal, :high, :urgent]
  field :status, Ecto.Enum, values: [
    :unscheduled,
    :scheduled,
    :dispatched,
    :en_route,
    :on_site,
    :in_progress,
    :completed,
    :cancelled,
    :on_hold
  ]

  # Scheduling
  field :scheduled_date, :date
  field :scheduled_start, :time
  field :scheduled_end, :time
  field :estimated_duration_minutes, :integer, default: 60

  # Actual times (filled by technician)
  field :actual_start, :utc_datetime
  field :actual_end, :utc_datetime

  # Service location
  field :service_address, :string
  field :service_lat, :float
  field :service_lng, :float

  # Work performed
  field :work_performed, :string
  field :technician_notes, :string
  field :internal_notes, :string

  # Financial
  field :quoted_amount, :decimal
  field :actual_amount, :decimal
  field :payment_status, Ecto.Enum, values: [:pending, :invoiced, :paid, :refunded]

  # Completion
  field :customer_signature, :string      # Base64 encoded
  field :photos, {:array, :string}        # S3 URLs

  belongs_to :organization, Organization
  belongs_to :customer, Customer
  belongs_to :technician, Technician
  belongs_to :created_by, User

  has_many :job_events, JobEvent

  timestamps()
end
```

#### Job Events (Audit Trail)
```elixir
schema "job_events" do
  field :event_type, :string              # "status_changed", "assigned", "note_added"
  field :old_value, :map
  field :new_value, :map
  field :metadata, :map                   # GPS coords, device info, etc.

  belongs_to :job, Job
  belongs_to :actor, User
  belongs_to :technician, Technician

  timestamps(updated_at: false)           # Immutable events
end
```

---

## ⚡ Real-Time Architecture

### PubSub Topics (No Redis - Using Phoenix.PubSub with PG2)

| Topic Pattern | Purpose | Subscribers |
|--------------|---------|-------------|
| `org:{org_id}:jobs` | All job updates for an org | Dispatcher dashboard |
| `org:{org_id}:technicians` | Tech status/location updates | Dispatcher dashboard |
| `tech:{tech_id}:jobs` | Job assignments for a tech | Technician mobile app |
| `customer:{customer_id}:jobs` | Job updates for customer | Customer portal |

### Broadcast Events

```elixir
# Job Events
{:job_created, job}
{:job_updated, job}
{:job_status_changed, job, old_status, new_status}

# Technician Events
{:technician_location_updated, tech_id, lat, lng}
{:technician_status_changed, tech}
```

---

## 📱 Mobile Strategy

### PWA (Progressive Web App)

**Why PWA over Native (for MVP):**
- Single codebase (LiveView)
- Instant updates (no app store)
- Offline support via Service Workers
- GPS and Camera access
- 2-4 weeks to build vs 2-4 months native

### Offline Capabilities

1. **Service Worker** caches critical assets
2. **IndexedDB** stores pending job updates
3. **Background Sync** pushes changes when online

---

## 🗺️ Routing & Geospatial

### PostGIS Integration
- Store locations as geography points
- Spatial indexes for "find nearby" queries
- Distance calculations in SQL

### Route Optimization
- Start with **Google Maps Directions API** (optimize:true)
- Future: Custom algorithm to reduce API costs

---

## 🚀 Deployment Architecture

```
                    ┌────────────────────────────────────────┐
                    │            LOAD BALANCER               │
                    │              (Fly.io)                  │
                    └───────────────────┬────────────────────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
     ┌────────▼────────┐       ┌────────▼────────┐       ┌────────▼────────┐
     │   PHOENIX 1     │◄─────►│   PHOENIX 2     │◄─────►│   PHOENIX N     │
     │   (LiveView)    │ libcluster                      │   (LiveView)    │
     └────────┬────────┘       └────────┬────────┘       └────────┬────────┘
              │                         │                         │
              └─────────────────────────┼─────────────────────────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
     ┌────────▼────────┐       ┌────────▼────────┐       ┌────────▼────────┐
     │   POSTGRESQL    │       │ OBJECT STORAGE  │       │   EXTERNAL      │
     │   + POSTGIS     │       │    (S3/R2)      │       │   SERVICES      │
     │                 │       │                 │       │                 │
     │ • All data      │       │ • Photos        │       │ • Stripe        │
     │ • Geo queries   │       │ • Signatures    │       │ • Twilio        │
     └─────────────────┘       └─────────────────┘       │ • Google Maps   │
                                                         └─────────────────┘
```

### Cluster Communication (No Redis)
- **libcluster** for node discovery
- **Erlang distributed** for PubSub across nodes
- **Horde** for distributed supervisors (optional)

---

## 📂 Project Structure

```
field_hub/
├── lib/
│   ├── field_hub/
│   │   ├── accounts/           # Users, Auth, Organizations
│   │   │   ├── organization.ex
│   │   │   ├── user.ex
│   │   │   └── user_token.ex
│   │   ├── dispatch/           # Technicians, Assignment Logic
│   │   │   ├── technician.ex
│   │   │   ├── broadcaster.ex
│   │   │   └── auto_assigner.ex
│   │   ├── jobs/               # Jobs, Events, Line Items
│   │   │   ├── job.ex
│   │   │   ├── job_event.ex
│   │   │   └── job_number.ex
│   │   ├── crm/                # Customers, Properties
│   │   │   └── customer.ex
│   │   ├── routing/            # Route optimization
│   │   │   └── route_optimizer.ex
│   │   └── notifications/      # SMS, Email, Push
│   │       └── notifier.ex
│   │
│   └── field_hub_web/
│       ├── live/
│       │   ├── dispatch_live/  # Dispatcher dashboard
│       │   ├── job_live/       # Job CRUD
│       │   ├── tech_live/      # Technician mobile
│       │   └── portal_live/    # Customer portal
│       ├── components/         # Shared UI components
│       └── layouts/
│
├── assets/
│   ├── js/
│   │   ├── app.js
│   │   ├── hooks/              # LiveView hooks
│   │   │   ├── sortable.js     # Drag & drop
│   │   │   ├── map.js          # Leaflet/Mapbox
│   │   │   └── geolocation.js  # GPS tracking
│   │   └── service-worker.js   # Offline support
│   └── css/
│       └── app.css
│
├── priv/
│   └── repo/migrations/
│
└── docs/
    └── ARCHITECTURE.md         # This file
```

---

## 🔑 Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Real-time | Phoenix Channels + PG2 | No Redis dependency, native Erlang distribution |
| Database | PostgreSQL + PostGIS | Geospatial queries, ACID, proven scale |
| Mobile | PWA (LiveView) | Fast to build, single codebase, offline capable |
| Auth | phx.gen.auth | Battle-tested, simple, customizable |
| Payments | Stripe | Best-in-class, webhooks, Billing Portal |
| SMS | Twilio | Reliable, good API, reasonable pricing |
| Maps | Leaflet + OpenStreetMap | Free tiles, or Google Maps for routing |
| File Storage | S3/Cloudflare R2 | Cost-effective, CDN distribution |
| Deployment | Fly.io | Easy clustering, global edge, Postgres included |

---

## 📈 Scaling Considerations

### Single Node Capacity (Fly.io shared-cpu-1x)
- ~10,000 concurrent WebSocket connections
- ~500 organizations with 20 techs each
- Sufficient for first $100K MRR

### Multi-Node Scaling
1. Add **libcluster** for automatic node discovery
2. Phoenix.PubSub automatically distributes across nodes
3. Sticky sessions via Fly.io `fly-replay` header
4. Read replicas for heavy query workloads

---

## 🎯 MVP Feature Scope

### Must Have (Week 1-8)
- [ ] Organization signup & onboarding
- [ ] User authentication (phx.gen.auth)
- [ ] Technician management (CRUD)
- [ ] Customer management (CRUD)
- [ ] Job creation & scheduling
- [ ] Dispatcher calendar view (day/week)
- [ ] Drag-and-drop job assignment
- [ ] Real-time status updates
- [ ] Technician mobile dashboard (PWA)
- [ ] Job status workflow (travel → arrive → complete)
- [ ] Basic SMS notifications

### Nice to Have (Week 9-12)
- [ ] Auto-assignment algorithm
- [ ] Route optimization
- [ ] Customer portal
- [ ] Signature capture
- [ ] Photo attachments
- [ ] Stripe billing integration

### Future
- [ ] Invoicing & payments
- [ ] Reporting & analytics
- [ ] Inventory management
- [ ] Native mobile apps
