# Nova Repair — Complete Offline Core UI Summary

## Project Overview

Nova Repair is a simple offline-first Windows desktop application for repair shops.

The application must remain focused and operational.

It is not an ERP.

The MVP is centered around:

* repair intake
* repair tracking
* repair status changes
* customer-visible repair information
* optional repair price
* customer price decision
* ticket printing
* device label printing
* warranty return linking
* settings
* local backup and restore

The application is built with Flutter for Windows.

Planned technical stack:

* Flutter Desktop
* Riverpod
* Drift / SQLite
* feature-first architecture
* lightweight Clean Architecture

Architecture principle:

UI → Controller / Notifier → Use Case only when real business logic exists → Repository → Local Data Source → Drift

Do not create fake layers.

The Dashboard should not have unnecessary repository/domain abstractions if simple direct data queries are enough.

---

# Core Repair Data

Each repair contains:

* internal database ID
* visible repair code such as `REP-0001`
* optional customer name
* optional customer phone
* required device type
* optional brand
* optional model
* required reported problem
* optional received accessories
* optional device access information
* repair status
* optional repair price
* customer price decision
* optional internal notes
* optional customer-visible message
* optional warranty link to a previous repair
* timestamps

The repair code is visible to the user.

Internal database IDs must never be shown in the UI.

---

# Repair Statuses

The application uses exactly these statuses:

1. Received
2. Diagnosing
3. Waiting for Customer Approval
4. Waiting for Part
5. Repairing
6. Ready for Pickup
7. Delivered
8. Cancelled

Internal enum examples:

* received
* diagnosing
* waitingForCustomerApproval
* waitingForPart
* repairing
* readyForPickup
* delivered
* cancelled

Approved visual status color system:

* Received: neutral blue-gray
* Diagnosing: subtle slate or purple
* Waiting for Customer Approval: amber
* Waiting for Part: orange
* Repairing: blue
* Ready for Pickup: green
* Delivered: neutral gray
* Cancelled: red

Use soft semantic colors.

Do not use bright saturated colors.

Do not use pulse animations for normal statuses.

---

# Customer Price Decision

The domain may contain:

* notRequested
* pending
* approved
* rejected

Important UI decision:

A dedicated full Customer Price Decision dialog was intentionally removed from the UI scope.

The product should remain simple.

Price behavior:

* repair price is entered or edited from New Repair / Edit Repair
* customer decision can later be updated from Repair Details with a lightweight interaction
* do not create a large dedicated workflow unless implementation later proves necessary

Important:

Changing the customer price decision must not automatically change the repair status.

Repair status and price decision are separate concepts.

---

# Out of Scope

Do not add:

* customer accounts
* customer database
* employees
* user roles
* authentication
* inventory
* suppliers
* accounting
* payments
* invoices
* taxes
* discounts
* profit tracking
* images
* device shelf location
* cloud sync
* notifications
* SMS
* WhatsApp
* online communication integrations
* multi-device sync
* licensing
* automatic cloud backup

The offline MVP must remain simple.

---

# Approved Global Design System

## General

Desktop-first layout around 1440×900.

Use:

* 240px fixed left sidebar
* Manrope typography
* light neutral background
* white cards and surfaces
* restrained primary blue
* subtle borders
* medium border radius
* compact efficient spacing

Avoid:

* glassmorphism
* decorative gradients
* large background blobs
* decorative photos
* fake statistics
* large empty spaces
* excessive shadows
* animations without functional value

---

# Approved Shared Sidebar

The sidebar must be one shared reusable Flutter widget used everywhere.

Exact structure:

Nova Repair
Management System

Navigation:

* Dashboard
* Repairs
* Settings

Bottom identity:

TechFix Repair
Repair Center

Do not show:

* avatar
* Admin User
* Manager
* role
* account
* initials
* profile controls

One shared sidebar widget should prevent design drift between screens.

---

# Approved Shared Page Header

Use one shared reusable page header.

Typical structure:

Title
Subtitle

Examples:

Dashboard
Overview of your repair activity

Repairs
Manage and track all repair jobs

New Repair
Create a new repair job

Repair Details
View and manage repair information

Edit Repair
Update repair information for REP-0042

Settings
Manage shop information and application preferences

Backup & Restore
Protect and recover your Nova Repair data

Do not add globally:

* search
* notifications
* account controls
* New Repair button

Screen-specific actions should appear only where necessary.

---

# Screen 1 — Dashboard

Status:

APPROVED

Layout:

* four summary cards
* Recent Repairs table
* Needs Attention panel

Summary cards:

* Active Repairs
* Waiting for Approval
* Waiting for Part
* Ready for Pickup

Do not add:

* charts
* fake revenue
* fake daily goals
* communication actions
* notification center
* account controls

Recent Repairs table should use repair terminology.

Use:

`Repair Code`

not:

`Order ID`
`Ticket ID`

Rows should be clickable.

Needs Attention is only for meaningful repair-related situations.

---

# Screen 2 — Repairs List

Status:

APPROVED

Page header:

Title:
`Repairs`

Subtitle:
`Manage and track all repair jobs`

Primary action:
`New Repair`

Search:

Search by:

* repair code
* customer
* phone
* device

Filters:

* All Statuses
* All Dates
* More Filters

Quick filter chips:

* All
* Active
* Waiting for Approval
* Waiting for Part
* Ready for Pickup
* Delivered

Table columns:

* Repair Code
* Device
* Customer
* Phone
* Status
* Received Date
* Last Updated
* chevron

Missing optional data should be shown as:

`—`

Old repair indicator:

Use subtle amber text such as:

`Open 16 days`

Do not use:

* red full-row warning
* pulse animation

Ready for Pickup and Old Repairs are filters inside this screen.

They are not separate pages.

---

# Screen 3 — New Repair

Status:

APPROVED

Use a two-column form layout.

## Left Column

### Customer Information

Fields:

* Customer Name — optional
* Phone Number — optional

Example phone placeholder:

`0555 12 34 56`

Do not add customer lookup or customer profiles.

### Device Information

Fields:

* Device Type — required
* Brand — optional
* Model — optional

Device Type must be a text field.

Do not use a dropdown.

### Reported Problem

Required multiline field.

### Notes

Contains:

* Internal Notes
* Customer Message

Helper for Customer Message:

`This may later be shown to the customer in repair tracking`

## Right Column

### Initial Status

Show:

`Received`

No status dropdown.

New repairs always start as Received.

### Received Accessories

Optional multiline field.

Helper:

`List any accessories received with the device`

### Device Access

Field label:

`PIN / Password / Access Note`

Optional.

Helper:

`Internal only — not shown on printed tickets`

Do not use red warning styling.

### Price

Section title:

`Price`

Field:

`Proposed Repair Price`

Integer values only.

DZD.

No decimals.

Suffix:

`DA`

Optional.

Helper:

`Optional — can be added later after diagnosis`

## Bottom Sticky Action Bar

Buttons:

* Cancel
* Save Repair
* Save & Print

Save & Print is the primary action.

---

# Screen 4 — Repair Details

Status:

APPROVED

## Page Header

Title:
`Repair Details`

Subtitle:
`View and manage repair information`

## Repair Context Header

Show:

* Back to Repairs
* REP-0042
* device name
* current status badge

Actions:

* Edit Repair
* Change Status
* Print

## Main Layout

Two-column layout.

### Left Column

#### Device Information

* Device Type
* Brand
* Model

#### Reported Problem

Read-only text.

Do not wrap the problem in quotation marks.

#### Notes

One shared Notes section containing:

* Internal Notes
* Customer Message

#### Repair Timeline

Approved event wording examples:

* Customer message updated
* Status changed to Repairing
* Status changed to Diagnosing
* Repair received

Timeline should remain simple.

No employee names unless the future product adds employees.

### Right Column

#### Summary

* Code
* Status
* Received
* Last Updated

#### Customer

Simple read-only fields:

* Customer Name
* Phone Number

Do not show:

* avatar
* initials
* customer account/profile actions

#### Price & Approval

Show:

* Proposed Repair Price
* Customer Decision

Do not mix accessories into this card.

#### Received Accessories

Separate section.

#### Device Access

Show the value internally.

Helper:

`Internal only — not shown on printed tickets`

#### Warranty

Show:

`No previous repair linked`

Action:

`Create Warranty Return`

Use a calm secondary button.

Do not use large dashed drop-zone styling.

---

# Screen 5 — Edit Repair

Status:

APPROVED

The Edit Repair screen must reuse the same UI structure and reusable widgets as New Repair.

It is not a separate design.

Page header:

Title:
`Edit Repair`

Subtitle:
`Update repair information for REP-0042`

All fields are prefilled.

Example data:

Customer Name:
`Ahmed Benali`

Phone:
`0555 12 34 56`

Device Type:
`Laptop`

Brand:
`HP`

Model:
`EliteBook 840`

Reported Problem:
`The laptop does not power on. The customer reports that it stopped working after suddenly shutting down during use.`

Internal Notes:
`Power supply section requires further testing. No visible liquid damage.`

Customer Message:
`The device is currently being repaired. We will update the status when testing is complete.`

Received Accessories:
`Charger, laptop bag`

Device Access:
`1234`

Price:
`6500`

## Current Status

Show:

`Repairing`

as read-only information.

No status dropdown.

Status changes happen only through Change Status.

## Bottom Actions

Only:

* Cancel
* Save Changes

Do not include:

* Save & Print
* Print
* Delete
* Archive

Printing happens from Repair Details.

---

# Screen 6 — Change Status Dialog

Status:

APPROVED

This is a centered modal over Repair Details.

Approximate width:

560px

Header:

Title:
`Change Repair Status`

Subtitle:
`REP-0042 — HP EliteBook 840`

Show current status:

`Repairing`

Use a static blue badge.

No pulse animation.

## Status List

Show all eight statuses:

* Received
* Diagnosing
* Waiting for Customer Approval
* Waiting for Part
* Repairing
* Ready for Pickup
* Delivered
* Cancelled

Each option contains:

* small semantic color indicator
* status name
* short description

Descriptions:

Received:
`Device has been received by the repair shop`

Diagnosing:
`Device is being inspected and diagnosed`

Waiting for Customer Approval:
`Waiting for the customer to approve the proposed price`

Waiting for Part:
`Repair is paused while waiting for a required part`

Repairing:
`Repair work is currently in progress`

Ready for Pickup:
`Repair is complete and the device is ready for collection`

Delivered:
`Device has been returned to the customer`

Cancelled:
`Repair job has been cancelled`

Current status should be marked:

`Current`

The user must not select the same current status again.

Example selected new status:

`Ready for Pickup`

Use:

* soft green background
* green indicator
* check icon

Do not add:

* Recommended
* Suggested
* Best Choice

## Customer Message

Optional multiline field.

Label:

`Customer Message`

Example:

`Your device is repaired and ready for pickup.`

Helper:

`This may later be shown to the customer in repair tracking`

Do not add SMS or notification controls.

## Footer

* Cancel
* Update Status

---

# Screen 7 — Print Preview

Status:

APPROVED

One reusable Print Preview screen handles:

* Customer Ticket
* Device Label

Use:

* left control panel
* right preview workspace

## Left Control Panel

### Document

Options:

* Customer Ticket
* Device Label

Use compact selectable rows.

Do not use large radio buttons.

### Print Settings

Copies:

Default:
`1`

Printer:

`Default Printer`

Paper:

For Customer Ticket:
`Receipt / A4`

For Device Label:
`Label`

Do not add:

* Save as PDF
* Export
* Email
* Share

## Actions

* Back
* Print

---

# Customer Ticket Preview

Status:

APPROVED

The customer ticket is a repair intake and tracking document.

It is not an invoice.

Use mostly black text on white.

## Shop Header

TechFix Repair
Repair Center

Phone:
`0555 00 11 22`

Address:
`Chlef, Algeria`

Do not invent a street address.

## Ticket Data

Show:

Repair Code:
`REP-0042`

Received Date:
`04 Jul 2026, 10:30`

Customer:
`Ahmed Benali`

Phone:
`0555 12 34 56`

Device:
`HP EliteBook 840`

Device Type:
`Laptop`

Reported Problem:
`The laptop does not power on.`

Received Accessories:
`Charger, laptop bag`

Do not use quotation marks around the reported problem.

Do not print the repair price.

Decision made intentionally:

The Customer Ticket should not contain price information because:

* price may change after diagnosis
* price may be unavailable during intake
* ticket is not an invoice
* this avoids confusion

## QR

Show a real QR code in the final Flutter implementation.

Text:

`Scan to track your repair`

Code:

`REP-0042`

Do not show:

* raw tracking token
* URL
* internal database ID

## Footer

`Please keep this ticket until your device is collected.`

`Thank you for choosing TechFix Repair.`

Important correction for implementation:

The right-side ticket header date label must be:

`Received Date`

not:

`Repair Code`

This was a Stitch visual typo.

---

# Device Label Preview

Status:

APPROVED

Small physical label.

Target visual concept similar to approximately 40×60mm.

Final actual dimensions should be controlled by the printer and print layout, not hardcoded from the HTML preview.

Include only:

* TechFix Repair
* REP-0042
* HP EliteBook 840
* Ahmed Benali
* 0555 12 34 56
* small QR code

Repair code must be visually dominant.

Never include:

* reported problem
* price
* PIN
* password
* access note
* internal notes
* customer message
* price decision
* warranty information

The QR must be real in Flutter.

The Stitch CSS pattern was only a visual placeholder.

---

# Screen 8 — Settings

Status:

APPROVED

Page header:

Title:
`Settings`

Subtitle:
`Manage shop information and application preferences`

Use approximately 900–1000px centered content width.

## Section 1 — Shop Information

Description:

`Information shown on printed customer tickets`

Fields:

Shop Name:
`TechFix Repair`

Shop Subtitle:
`Repair Center`

Phone Number:
`0555 00 11 22`

Address:
`Chlef, Algeria`

Do not add:

* email
* website
* tax number
* social media
* business registration

## Section 2 — Printing Defaults

Description:

`Choose the default printers used for repair documents`

Fields:

Customer Ticket Printer:
`Default Printer`

Helper:
`Used for customer repair tickets`

Device Label Printer:
`Default Printer`

Helper:
`Used for small device labels`

The real application should load actual printers from the operating system.

Do not hardcode fake printer names.

## Section 3 — Data

Navigation card:

Title:
`Backup & Restore`

Description:
`Create backups and restore Nova Repair data`

Chevron opens the dedicated Backup & Restore screen.

## Save Action

Only:

`Save Changes`

Do not show Discard Changes by default.

---

# Screen 9 — Backup & Restore

Status:

APPROVED

Settings remains active in the sidebar.

Show:

`Back to Settings`

inside page content.

Recommended implementation:

Do not use an empty 64px top bar.

Either:

* remove the empty bar completely

or:

* use the shared page header properly

Preferred final implementation:

No unnecessary empty header area.

## Page Header

Title:
`Backup & Restore`

Subtitle:
`Protect and recover your Nova Repair data`

## Current Data

Compact summary:

Repairs:
`248`

Database Size:
`18.4 MB`

Last Updated:
`Today, 16:40`

No charts.

No large dashboard-style icons.

## Create Backup

Title:
`Create Backup`

Description:
`Create a local backup of all Nova Repair data`

Helper:
`The backup includes repairs, settings, and application data.`

Last Backup:
`02 Jul 2026, 18:25`

File:
`NovaRepair_Backup_2026-07-02.nrbackup`

Action:
`Create Backup`

The application should open a system save dialog.

Do not show a file path field directly on the screen.

## Restore Backup

Title:
`Restore Backup`

Description:
`Restore Nova Repair data from a previous backup file`

Action:
`Choose Backup File`

Example selected file:
`NovaRepair_Backup_2026-07-02.nrbackup`

Selecting a file must not immediately restore it.

## Warning

Use a soft amber warning.

Text:
`Restoring a backup will replace the current Nova Repair data.`

Secondary text:
`Create a new backup first if you may need to return to the current data.`

The main page should not use strong red styling.

## Restore Action

Button:
`Restore Backup`

Use a restrained secondary or outlined style.

Pressing it opens the Restore Confirmation Dialog.

---

# Screen 10 — Restore Confirmation Dialog

Status:

APPROVED

Compact centered modal.

Approximate width:

480px

Displayed over the real Backup & Restore screen.

Use a dark scrim.

Do not use blur in final Flutter implementation.

## Header

Warning icon.

Title:
`Restore Backup?`

Subtitle:
`Current Nova Repair data will be replaced`

Close icon.

## Backup File Summary

Label:
`Backup File`

Value:
`NovaRepair_Backup_2026-07-02.nrbackup`

Read-only.

Do not show:

* file path
* rename controls
* file browser

## Warning

Text:
`Restoring this backup will replace the current Nova Repair data.`

Secondary text:
`This action cannot be undone.`

Use restrained red/error styling.

Do not make the whole dialog red.

## Helper

`Create a new backup first if you may need to return to the current data.`

Do not add another Create Backup button inside the dialog.

## Actions

* Cancel
* Restore Data

`Restore Data` is the destructive red action.

Do not require:

* typing RESTORE
* password
* checkbox
* multiple confirmation steps

One confirmation dialog is enough.

---

# Offline Core UI Status

The complete approved offline UI now contains:

1. Dashboard
2. Repairs List
3. New Repair
4. Repair Details
5. Edit Repair
6. Change Status Dialog
7. Print Preview — Customer Ticket
8. Print Preview — Device Label
9. Settings
10. Backup & Restore
11. Restore Confirmation Dialog

---

# Important Implementation Strategy

Do not implement each screen independently.

Create reusable shared widgets first.

At minimum, shared reusable UI should include:

* AppShell
* NovaSidebar
* PageHeader
* SectionCard
* StatusBadge
* RepairTable
* EmptyValueText
* FormSection
* AppTextField
* AppTextArea
* PrimaryButton
* SecondaryButton
* BottomActionBar
* ConfirmationDialog
* PrintPreviewShell

New Repair and Edit Repair should use the same form structure and reusable widgets.

Print Preview should use one screen with a document mode:

* customerTicket
* deviceLabel

Do not create separate duplicated pages.

Repair Details and dialogs should reuse the same StatusBadge implementation.

The sidebar must exist once in the codebase.

Do not create a separate sidebar implementation for every screen.

The page header must exist once in the codebase.

This avoids the design drift that appeared during Stitch generation.

---

# Existing Development Status

The project foundation was already created previously.

Prompt 001 completed:

* Flutter project foundation
* Riverpod shell
* Dashboard placeholder
* Repairs placeholder
* Settings placeholder
* light theme
* Drift database infrastructure
* schema version 1 with no tables

Report:

`docs/reports/001-project-foundation.md`

Prompt 002 was already prepared for:

* repair domain
* repair statuses
* customer price decision
* database schema
* migration v1 → v2
* repository / datasource only when meaningful
* tests
* report

Expected report:

`docs/reports/002-repair-domain-database.md`

Before implementing UI, inspect the current repository and verify whether Prompt 002 has already been completed.

Do not assume.

Do not duplicate existing work.

---

# Next Development Direction

The next step should be:

1. inspect current repository state
2. read all existing reports
3. verify whether Prompt 002 is complete
4. inspect the existing AppShell and theme
5. create shared reusable UI foundations based on the approved design system
6. then implement the first real screen incrementally

Recommended next UI implementation order:

1. shared shell and design tokens
2. Dashboard
3. Repairs List
4. New Repair
5. Repair Details
6. Change Status Dialog
7. Edit Repair
8. Print Preview
9. Settings
10. Backup & Restore
11. Restore Confirmation Dialog

Important:

Do not implement all screens in one huge change.

Continue using small controlled Codex prompts with:

* exact scope
* files inspected
* files changed
* tests
* report
* no unrelated refactors
