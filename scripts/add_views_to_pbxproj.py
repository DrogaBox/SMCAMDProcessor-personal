#!/usr/bin/env python3
"""Add Views/ subdirectory with all extracted files to pbxproj."""

import plistlib, uuid, os, subprocess, json, sys

PROJECT = "/Users/droga/Desktop/SMCAMDProcessor"
PBXPROJ = os.path.join(PROJECT, "SMCAMDProcessor.xcodeproj/project.pbxproj")

# Convert to JSON
subprocess.run(["plutil", "-convert", "json", PBXPROJ], check=True)

with open(PBXPROJ, 'r') as f:
    proj = json.load(f)

objects = proj.get("objects", {})

# Find AMD Power Gadget group and main target
main_group = None
main_target = None
sources_phase = None

for oid, obj in objects.items():
    if not isinstance(obj, dict):
        continue
    # Find main group
    if obj.get("path") == "AMD Power Gadget" and obj.get("isa") == "PBXGroup":
        main_group = oid
    # Find main target
    if obj.get("name") == "AMD Power Gadget" and obj.get("isa") == "PBXNativeTarget":
        main_target = oid

# Find Sources phase for AMD Power Gadget target
if main_target:
    target_obj = objects.get(main_target, {})
    for bid in target_obj.get("buildPhases", []):
        phase = objects.get(bid, {})
        if phase.get("isa") == "PBXSourcesBuildPhase":
            sources_phase = bid
            break

print(f"Main group: {main_group}")
print(f"Main target: {main_target}")
print(f"Sources phase: {sources_phase}")

if not main_group:
    print("ERROR: Could not find AMD Power Gadget group")
    exit(1)

def generate_id():
    return uuid.uuid4().hex.upper()[:24]

# Create Views group
views_group_id = generate_id()
views_group = {
    "isa": "PBXGroup",
    "children": [],
    "name": "Views",
    "sourceTree": "<group>"
}
objects[views_group_id] = views_group

# Add Views group to AMD Power Gadget group
main_group_obj = objects[main_group]
main_group_obj["children"].append(views_group_id)

# Subdirectories to create
subdirs = ["Charts", "Dashboard", "Popover", "Settings", "Shared", "Widgets"]
subdir_ids = {}

for subdir in subdirs:
    gid = generate_id()
    subdir_ids[subdir] = gid
    subdir_group = {
        "isa": "PBXGroup",
        "children": [],
        "name": subdir,
        "sourceTree": "<group>"
    }
    objects[gid] = subdir_group
    views_group["children"].append(gid)

# Files to add (subdir -> [filename])
files_to_add = {
    "Charts": ["CoreGridCard.swift", "NetworkLineChartCard.swift", "OriginalLineChartCard.swift",
               "PowerToolBarChart.swift", "SimpleLineChart.swift", "TelemetryContentView.swift"],
    "Dashboard": ["DashboardCPPC.swift", "DashboardCards.swift", "DashboardCharts.swift",
                  "DashboardHistory.swift", "DashboardSidebar.swift", "DashboardSparklines.swift",
                  "FanCurveEditor.swift"],
    "Popover": ["MenuBarPopoverView.swift", "PopoverCoreGridView.swift", "PopoverProfilesView.swift",
                "PopoverSettingsView.swift"],
    "Settings": ["MenuBarConfigView.swift", "PStateViews.swift", "SettingsFields.swift"],
    "Shared": ["BlockWindowDragView.swift", "InfoRow.swift", "LinearProgressBar.swift", "VisualEffects.swift"],
    "Widgets": ["DesktopWidgetManager.swift", "DesktopWidgetWindow.swift"]
}

for subdir, filenames in files_to_add.items():
    group_id = subdir_ids[subdir]
    group_obj = objects[group_id]
    
    for filename in filenames:
        file_ref_id = generate_id()
        file_ref = {
            "isa": "PBXFileReference",
            "lastKnownFileType": "sourcecode.swift",
            "path": filename,
            "sourceTree": "<group>"
        }
        objects[file_ref_id] = file_ref
        group_obj["children"].append(file_ref_id)
        
        if sources_phase:
            build_file_id = generate_id()
            build_file = {
                "isa": "PBXBuildFile",
                "fileRef": file_ref_id
            }
            objects[build_file_id] = build_file
            
            phase_obj = objects[sources_phase]
            phase_obj["files"].append(build_file_id)

# Write back
proj["objects"] = objects
with open(PBXPROJ, 'w') as f:
    json.dump(proj, f, indent=2)

# Convert back to plist/ASCII plist
subprocess.run(["plutil", "-convert", "xml1", PBXPROJ], check=True)

print(f"\nAdded Views group with {sum(len(v) for v in files_to_add.values())} files to pbxproj")
