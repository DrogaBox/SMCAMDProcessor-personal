#!/usr/bin/env python3
"""
Phase 2: View decomposition (corrected)
Extract sections in REVERSE order (highest line numbers first) to avoid line number shifts.
Reads each file once, processes all extractions from memory, writes results.
"""

import os, sys, subprocess

PROJECT = "/Users/droga/Desktop/SMCAMDProcessor"
APP_DIR = os.path.join(PROJECT, "AMD Power Gadget")
VIEWS_DIR = os.path.join(APP_DIR, "Views")

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def read_lines(filepath):
    with open(filepath, 'r') as f:
        return f.readlines()

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"  Created: {os.path.relpath(path, APP_DIR)}")

def extract_section(lines, start, end):
    """Extract lines start..end (0-indexed) from lines list."""
    return ''.join(lines[start:end])

def wrap_imports(imports, body):
    header = "//\n// Auto-extracted during Phase 2 restructure\n//\n\n"
    return header + '\n'.join(imports) + '\n\n' + body

# Ensure view subdirectories exist
for d in ['Dashboard', 'Widgets', 'Charts', 'Settings', 'Popover', 'Shared']:
    ensure_dir(os.path.join(VIEWS_DIR, d))

# All extractions defined as (src_file, dest_file, start_line_0idx, end_line_0idx, imports)
# Line numbers are 0-indexed: start is first line of extraction, end is one past the last line
extractions = {
    "MainDashboardView.swift": [
        ("Views/Dashboard/DashboardHistory.swift", 915, 1142, ["import Foundation", "import SwiftUI", "import Combine"]),
        ("Views/Dashboard/FanCurveEditor.swift", 1142, 1376, ["import SwiftUI"]),
        ("Views/Shared/BlockWindowDragView.swift", 1376, 1391, ["import SwiftUI"]),
        ("Views/Dashboard/DashboardSparklines.swift", 821, 910, ["import SwiftUI"]),  # SparklineShape + MiniSparkline
        ("Views/Dashboard/DashboardSparklines.swift", 1391, 1454, ["import SwiftUI"]),  # Appends Sparkline
        ("Views/Shared/LinearProgressBar.swift", 781, 820, ["import SwiftUI"]),
        ("Views/Shared/InfoRow.swift", 356, 368, ["import SwiftUI"]),
        ("Views/Dashboard/DashboardCPPC.swift", 605, 686, ["import SwiftUI"]),
        ("Views/Popover/PopoverCoreGridView.swift", 686, 780, ["import SwiftUI"]),
        ("Views/Shared/VisualEffects.swift", 1454, 1546, ["import SwiftUI"]),  # HUDBackdrop + Theme + Panel + View ext
        ("Views/Dashboard/DashboardCards.swift", 455, 507, ["import SwiftUI"]),  # StatCardsHeaderRow + CPUProfileBadgeView
        ("Views/Dashboard/DashboardCards.swift", 1547, 1636, ["import SwiftUI"]),  # MemoryCard
        ("Views/Dashboard/DashboardSidebar.swift", 201, 355, ["import SwiftUI"]),
        ("Views/Dashboard/DashboardCharts.swift", 507, 604, ["import SwiftUI"]),
    ],
    "DesktopWidgetExtensions.swift": [
        ("Views/Widgets/DesktopWidgetManager.swift", 69, 412, ["import Cocoa", "import SwiftUI", "import Combine"]),
        ("Views/Widgets/DesktopWidgetWindow.swift", 1241, 1266, ["import Cocoa", "import SwiftUI"]),
    ],
    "ChartDetailViews.swift": [
        ("Views/Charts/OriginalLineChartCard.swift", 10, 235, ["import SwiftUI", "import Charts"]),
        ("Views/Charts/SimpleLineChart.swift", 235, 320, ["import SwiftUI", "import Charts"]),
        ("Views/Charts/PowerToolBarChart.swift", 321, 382, ["import SwiftUI", "import Charts"]),
        ("Views/Charts/NetworkLineChartCard.swift", 383, 674, ["import SwiftUI", "import Charts"]),
        ("Views/Charts/CoreGridCard.swift", 675, 901, ["import SwiftUI", "import Charts"]),
        ("Views/Charts/TelemetryContentView.swift", 907, 1101, ["import SwiftUI", "import Charts"]),
    ],
    "AdvancedViews.swift": [
        ("Views/Settings/PStateViews.swift", 230, 572, ["import SwiftUI", "import Charts"]),
        ("Views/Settings/SettingsFields.swift", 573, 641, ["import SwiftUI"]),
        ("Views/Settings/MenuBarConfigView.swift", 641, 1050, ["import SwiftUI"]),
    ],
    "PopoverViews.swift": [
        ("Views/Popover/PopoverProfilesView.swift", 41, 200, ["import SwiftUI"]),
        ("Views/Popover/PopoverSettingsView.swift", 200, 393, ["import SwiftUI"]),
        ("Views/Popover/MenuBarPopoverView.swift", 394, 1028, ["import SwiftUI"]),
    ],
}

# Process each source file
for src_filename in ["MainDashboardView.swift", "DesktopWidgetExtensions.swift", "ChartDetailViews.swift", "AdvancedViews.swift", "PopoverViews.swift"]:
    src_path = os.path.join(APP_DIR, src_filename)
    lines = read_lines(src_path)
    total_lines = len(lines)
    print(f"\n=== {src_filename} ({total_lines} lines) ===")
    
    src_extractions = extractions[src_filename]
    
    # Group by destination file for multi-section appends
    dest_contents = {}
    
    # Process in reverse order of start line (highest first) to avoid line number shifts
    for dest_relpath, start_0, end_0, imports in sorted(src_extractions, key=lambda x: -x[1]):
        body = extract_section(lines, start_0, end_0)
        
        if dest_relpath not in dest_contents:
            dest_contents[dest_relpath] = ("", imports)
        
        # Prepend to existing content (since we're going in reverse order)
        existing, old_imports = dest_contents[dest_relpath]
        if existing:
            dest_contents[dest_relpath] = (body + existing, imports)
        else:
            dest_contents[dest_relpath] = (body, imports)
        
        print(f"  Extracted lines {start_0+1}-{end_0} -> {dest_relpath}")
    
    # Write all extracted files
    for dest_relpath, (content, imports) in dest_contents.items():
        dest_path = os.path.join(VIEWS_DIR, dest_relpath)
        write_file(dest_path, wrap_imports(imports, content))
    
    # Remove extracted sections from original (in reverse order)
    for dest_relpath, start_0, end_0, imports in sorted(src_extractions, key=lambda x: -x[1]):
        # Remove lines start_0..end_0 from lines list
        del lines[start_0:end_0]
    
    # Write modified original
    with open(src_path, 'w') as f:
        f.writelines(lines)
    print(f"  Original reduced to {len(lines)} lines (-{total_lines - len(lines)})")
    print(f"  Wrote: {src_filename}")

# ============================================================
# Summary
# ============================================================
print("\n" + "="*60)
print("PHASE 2 EXTRACTION COMPLETE")
print("="*60)
print(f"\nNew files in AMD Power Gadget/Views/:")
for root, dirs, files in os.walk(VIEWS_DIR):
    for f in files:
        if f.endswith('.swift'):
            path = os.path.join(root, f)
            size = os.path.getsize(path)
            wc = len(read_lines(path))
            print(f"  {os.path.relpath(path, APP_DIR)} ({wc} lines, {size}B)")

total_new = sum(1 for root, dirs, files in os.walk(VIEWS_DIR) for f in files if f.endswith('.swift'))
print(f"\nTotal new files: {total_new}")
