# Post-Refactor Cleanup Implementation Plan

**Goal:** Clean up 3 residual issues from the Phase 1-3 restructure

**Architecture:** 3 independent sub-projects executed sequentially, each followed by a build. Task 1 is trivial (delete 2 files, move 1 struct). Task 2 is a file move within existing Telemetry/ infrastructure. Task 3 follows the same extraction pattern as Phase 2.

**Tech Stack:** SwiftUI, Xcode, pbxproj

## Global Constraints

- Build after each sub-project
- Zero behavior change — extraction only
- No AI/Codebuff references in any new or modified file

---

### Sub-project 1: Remove shell files

**Files:**
- Delete: `AMD Power Gadget/ChartDetailViews.swift`
- Create: `AMD Power Gadget/Views/Popover/PopoverTabButton.swift` (move PopoverTabButton here)
- Delete: `AMD Power Gadget/PopoverViews.swift`
- Modify: `SMCAMDProcessor.xcodeproj/project.pbxproj` (remove 2 file refs, add 1)

- [ ] **Step 1: Create `PopoverTabButton.swift`** with PopoverTabButton content
- [ ] **Step 2: Delete `ChartDetailViews.swift`** and `PopoverViews.swift` from disk
- [ ] **Step 3: Update pbxproj** — remove ChartDetailViews, PopoverViews; add PopoverTabButton
- [ ] **Step 4: Build** to verify

### Sub-project 2: Move HistoryManager to Telemetry/

**Files:**
- Create: `AMD Power Gadget/Telemetry/HistoryStorage.swift` (HistoryDataPoint + HistoryManager)
- Delete: `AMD Power Gadget/Views/Dashboard/DashboardHistory.swift`
- Modify: `SMCAMDProcessor.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create `Telemetry/HistoryStorage.swift`** with HistoryDataPoint + HistoryManager
- [ ] **Step 2: Delete `Views/Dashboard/DashboardHistory.swift`**
- [ ] **Step 3: Update pbxproj**
- [ ] **Step 4: Build** to verify

### Sub-project 3: Decompose ThemeViews.swift

**Files:**
- Create: `AMD Power Gadget/Views/Themes/ThemeStudio.swift`
- Create: `AMD Power Gadget/Views/Themes/ThemePresets.swift`
- Create: `AMD Power Gadget/Views/Themes/ChartStylesViews.swift`
- Create: `AMD Power Gadget/Views/Themes/ThemePickers.swift`
- Modify: `AMD Power Gadget/ThemeViews.swift` (reduce from 951 → ~150 lines)
- Modify: `SMCAMDProcessor.xcodeproj/project.pbxproj`

- [ ] **Step 1: Read ThemeViews.swift** and map extraction ranges
- [ ] **Step 2: Extract sections** in reverse order
- [ ] **Step 3: Update pbxproj** with 4 new files
- [ ] **Step 4: Build** to verify
