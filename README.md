# FieldHub Service Platform

FieldHub is a white-label, industry-agnostic Field Service Management (FSM) platform engineered for scale and flexibility. It empowers contractors and service businesses to manage their entire operation—from job scheduling and dispatch to customer management and invoicing—within a single, intuitive interface.

## 🎯 Project Vision

FieldHub creates a standardized yet customizable core for the service industry. Whether for HVAC, Plumbing, Landscaping, or Home Health, FieldHub adapts to the jargon and workflow of the specific vertical without code changes.

### Core Philosophy
*   **Industry Agnostic:** Built to be renamed and reconfigured. "Technicians" can become "Providers", "Jobs" can become "Visits".
*   **Real-Time First:** Built on Phoenix LiveView for instant updates across Dispatch and Mobile.
*   **Mobile Optimized:** A PWA experience for field workers that rivals native apps.

## ✨ Key Features

### 🏢 Organization & Multi-Tenancy
*   **Secure Isolation:** Complete data separation between tenant organizations.
*   **Custom Settings:** Each organization configures its own terminology, branding, and workflows.
*   **Custom Fields:** Dynamic schema extension for Jobs, Customers, and Technicians properly integrated into forms.

### 🧩 Dispatch & Operations
*   **Live Dispatch Board:** Drag-and-drop calendar with real-time collision detection.
*   **Smart Queue:** "unassigned" job holding area for rapid triage.
*   **Technician Status:** Real-time visibility into who is `En Route`, `On Site`, or `Available`.
*   **Map Integration:** Geospatial visualization of jobs and workforce.

### 📱 Technician Mobile PWA
*   **Offline-Ready:** (In progress) Architecture supports low-connectivity environments.
*   **Job Lifecycle:** Simple one-tap status updates.
*   **Evidence Capture:** Photos, signatures, and notes attached directly to the job event log.

## 🛠 Technology Stack

*   **Elixir & Phoenix (1.7+):** The backbone of our fault-tolerant, concurrent backend.
*   **Phoenix LiveView:** For rich, real-time client-side interactions.
*   **PostgreSQL:** Relational data integrity.
*   **TailwindCSS:** Utility-first styling for a premium, custom UI.
*   **Alpine.js / Hooks:** For client-side interactions (Maps, Charts).

## 🚀 Getting Started

### Prerequisites

*   Elixir and Erlang (via ASDF or standard installers)
*   PostgreSQL
*   Node.js (for asset compilation)

### Setup

1.  **Install dependencies:**
    ```bash
    mix setup
    ```

2.  **Start the Server:**
    ```bash
    mix phx.server
    ```

    Visit [`localhost:4000`](http://localhost:4000) to see the application.

### Development Workflow

We use a feature-branch workflow. Please see `TODO.md` in the project root for detailed development phases and roadmap status.

## 🧪 Testing

Run the comprehensive test suite:

```bash
mix test
```

## 📄 License

Proprietary Software. All rights reserved.
