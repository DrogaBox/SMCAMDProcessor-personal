#!/usr/bin/env python3
"""
Phase 1b: Add new Telemetry files to pbxproj via JSON round-trip.
Fix imports in extracted files.
"""
import json, os, subprocess, random, string

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBXPROJ = os.path.join(BASE, "SMCAMDProcessor.xcodeproj", "project.pbxproj")
JSON_PATH = "/tmp/project.json"

# Fix imports
caff_path = os.path.join(BASE, "AMD Power Gadget", "Telemetry", "CaffeinateManager.swift")
if os.path.exists(caff_path):
    with open(caff_path, 'r') as f:
        c = f.read()
    if "import Foundation" not in c:
        c = c.replace("import IOKit", "import Foundation\nimport IOKit")
        with open(caff_path, 'w') as f:
            f.write(c)
        print("Fixed CaffeinateManager.swift imports")

# Convert pbxproj to JSON
subprocess.run(["plutil", "-convert", "json", "-o", JSON_PATH, PBXPROJ], check=True)

with open(JSON_PATH, 'r') as f:
    data = json.load(f)
objects = data["objects"]

def gen_uuid():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=24))

new_files = [
    ("Telemetry/TelemetryDataTypes.swift", "sourcecode.swift"),
    ("Telemetry/TelemetryPerformance.swift", "sourcecode.swift"),
    ("Telemetry/TelemetryStorage.swift", "sourcecode.swift"),
    ("Telemetry/CSVLogger.swift", "sourcecode.swift"),
    ("Telemetry/CaffeinateManager.swift", "sourcecode.swift"),
]

file_refs = {}
build_pairs = []

for path, filetype in new_files:
    fr = gen_uuid()
    br = gen_uuid()
    
    objects[fr] = {"isa": "PBXFileReference", "lastKnownFileType": filetype, "path": path, "sourceTree": "<group>"}
    objects[br] = {"isa": "PBXBuildFile", "fileRef": fr}
    
    file_refs[path] = fr
    build_pairs.append((br, fr))

# Find AMD Power Gadget group
amd_group = None
for uid, obj in objects.items():
    if isinstance(obj, dict) and obj.get("isa") == "PBXGroup" and obj.get("path") == "AMD Power Gadget":
        amd_group = uid
        break

if amd_group:
    tg = gen_uuid()
    objects[tg] = {"isa": "PBXGroup", "children": [file_refs[p] for p, _ in new_files], "name": "Telemetry", "sourceTree": "<group>"}
    children = objects[amd_group].get("children", [])
    children.append(tg)
    objects[amd_group]["children"] = children
    print(f"Added Telemetry group ({tg}) to AMD Power Gadget")
else:
    print("ERROR: AMD Power Gadget group not found!")
    exit(1)

# Add to Sources build phase
sp = "B56162C02400EF770006A7D8"
if sp in objects:
    phase = objects[sp]
    if phase.get("isa") == "PBXSourcesBuildPhase":
        files = phase.get("files", [])
        for br, _ in build_pairs:
            files.append(br)
        phase["files"] = files
        print(f"Added {len(build_pairs)} files to Sources phase")
    else:
        print(f"ERROR: {sp} is not PBXSourcesBuildPhase")
        exit(1)
else:
    print(f"ERROR: Sources phase {sp} not found")
    exit(1)

# Write JSON back and convert to XML plist
with open(JSON_PATH, 'w') as f:
    json.dump(data, f, indent='\t')
subprocess.run(["plutil", "-convert", "xml1", "-o", PBXPROJ, JSON_PATH], check=True)
print("pbxproj updated successfully!")
