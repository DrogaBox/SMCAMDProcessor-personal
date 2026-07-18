# Post-Refactor Cleanup Plan

**Date:** 2026-07-17
**Status:** Design — pending implementation

---

## Overview

Clean up three residual issues from the Phase 1-3 restructure:
1. Remove shell files left empty by the extraction
2. Move HistoryManager from Views/ to its proper place
3. Decompose ThemeViews.swift (951 lines)

---

## Sub-project 1: Remove shell files

**Files to eliminate:**
| File | Lines | Contents |
|------|-------|----------|
| `ChartDetailViews.swift` | 19 | Imports + MARK comments only (all structs extracted) |
| `PopoverViews.swift` | 42 | `PopoverTabButton` struct only (move to `Views/Popover/`) |

**Plan:** Delete `ChartDetailViews.swift` from disk and pbxproj. Move `PopoverTabButton` to a new `Views/Popover/PopoverTabButton.swift`, delete `PopoverViews.swift`. Update pbxproj references.

**Risk:** Very low — the extracted structs are in their own files with proper imports.

---

## Sub-project 2: Move HistoryManager

**Current location:** `Views/Dashboard/DashboardHistory.swift`
**Problem:** `HistoryManager` is a `@MainActor class` (data/state singleton, not a view). It doesn't belong in `Views/`.
**Target location:** `Telemetry/HistoryStorage.swift` — it lives alongside the rest of the Telemetry infrastructure.

**Plan:** Move `HistoryDataPoint` struct + `HistoryManager` class from `Views/Dashboard/DashboardHistory.swift` to `Telemetry/HistoryStorage.swift`. Update the pbxproj file references.

**Risk:** Low — `HistoryManager` and `HistoryDataPoint` are `internal` and accessed from multiple files. Since all files are in the same module, the move is transparent to callers.

---

## Sub-project 3: Decompose ThemeViews.swift

**Current state:** 951 lines, 14 types (themes, chart styles, color pickers, etc.)

**Extraction targets:**
| New file | Types extracted | Lines |
|----------|----------------|-------|
| `Views/Themes/ThemeStudio.swift` | CustomThemeStudio, ColorTokenEditorSlot, CardOpacityEditorCard | ~250 |
| `Views/Themes/ThemePresets.swift` | ThemePresetPack, OptimizedThemeSelectorGrid, CompactThemeButton, CompactCardOpacityEditor | ~200 |
| `Views/Themes/ChartStylesViews.swift` | ChartStylesContentView, ChartStyleSelectorGrid, ChartStyleButton, AppChartStyle | ~200 |
| `Views/Themes/ThemePickers.swift` | Color extension, CheckerboardBackground, SectionWithIcon, LanguagePickerCard | ~150 |

**Remaining in ThemeViews.swift:** ~150 lines (ThemesContentView coordinator + helpers)

**Plan:** Same extraction pattern as Phase 2 — extract sections in reverse order, write new files, update pbxproj, build.

**Risk:** Low-medium — Theme views are mostly independent SwiftUI structs. The `Color` extension needs proper placement.
