---
trigger: always_on
---

# 🧠 Workday Timer + Notes App  
## High-Level Product & Technical Design (MVP)

---

## 🎯 Objective

Build a **minimal, fast, and reliable mobile application** that helps users:

- Track their daily work duration  
- Instantly see **remaining work time**  
- Maintain **daily notes (work logs)**  
- Access **previous days’ notes and records**

The app is **personal-first**, optimized for **daily repeated usage with zero friction**.

---

## 🧩 Core Problem

Users relying on tools like Keka:

- Cannot see **remaining work hours in real-time**
- Perform **manual calculations repeatedly**
- Lack a simple way to **log daily context or notes**

---

## 💡 Solution Overview

A lightweight app that:

- Starts tracking when user checks in  
- Continuously calculates:
  - elapsed time  
  - remaining time  
  - expected logout time  
- Allows **quick note-taking throughout the day**  
- Stores **daily history of time + notes**

---

## 👤 Target User (Initial)

- Personal use (primary)  
- Developers / corporate employees  
- Anyone working fixed daily hours (8–10h)

---

## 🚀 Core Features (MVP)

### 1️⃣ Workday Timer
- Manual **Check-In**
- Real-time tracking
- Manual or auto **Check-Out (optional)**

---

### 2️⃣ Time Insights (Real-time)
- ⏱️ Worked Time  
- ⌛ Remaining Time  
- 🎯 Target Hours (configurable)  
- 🕓 Expected Logout Time  

---

### 3️⃣ Daily Notes (Work Log)
- Add **multiple notes per day**
- Each note:
  - text  
  - timestamp  
- Lightweight + fast entry

---

### 4️⃣ Historical View
- View previous days:
  - check-in / check-out  
  - total worked hours  
  - notes  

---

### 5️⃣ Settings
- Set daily target hours  
- Reset current day  
- (Optional) reminders

---

## 🧠 Key UX Principles

- ⚡ **Glanceable in < 2 seconds**
- 🧘 Minimal cognitive load  
- 📱 Single primary screen focus  
- ✍️ Fast note entry (no friction)  
- 🧩 Notes are secondary, time is primary  

---

## 🏗️ System Architecture (High-Level)

### App Type:
- Offline-first mobile app  

---

### Layers:

#### 1. Presentation Layer
- UI screens (Dashboard, History, Settings)  
- Reactive updates (timer-driven)

#### 2. Domain Layer
- Time calculation logic  
- Work session management  
- Notes handling logic  

#### 3. Data Layer
- Local storage (no backend in MVP)  
- Handles persistence and retrieval  

---

## 🧱 Data Models (Conceptual)

### WorkSession
- date  
- checkInTime  
- checkOutTime (nullable)  
- targetHours  
- totalWorkedDuration  

---

### Note
- id  
- date  
- timestamp  
- content  

---

## 🔁 Core Logic Flow

### Check-In Flow:
1. User taps Check-In  
2. Store timestamp  
3. Start timer  

---

### Timer Update:
- Runs every second/minute  
- Calculates:
  - elapsed time  
  - remaining time = target - elapsed  
  - expected logout = check-in + target  

---

### Check-Out Flow:
1. User taps Check-Out  
2. Store timestamp  
3. Stop timer  
4. Save session  

---

### Notes Flow:
1. User adds note  
2. Attach to current date  
3. Save instantly  
4. Display in list  

---

### History Flow:
1. User selects date  
2. Fetch session + notes  
3. Display summary  

---

## 💾 Storage Strategy

### MVP:
- Local storage (SharedPreferences / lightweight DB)

### Structure:
- Sessions stored per date  
- Notes mapped to date  

---

## ⚙️ Edge Cases

- User forgets to check out  
  → Auto-calculate until current time  

- App closed/killed  
  → Restore timer using stored check-in  

- Day rollover (midnight)  
  → Close previous session or carry logic  

---

## 🔔 Optional Enhancements (Post-MVP)

- Logout reminder notification  
- Break tracking  
- Weekly summary  
- Export logs  
- Tag-based notes  

---

## 🚫 Non-Goals (MVP Scope Control)

- No analytics dashboard  
- No team features  
- No over-engineered UI  

---

## 🧪 Success Criteria

- User opens app and understands status instantly  
- Used daily without friction  
- Eliminates manual time calculation  
- Notes are actually used (not ignored)  

---

## 🔮 Future Potential

- Expand to team usage  
- Integrate with HR tools  
- Smart insights (patterns, fatigue tracking)  
- Cross-device sync  

---

## 🏁 Summary

This app is a **focused, minimal productivity tool** that combines:

- ⏱️ Time awareness  
- 🧠 Daily memory (notes)  

Built for **speed, clarity, and daily habit formation** — not feature bloat.