desc "run sinatra app locally"
task :run => "Gemfile.lock" do
  require './whereiskeavy'
  Sinatra::Application.run!
end

desc "Run those specs"
task :spec do
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new do |t|
    t.pattern = 'spec/*_spec.rb'
  end
end

task :default => :spec

desc "load results"
task :load_results do
  require './whereiskeavy'
  p WhereIsKeavy.new.store_results
end