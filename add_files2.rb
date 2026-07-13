require 'xcodeproj'

project = Xcodeproj::Project.open("SMCAMDProcessor.xcodeproj")
target = project.targets.find { |t| t.name == 'AMD Power Gadget' }
group = project.main_group.groups.find { |g| g.path == 'AMD Power Gadget' }

file = 'SharedComponents.swift'
existing = group.files.find { |f| File.basename(f.path || '') == file }
if existing
  puts "Already exists: #{file}"
else
  file_ref = group.new_reference(file)
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added #{file}"
end

project.save
puts "Project saved"
