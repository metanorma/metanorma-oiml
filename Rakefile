require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

Dir.glob("tasks/*.rake").each { |t| load t }

task default: :spec
