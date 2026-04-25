---
trigger: manual
---

# 📏 Development Agent Rules

## 🎯 Purpose
Define strict implementation rules to ensure reliability, consistency, and scalability of the application.

---

## 🧱 Core Rules

### 1. Separation of Concerns
- UI must not contain business logic
- Business logic must not depend on UI
- Data handling must be isolated from presentation

---

### 2. Single Source of Truth
- Maintain one authoritative state for each feature
- Avoid duplicated or conflicting state
- Ensure consistent updates across the app

---

### 3. Deterministic Behavior
- All calculations must be predictable and reproducible
- Avoid hidden side effects
- Ensure consistent outputs for same inputs

---

### 4. Timer Accuracy Rule
- Never rely solely on continuous timers
- Always compute time using stored timestamps
- Recalculate on app resume or rebuild

---

### 5. Persistence First
- Critical data must be stored immediately
- Do not rely on in-memory state for important data
- Ensure recovery after app restart

---

### 6. Fail-Safe Defaults
- Handle missing or null data gracefully
- Provide safe fallback values
- Prevent crashes due to unexpected states

---

### 7. Minimal Rebuilds
- Avoid unnecessary UI updates
- Update only affected components
- Optimize reactive listeners

---

### 8. Feature Isolation Rule
- Each feature must function independently
- Changes in one feature must not break others
- Avoid shared mutable logic across features

---

### 9. No Premature Optimization
- Optimize only when necessary
- Focus on correctness first
- Avoid complex solutions for simple problems

---

### 10. Consistent Data Flow
- Follow unidirectional data flow
- Ensure clear flow from input → processing → output
- Avoid circular dependencies

### 11. Controllers architecture
- Common loader views must be kept in the base controller
- All commons flags and data variables of controllers must be in the base controller
- All Controllers must extends to Base Controller

---

## ⚠️ Strict Prohibitions

- ❌ Do not store critical state only in memory  
- ❌ Do not depend on UI lifecycle for logic correctness  
- ❌ Do not hardcode time calculations  
- ❌ Do not create global mutable state without control  
- ❌ Do not tightly couple features  

---

## 🔁 Refinement Rules

- Refactor when complexity increases
- Simplify logic when possible
- Remove redundant code paths
- Ensure readability over cleverness

---

## 🧪 Validation Checklist

Before finalizing implementation:

- Is the logic independent of UI?
- Is data safely persisted?
- Can the app recover from restart?
- Are timers accurate after resume?
- Are edge cases handled?

If any answer is “no”, fix before proceeding.

---

## 🏁 Outcome

The Development Agent must produce systems that are:

- Reliable  
- Predictable  
- Recoverable  

and capable of handling real-world usage without failure.