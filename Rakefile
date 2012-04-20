require 'rspec/core/rake_task'

def run(cmd, msg)
  `#{cmd}`
  if $?.exitstatus != 0
    puts msg
    exit 1
  end
end

def outstanding_changes?
  run "git diff-files --quiet", "You have outstanding changes. Please commit them first."
end

task :default => [:run]

desc "run sinatra app locally"
task :run => "Gemfile.lock" do
  require 'app'
  Sinatra::Application.run!
end

desc "bundle ruby gems"
task :bundle => "Gemfile.lock"

# need to touch Gemfile.lock as bundle doesn't touch the file if there is no change
file "Gemfile.lock" => "Gemfile" do
  sh "bundle && touch Gemfile.lock"
end

desc "run specs"
RSpec::Core::RakeTask.new(:spec)