# Interactive Charts — Design Document

**Date:** 2026-07-16
**Version:** v3.31.0 (proposed)
**Status:** Draft

## Overview

Add interactivity to the existing Swift Charts-based charts in AMD Power Gadget: tooltips on hover, zoom via scroll wheel/magnification, and range selection via drag.

## Scope (Subsystem A only)

Affects 3 chart components:
- `OriginalLineChartCard` — Dashboard (Freq/Temp/Power)
- `SimpleLineChart` — Telemetry (CPU/GPU/RAM/Disk/Net/Fan)
- `HistoryCard` — Analysis (CPU Load, Thermals, RAM, GPU, Power, Freq)

Does **not** affect:
- `Sparkline` / `MiniSparkline` — custom Path rendering (future work)
- Network chart (`NetworkLineChartCard`) — bidirectional charts (future work)

## Components

### ChartInteractionState

```swift
@Observable
class ChartInteractionState {
    var isPaused: Bool = false
    var pausedSnapshot: [TelemetryPoint] = []
    var hoveredIndex: Int? = nil
    var zoomRange: ClosedRange<Int>? = nil
    var isDragging: Bool = false
    var dragStartIndex: Int? = nil
    var dragEndIndex: Int? = nil

    var fullRange: ClosedRange<Int>
    var visibleRange: ClosedRange<Int> { zoomRange ?? fullRange }
}
```

### ChartTooltipView

A floating tooltip overlay that shows:
- 1 or 2 metric lines (dynamically based on chart config)
- Timestamp
- Same visual style as the existing Tahoe design (glass background, rounded corners)

### ChartHoverGesture

A `ViewModifier` that attaches a `DragGesture(minimumDistance: 0)` to the chart overlay, converts touch position to data index via `ChartProxy`, and updates `ChartInteractionState.hoveredIndex`.

## Integration Points

| Chart | Component | File | lines1 |
|-------|-----------|------|--------|
| Frequency | `OriginalLineChartCard` | `ChartDetailViews.swift` | 2 (avg, max) |
| Temperature | `OriginalLineChartCard` | `ChartDetailViews.swift` | 1 |
| Power | `OriginalLineChartCard` | `ChartDetailViews.swift` | 1 |
| Telemetry charts | `SimpleLineChart` | `ChartDetailViews.swift` | 1 |
| Analysis charts | `HistoryCard` | `AnalysisViews.swift` | 1 |

## Implementation Order

1. `ChartInteractionState` in `ChartComponents.swift`
2. `ChartTooltipView` in `ChartComponents.swift`
3. `ChartHoverGesture` modifier in `ChartComponents.swift`
4. Integrate into `OriginalLineChartCard` (Freq/Temp/Power — 3 charts at once)
5. Integrate into `SimpleLineChart` (6+ telemetry charts)
6. Integrate into `HistoryCard` in `AnalysisViews.swift`
7. Build & verify
8. Code review

## Future (Phase 2)

- Zoom via MagnificationGesture
- Range selection via DragGesture
- Pause/Resume button
- Custom Path chart interactivity (Sparkline, etc.)
