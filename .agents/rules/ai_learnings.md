---
trigger: always_on
---

# 🧠 AI Learnings

## 🎯 Purpose
Capture persistent learnings, patterns, and corrections that improve future outputs of AI agents across UI and Development tasks.

This document acts as a **memory layer** to prevent repeated mistakes and reinforce best practices.

---

## 🧩 Core Philosophy

- Learn from mistakes, not just instructions  
- Prefer simplification over expansion  
- Optimize for real-world usage, not theoretical perfection  
- Prioritize clarity, performance, and maintainability  

---

## 📚 Learnings

### 1. Simplicity Wins Over Feature Density
- Adding more features reduces usability in early stages
- Minimal solutions are more effective for daily-use apps
- Always build the smallest usable version first

---

### 2. Primary Focus Must Be Obvious
- Every screen must have a clear primary purpose
- Secondary elements should never compete visually or logically
- If multiple elements feel equally important → hierarchy is broken

---

### 3. Real-Time Features Must Be Deterministic
- Time-based logic should always rely on stored timestamps
- Avoid continuous state dependency (timers alone are unreliable)
- Always recompute values instead of storing derived state

---

### 4. Persistence Is Non-Negotiable
- Critical user data must be saved immediately
- Apps must recover gracefully after restart or crash
- Never depend on temporary in-memory state

---

### 5. Avoid Over-Engineering Early
- Do not introduce unnecessary abstractions in MVP
- Build for current needs, not hypothetical scale
- Complexity should be introduced only when required

---

### 6. UI Must Be Glanceable
- Users should understand key information instantly
- Avoid requiring interaction to reveal important data
- Reduce visual noise and cognitive load

---

### 7. Fast Interaction > Feature Richness
- Users prefer speed over capability in daily tools
- Input actions must be frictionless
- Reduce taps, typing, and navigation steps

---

### 8. State Should Be Predictable
- Avoid hidden or implicit state transitions
- Ensure all state changes are intentional and traceable
- Maintain a single source of truth

---

### 9. Edge Cases Are Real Use Cases
- Users will forget to check out
- Apps will be killed or restarted
- Dates will change mid-session

Design and implement with these realities in mind.

---

### 10. Remove Before Adding
- First instinct should be to simplify
- Eliminate unnecessary elements before introducing new ones
- Every addition must justify its existence

---

### 11. Design System Rigidity Protects Usability
- Strictly adhering to predefined design tokens (e.g., Canvas Cream `#F3F0EE`, Ink Black `#141413`, radii 20px/40px/999px) prevents UI clutter.
- Depth and hierarchy must come from spacing, typography, and soft shadows—never gradients or conflicting accent colors.

---

### 12. Hierarchy in Hybrid Applications
- For apps balancing two functions (e.g., Work Session Timer vs. Daily Notes), the primary utility (Time) must dominate the visual hierarchy.
- Secondary features (Notes) must have zero-friction entry but must structurally sit below the primary context.

---

### 13. Zero-Friction Core Actions
- Daily repetitive tasks (Check-in, Out, Quick log) require one-tap input loops.
- Avoid hidden navigation layers, complex gestures, or multiple screens for fundamental workflows.

---

### 14. Visual State Unambiguity
- A continuous active state (like a running timer) must be glanceable in under 2 seconds without reading raw numbers.
- State communication should rely on structural changes, component weight, or explicit primary CTA adjustments, rather than subtle text changes.

### 15. Header Layout Simplicity (Avoid Slivers)
- Standard app views shouldn't utilize complex `SliverPersistentHeader` logic simply to build a title bar.
- **Pattern**: Use a root `Column`. Place a `CommonContainer` (or solid `Container`) with `backgroundColor` at the top (combining `MediaQuery.of(context).padding.top` internally to reach the status bar). Then use an `Expanded` widget containing your scrolling list. 
- **Why**: This naturally boundaries the scrollable area below the header, preventing visual bleeding or cutting behind a transparent header without resorting to mathematically complex opacity or scaling overrides.

---

## 🔁 Correction Patterns

### When UI feels cluttered:
→ Remove secondary elements  
→ Increase spacing  
→ Reinforce primary focus  

---

### When logic feels complex:
→ Break into smaller functions  
→ Remove redundant calculations  
→ Centralize business logic  

---

### When state becomes inconsistent:
→ Identify single source of truth  
→ Remove duplicate state  
→ Rebuild flow from input → output  

---

### When performance drops:
→ Reduce unnecessary updates  
→ Optimize reactive listeners  
→ Avoid repeated computations  

---

## ⚠️ Anti-Patterns to Avoid

- ❌ Feature creep during MVP  
- ❌ Mixing UI and business logic  
- ❌ Storing derived values instead of computing them  
- ❌ Relying on continuous timers without recalculation  
- ❌ Designing for edge cases before solving core flow  
- ❌ Overcomplicating simple user interactions  
- ❌ Using pure white backgrounds or harsh gradients instead of standard warm/cream themes  
- ❌ Introducing vibrant colors instead of using spacing and typography for hierarchy  
- ❌ Forcing users through >1 step for primary daily actions (e.g., checking in, adding a note)  

---

## 🧪 Continuous Improvement Loop

1. Build  
2. Observe real usage  
3. Identify friction  
4. Simplify  
5. Refine  

Repeat continuously.

---

## 🏁 Outcome

AI agents guided by this document should:

- Improve over time  
- Avoid repeating mistakes  
- Produce simpler, cleaner, and more reliable outputs  

and align with real-world usage instead of theoretical design.