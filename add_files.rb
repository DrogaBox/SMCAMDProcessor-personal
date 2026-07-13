require 'xcodeproj'

project_path = 'SMCAMDProcessor.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the AMD Power Gadget target
target = project.targets.find { |t| t.name == 'AMD Power Gadget' }

# Find the AMD Power Gadget group
group = project.main_group.groups.find { |g| g.path == 'AMD Power Gadget' }

abort "Target not found" unless target
abort "Group not found" unless group

# Files to add
files = [
  'AppTheme.swift',
  'VisualEffectComponents.swift',
  'DashboardTab.swift'
]

files.each do |file|
  # Check if file already exists in project
  existing = group.files.find { |f| File.basename(f.path || '') == file }
  if existing
    puts "Already exists: #{file}"
    next
  end
  
  # Add file reference to group
  file_ref = group.new_reference(file)
  
  # Add file to target's sources build phase
  target.source_build_phase.add_file_reference(file_ref)
  
  puts "Added #{file}"
end

project.save
puts "Project saved successfully"
