# Task: Enhance Portal Dashboard UI

## Objective
Update the `FieldHubWeb.PortalLive.Dashboard` to provide a premium, intelligent experience for customers. This includes transitioning from a basic list to an "Intelligent Grid" with high-impact KPIs (Lifetime Invoiced, etc.) and a polished visual language that builds trust.

## Design Commitment: Intelligent Narrative Grid
- **Geometry**: Sharp 2px corners for a "technical/professional" feel.
- **Topological Choice**: Staggered KPI row at the top followed by an asymmetrical 65/35 split. Main column for active jobs/history, sidebar for "Service Intelligence" (Stats & Technician context).
- **Palette**: `Slate-950` background with `Emerald-500` and `Teal-500` accents. No purple.
- **Micro-animations**: Staggered entry for job cards, pulsing "Live Service" indicator for active jobs.
- **Cliché Liquidation**: Breaking away from the standard 3-column bento grid. Intentionally avoiding the "Safe SaaS Blue".

## Implemented KPIs
1. **Lifetime Service Value**: Total amount invoiced (all-time). - **COMPLETED**
2. **Total Service Histroy**: Count of all completed jobs. - **COMPLETED**
3. **Avg Completion**: Real calculation of days from request to sign-off. - **COMPLETED**
4. **Active Trust Score**: Completion rate reliability score. - **COMPLETED**

## Implementation Steps

### Phase 1: Data Preparation [DONE]
- Update `PortalLive.Dashboard` to calculate real-time stats using PostgreSQL fragments for timing and aggregation.
- Map industry-standard terminology from organization settings.

### Phase 2: UI Overhaul [DONE]
- Implemented `render/1` with the asymmetrical grid layout.
- Created `kpi_widget` private component for consistent styling.
- Redesigned active job cards with status themes and hover states.

### Phase 3: Polish & Interactivity [DONE]
- Added pulsing "System Live" indicator.
- Refined SMS preferences toggle with confirmation logic and event handling.
- Optimized for responsiveness (grid-cols-1 to grid-cols-12).

## Verification Criteria
- [x] Life-time invoiced amount is accurate.
- [x] Mobile responsiveness remains solid (stacking correctly).
- [x] Pure Tailwind implementation; no conflicts.
- [x] Dynamic labels reflect organization terminology.
- [x] SMS toggle persists changes to database.
