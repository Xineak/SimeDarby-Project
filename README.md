<div align="center">

# 🤖 CONVY
### Smart Residential Autonomous Last-Mile Delivery System

**Bringing convenience closer to home.**

*A township delivery concept developed for the Sime Darby Property University Hackathon 2026 — Township of Tomorrow.*

**Focus:** Gated landed residential communities · **Prototype:** Mobile app + robot design and workflow visualisation

</div>

---

## 🌿 Overview

CONVY proposes a residential delivery system that connects **designated smart lockers at a community collection point**, a **resident mobile application**, an **autonomous delivery robot**, and **built-in collection compartments beside residents' gates**.

Instead of requiring residents to travel to a guardhouse to collect food or parcels, CONVY is designed to complete the final leg of delivery within an approved residential area. Delivery riders can hand over eligible items at a central location, while residents request robot-assisted delivery using the app.

> **Project status:** CONVY is a design and demonstration prototype. The mobile application illustrates the intended user experience; robot navigation, mechanical transfer, smart-locker controls, and end-to-end physical delivery have **not yet been validated** on a working robot.

## 💡 The Problem

In many gated communities, central collection points and access restrictions create a difficult trade-off between **delivery convenience and controlled community access**:

- Residents may need to travel to the guardhouse, even during heavy rain or when occupied with work or family responsibilities.
- Older residents and people with mobility limitations may find manual collection challenging.
- Transporting bulky or multiple parcels from a collection point can be inconvenient.
- Security teams and property management must manage external riders and delivery handovers.

**Our challenge:** How might we improve the final stage of food and parcel delivery while supporting residential convenience, accessibility, and access management?

## 📊 Preliminary Problem Validation

The team collected **64 responses** in a preliminary online survey of residents from guarded landed housing, non-guarded landed housing, and high-rise residences.

| Survey finding | Responses |
| --- | ---: |
| Collection during bad weather identified as a challenge | **62.5%** |
| Travelling to the guardhouse identified as a challenge | **57.8%** |
| Carrying heavy items identified as a challenge | **43.8%** |
| Real-time tracking/status information selected as important | **76.6%** |
| Likely or very likely to use the proposed CONVY service | **84.4%** |

These are **exploratory, self-reported findings** from a small mixed residential sample, not representative population estimates or proof of actual future adoption.

## ⚙️ How CONVY Is Designed to Work

1. **Central drop-off:** A delivery rider leaves an eligible parcel or food order in the designated locker at the guardhouse or collection area.
2. **Resident request:** The resident uses the CONVY app to request delivery to the assigned home.
3. **Authorised collection (proposed):** The system verifies the request and opens the matching locker for up to **10 minutes**. A robot aligns with the locker and uses a motorised retractable tray to retrieve the item.
4. **Secure transport (proposed):** The tray retracts and the roller shutter closes while the robot follows a predefined, approved residential route.
5. **Gate-side transfer (proposed):** The robot transfers the item to a compatible built-in collection compartment beside the resident's gate.
6. **Resident collection (proposed):** The resident receives a status update and retrieves the item without travelling back to the guardhouse or opening the main gate.

**Important:** The timed locker access, autonomous movement, item transfer and gate-side compartment are **proposed engineering functions**, not demonstrated working hardware.

## 📱 Resident Mobile Application

The Flutter application prototype demonstrates the resident-facing workflow:

| Screen / feature | Purpose |
| --- | --- |
| Login and registration | Resident account access |
| Home dashboard | Delivery overview, current status and shortcuts |
| Request robot | Choose delivery details and request immediate or scheduled service |
| Delivery tracking | Illustrative robot route, progress and estimated arrival time |
| Timeline and history | Review delivery milestones and past records |
| Notifications | Delivery updates within the prototype experience |
| Profile and settings | Resident and account information |

**Tracking and delivery status shown in the prototype may use simulated data and animation.** They should not be interpreted as live telemetry from a physical robot.

## 🤖 Proposed Robot & Infrastructure

CONVY's concept incorporates:

- A **motorised retractable tray** for intended transfer at both ends of a journey.
- A **roller-shutter storage compartment** intended to protect the item during transport.
- A proposed sensor/navigation system for **predefined routes**, obstacle detection and safe stopping.
- **Compatible smart lockers** and **residential collection compartments** that must be engineered to align with the robot's transfer mechanism.

| Preliminary design parameter | Proposed target |
| --- | --- |
| Robot size | Approximately **600 × 500 × 750–850 mm** |
| Storage space | Approximately **450 × 350 × 250 mm** |
| Retractable tray | Approximately **350 × 300 mm** |
| Tray extension | Approximately **250–350 mm** |
| Initial payload | **3–5 kg**, subject to testing |

All specifications are preliminary design targets, **not verified performance figures**.

## 🛠️ Technology & Demonstration Materials

- **Flutter / Dart:** Resident-facing mobile application prototype.
- **Flask (Python):** Backend service developed for app integration.
- **MongoDB Atlas:** Database used in the team's backend development.
- **Blender:** Robot 3D model and concept visualisation.
- **GitHub:** Version control and project documentation.

Backend/database availability, authentication and deployment should be confirmed in the submitted build. The concept animation does not represent a functioning physical robot.

## 🎬 Prototype & Project Links

> Replace the placeholders below with your final public links **before submission**. Do not leave broken or private links in the final README.

| Resource | Link / status |
| --- | --- |
| App prototype | **[ADD PUBLIC FLUTTER WEB OR DEMO LINK]** |
| Demonstration video | **[ADD DEMO VIDEO LINK]** |
| Full proposal (PDF) | **[ADD PROPOSAL PDF LINK]** |
| Robot blueprint / Blender render | **[ADD IMAGE OR DOCUMENT LINK]** |

### Running the Flutter app locally

If this repository contains the Flutter project at its root and Flutter is already installed:

```bash
flutter pub get
flutter run -d chrome
```

If the application requires a locally running backend, database access, or environment variables, follow the repository's corresponding backend setup instructions. **Do not commit API keys, MongoDB connection strings, or `.env` secrets.**

## 🌱 Potential Impact

CONVY aims to:

- **Improve convenience:** Reduce the need for residents to collect eligible deliveries at central locations.
- **Support accessibility:** Offer an alternative for residents who have difficulty travelling to a collection point.
- **Support controlled access:** Reduce unnecessary internal trips by external delivery personnel.
- **Improve service visibility:** Provide app-based delivery requests, status information and records.

These are intended benefits, **not measured outcomes**. The team proposes future pilot measurement of collection time, delivery completion rate, manual intervention, resident satisfaction and operating cost per completed delivery.

## 💰 Preliminary Hardware Budget

| Scope | Estimated planning range |
| --- | ---: |
| One robot, including contingency | RM 3,200–8,100 |
| Basic collection/receiving infrastructure | RM 800–2,800 |
| **Total preliminary estimate** | **RM 4,000–10,900** |

The figures are early planning estimates rather than supplier quotations. They **exclude** significant items such as software development labour, advanced outdoor navigation equipment, comprehensive safety testing, certification, multi-home deployment and ongoing maintenance.

## 🗺️ Development Roadmap

| Phase | Focus |
| --- | --- |
| **1. Design & demonstration** | Drawings, component plans, Flutter prototype, Blender model and demo video |
| **2. Functional robot prototype** | Fabrication, tray and shutter control, obstacle detection, docking and transfer testing |
| **3. Controlled residential pilot** | Small-scale deployment on approved routes in gated landed housing; safety and reliability evaluation |
| **4. Commercial assessment** | Review resident demand, costs, maintenance, reliability and scalability |

## ⚠️ Limitations & Next Steps

The project requires further validation of:

- Smart locker integration, timed unlocking/relocking and secure authorisation.
- Tray alignment, parcel detection, load limits and item-transfer reliability.
- Robot navigation, obstacle avoidance, emergency stopping and manual recovery.
- Outdoor weather resistance, battery performance and route suitability.
- Gate-side compartment compatibility, security and maintenance requirements.
- Real robot-to-app communication and live tracking.

The proposed first pilot would be limited to a **controlled gated landed community** with suitable infrastructure and property-management approval. Expansion into apartments or condominiums would require additional analysis of lifts, shared corridors and building access.

## 👥 Team

Developed by a three-member university hackathon team.

KHOO XING EN
JOYCE LAI MING SAN
SIEW KAE XIN

## 📄 Disclosure

Some presentation or demonstration scenes may use **AI-generated illustrative imagery**. These scenes are storytelling visualisations, not footage of actual incidents at Sime Darby Property developments. Mechanical animations illustrate intended concepts; any AI and third-party asset use should be disclosed according to the competition's submission requirements.

---

<div align="center">

### CONVY — Bringing Convenience Closer to Home.

*Designed for smarter, more accessible residential delivery.*

</div>
