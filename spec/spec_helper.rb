require File.join(File.dirname(__FILE__), '..', 'whereiskeavy.rb')

require 'sinatra'
require 'rack/test'
require 'webmock/rspec'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  Sinatra::Application
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include WebMock
end

def fixture_file(filename, options={})
  return '' if filename == ''
  file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/' + filename)
  fixture   = File.read(file_path)
  
  case File.extname(file_path)
  when '.json'
    options[:parse] ? Hashie::Mash.new(JSON.parse(fixture)) : fixture
  else
    fixture
  end
end