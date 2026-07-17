#!/usr/bin/env python3
"""
Phase 1: Extract sections from TelemetryModel.swift into focused files under Telemetry/.
Updates pbxproj to include the new files.
"""
import os, re, sys, subprocess, random

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TM_PATH = os.path.join(BASE, "AMD Power Gadget", "TelemetryModel.swift")
TELEMETRY_DIR = os.path.join(BASE, "AMD Power Gadget", "Telemetry")
PBXPROJ_PATH = os.path.join(BASE, "SMCAMDProcessor.xcodeproj", "project.pbxproj")

def gen_uuid():
    """Generate a 24-char hex UUID similar to Xcode's."""
    return ''.join(random.choice('0123456789ABCDEF') for _ in range(24))

# Read TelemetryModel.swift
with open(TM_PATH, 'r') as f:
    lines = f.readlines()

# Define extractions: (start_line_1based, end_line_1based, output_file, remove_from_source)
# Line numbers are 1-based as shown by grep -n
extractions = [
    # TelemetryPerformance.swift: ThresholdPublished + ViewVisibilityModifier + CalculationCache + PerformanceMonitor + DiagnosticsHelper
    (23, 165, "TelemetryPerformance.swift", True),
    # TelemetryDataTypes.swift: Data structures (CoreSnapshot, RankedPhysicalCore, PStateRow, TelemetryPoint, SystemInfo)
    (166, 290, "TelemetryDataTypes.swift", True),
    # ChartSizeConfig
    (291, 316, "TelemetryStorage.swift", False), # Will be added to TelemetryStorage
    # ProcessInfoRow
    (317, 323, "TelemetryDataTypes.swift", True),
    # Lines to remove that are now in TelemetryStorage
    # Will also add SimpleDeque and MetricHistory from near the end
]

# Read all lines for each extraction
os.makedirs(TELEMETRY_DIR, exist_ok=True)

# Collect content for each output file
file_contents = {}

def add_content(filename, content):
    if filename not in file_contents:
        file_contents[filename] = []
    file_contents[filename].append(content)

# Process each extraction
for start, end, outfile, _ in extractions:
    content = ''.join(lines[start-1:end])  # Convert to 0-based
    add_content(outfile, content)

# Read the end of the file for SimpleDeque, MetricHistory (lines ~2770-2828) and CaffeinateManager (2829-end)
# CSVLogger: 2725-2769
csv_logger_content = ''.join(lines[2724:2769])  # 0-based
add_content("CSVLogger.swift", csv_logger_content)

# SimpleDeque + MetricHistory: 2770-2828
storage_extra = ''.join(lines[2769:2828])  # 0-based
add_content("TelemetryStorage.swift", storage_extra)

# ChartSizeConfig was already added to TelemetryStorage (as collected above)
# Let me re-add ChartSizeConfig content to TelemetryStorage
chartsize_content = ''.join(lines[290:316])  # 0-based of lines 291-316
# Check if TelemetryStorage already has content (from storage_extra)
if "TelemetryStorage.swift" in file_contents:
    # Remove the placeholder chart line if it was added via extractions
    pass

# Actually let me restructure: TelemetryStorage gets ChartSizeConfig + SimpleDeque + MetricHistory
# ChartSizeConfig was extraction 291-316 -> TelemetryStorage.swift, remove=True

# CaffeinateManager: 2829 to end
caff_content = ''.join(lines[2828:])
add_content("CaffeinateManager.swift", caff_content)

# Write files
for filename, contents in file_contents.items():
    filepath = os.path.join(TELEMETRY_DIR, filename)
    combined = '\n'.join(contents)
    # Add proper header
    header = f"""//
//  {filename}
//  AMD Power Gadget
//
//  Auto-generated during Phase 1 codebase restructure (2026-07-17).
//

import Foundation
import SwiftUI
import Combine

"""
    # For DataTypes and simple types, keep minimal imports
    if filename == "TelemetryDataTypes.swift":
        header = f"""//
//  {filename}
//  AMD Power Gadget
//

import Foundation

"""
    elif filename == "TelemetryPerformance.swift":
        header = f"""//
//  {filename}
//  AMD Power Gadget
//

import Foundation
import SwiftUI
import Combine

"""
    elif filename == "TelemetryStorage.swift":
        header = f"""//
//  {filename}
//  AMD Power Gadget
//

import Foundation

"""
    elif filename == "CSVLogger.swift":
        header = f"""//
//  {filename}
//  AMD Power Gadget
//

import Foundation

"""
    elif filename == "CaffeinateManager.swift":
        header = f"""//
//  {filename}
//  AMD Power Gadget
//

import Foundation
import IOKit

"""
    
    with open(filepath, 'w') as f:
        f.write(header + combined)
    print(f"Created {filepath}")

# Now remove extracted sections from TelemetryModel.swift
# We need to rebuild the file without the extracted lines
# Remove lines: 23-165, 166-290, 291-316, 317-323
# And lines: 2725-2769 (CSVLogger), 2770-2828 (SimpleDeque+MetricHistory), 2829-end (CaffeinateManager)

remove_ranges = [
    (23, 323),    # All performance + data types + chart config + process info
    (2725, 2888), # CSVLogger + SimpleDeque + MetricHistory + CaffeinateManager (to end)
]

# Build new content
new_lines = []
current_line = 1
for line in lines:
    in_removed = False
    for rstart, rend in remove_ranges:
        if rstart <= current_line <= rend:
            in_removed = True
            break
    if not in_removed:
        new_lines.append(line)
    current_line += 1

with open(TM_PATH, 'w') as f:
    f.writelines(new_lines)
print(f"Updated {TM_PATH} (removed ~530 lines)")

# ========== Patch pbxproj ==========
# Generate UUIDs for new files
file_uuids = {}
for fname in ["TelemetryDataTypes.swift", "TelemetryPerformance.swift", 
              "TelemetryStorage.swift", "CSVLogger.swift", "CaffeinateManager.swift"]:
    file_uuids[fname] = {
        'fileRef': gen_uuid(),
        'buildFile': gen_uuid(),
    }

with open(PBXPROJ_PATH, 'r') as f:
    pbxproj = f.read()

# 1. Add PBXBuildFile entries (before /* End PBXBuildFile section */)
build_entries = ""
for fname, uuids in file_uuids.items():
    # Path relative to AMD Power Gadget group
    relpath = f"Telemetry/{fname}"
    build_entries += f"\t\t{uuids['buildFile']} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {uuids['fileRef']} /* {fname} */; }};\n"

pbxproj = pbxproj.replace("/* End PBXBuildFile section */", build_entries + "/* End PBXBuildFile section */")

# 2. Add PBXFileReference entries (before /* End PBXFileReference section */)
ref_entries = ""
for fname, uuids in file_uuids.items():
    ref_entries += f"\t\t{uuids['fileRef']} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = \"<group>\"; }};\n"

pbxproj = pbxproj.replace("/* End PBXFileReference section */", ref_entries + "/* End PBXFileReference section */")

# 3. Add to AMD Power Gadget PBXGroup (between last file and closing paren)
# Find the AMD Power Gadget group and add the Telemetry group reference
# The group ends with ChartHelpers.swift then );
# We need to add the Telemetry subgroup before the closing )
group_pattern = r'(B5CH000100000001 /\* ChartHelpers\.swift \*/;)'
replacement = r'\1\n\t\t\t\tAABB00110000TELEMETRY /* Telemetry */,'
# But we need a group UUID for Telemetry
telemetry_group_uuid = gen_uuid()
pbxproj = re.sub(
    r'(B5CH000100000001 /\* ChartHelpers\.swift \*/;)',
    f'\\1\n\t\t\t\t{telemetry_group_uuid} /* Telemetry */,',
    pbxproj
)

# 4. Add the Telemetry PBXGroup definition before the closing PBXGroup section
# The last group is AMDPowerGadgetTests
# Add Telemetry group right after AMD Power Gadget group
# Find the PBXGroup section end
# We need to add:
# TELEMETRY_GROUP_UUID /* Telemetry */ = {
#     isa = PBXGroup;
#     children = ( ... files ... );
#     path = Telemetry;
#     sourceTree = "<group>";
# };

group_children = ""
for fname, uuids in file_uuids.items():
    group_children += f"\t\t\t\t{uuids['fileRef']} /* {fname} */,\n"

telemetry_group_def = f"""
\t\t{telemetry_group_uuid} /* Telemetry */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{group_children}\t\t\t);
\t\t\tpath = Telemetry;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

# Insert before the last PBXGroup end
last_group_end = pbxproj.rfind("/* End PBXGroup section */")
if last_group_end != -1:
    pbxproj = pbxproj[:last_group_end] + telemetry_group_def + pbxproj[last_group_end:]

# 5. Add to PBXSourcesBuildPhase for AMD Power Gadget
# Find the Sources build phase (B56162C02400EF770006A7D8) and add files before the closing )
# The AMD Power Gadget Sources phase has entries for all .swift files
# We need to find where it lists the source files

sources_entries = ""
for fname, uuids in file_uuids.items():
    sources_entries += f"\t\t\t\t{uuids['buildFile']} /* {fname} in Sources */,\n"

# Find the Sources build phase - it contains B5F46D81 (ProcessorModel.swift in Sources) 
# and similar entries. Insert before the closing of the Sources phase.
# The AMD Power Gadget Sources phase is B56162C0...
# Look for the closing of the Sources phase after the last source entry
# Pattern: find AnalysisViews.swift in Sources then add after it
sources_marker = "E32E28C693D98B149646A32B /* AnalysisViews.swift in Sources */"
if sources_marker in pbxproj:
    pbxproj = pbxproj.replace(
        sources_marker + ",", 
        sources_marker + ",\n" + sources_entries.strip()
    )

with open(PBXPROJ_PATH, 'w') as f:
    f.write(pbxproj)
print(f"Updated {PBXPROJ_PATH}")

print("\nDone. Run build to verify.")
