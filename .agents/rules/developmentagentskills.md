---
trigger: manual
---

# 🛠️ Development Agent Skills

## 🎯 Purpose
Define the capabilities of the Development Agent responsible for building a scalable, maintainable, and performant mobile application.

---

## 🧠 Core Skills

### 1. Architecture Design
- Implement clean and modular architecture
- Separate concerns clearly (Presentation, Domain, Data)
- Avoid tightly coupled components
- Ensure scalability from MVP to future features

---

### 2. State Management
- Manage reactive state efficiently
- Minimize unnecessary UI rebuilds
- Maintain single source of truth
- Ensure predictable state transitions

---

### 3. Time-Based Logic Handling
- Implement accurate timer systems
- Handle real-time updates efficiently
- Prevent timer drift or inconsistencies
- Support app lifecycle changes (pause, resume, kill)

---

### 4. Data Persistence
- Store and retrieve data reliably
- Ensure data integrity across sessions
- Optimize read/write operations
- Handle edge cases (missing, partial, corrupted data)

---

### 5. Business Logic Implementation
- Encapsulate logic in dedicated layers/services
- Avoid embedding logic directly in UI
- Ensure testable and reusable logic
- Maintain clarity and simplicity

---

### 6. Error Handling
- Gracefully handle runtime failures
- Prevent app crashes
- Provide fallback logic where needed
- Log errors for debugging

---

### 7. Performance Optimization
- Avoid unnecessary computations
- Optimize rendering cycles
- Use efficient data structures
- Ensure smooth UI updates for real-time features

---

### 8. Local Data Modeling
- Design clear and extensible data models
- Maintain relationships between entities (e.g., session ↔ notes)
- Ensure future extensibility without refactoring core models

---

### 9. Feature Isolation
- Build features independently (timer, notes, history)
- Avoid cross-feature dependencies
- Ensure features can evolve without breaking others

---

### 10. Code Quality & Maintainability
- Write clean, readable, and consistent code
- Use meaningful naming conventions
- Follow consistent project structure
- Keep functions small and focused

---

## ⚡ Advanced Skills

### App Lifecycle Management
- Handle background/foreground transitions
- Restore state after app kill
- Maintain timer accuracy across lifecycle changes

---

### Edge Case Handling
- Handle missing check-out scenarios
- Manage date transitions (midnight rollover)
- Prevent invalid state combinations

---

### Incremental Development
- Build MVP-first, then extend
- Avoid over-engineering early
- Ensure backward compatibility for updates

---

### Debugging & Observability
- Implement structured logging
- Enable easy debugging of time and state issues
- Track critical flows (check-in, check-out, notes)

---

## 🚫 Skill Constraints

- Do NOT mix UI and business logic
- Do NOT introduce unnecessary abstractions
- Do NOT over-engineer for future assumptions
- Do NOT compromise performance for convenience

---

## 🏁 Outcome

The Development Agent should produce:
- Stable  
- Performant  
- Maintainable  

code that supports real-time features and daily usage reliably.