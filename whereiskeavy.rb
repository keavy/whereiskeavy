require 'foursquare2'
require 'google_weather'
require 'json'
require 'nokogiri'
require 'oauth2'
require 'open-uri'
require 'redis'
require 'rubygems'
require 'sinatra'
require 'tzinfo'
require 'yaml'

configure :production do
  uri = URI.parse(ENV["REDISTOGO_URL"])
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

configure :development do
  REDIS = Redis.new
end

class Foursquare
  def initialize(token)
    @oauth_token = token
  end

  def client
    Foursquare2::Client.new(:oauth_token => @oauth_token)
  end

  def last_checkin
    checkins = client.user_checkins
    checkins.items[0]
  end

  def venue
    last_checkin.venue
  end

  def location
    venue['location'] || {}
  end

  def location_str
    [location['city'], location['state'], location['country']].reject(&:nil?) * ', '
  end

  def lat_lng
    [location['lat'], location['lng']]
  end

  def timezone
    last_checkin['timeZone'] || 'GMT'
  end
end

class WhereIsKeavy
  OAUTH_TOKEN = ENV['OAUTH_TOKEN']

  def results(reload=false)
    return @results if @results unless reload
    
    foursquare = Foursquare.new(OAUTH_TOKEN)
    weather = GoogleWeather.new(foursquare.lat_lng)

    @results = {
      :timezone => foursquare.timezone,
      :lat_lng => foursquare.lat_lng,
      :location_str => foursquare.location_str,
      :city => foursquare.location['city'],
      :icon => weather.forecast_conditions[0].icon,
      :low => weather.forecast_conditions[0].low,
      :high => weather.forecast_conditions[0].high
    }
  end

  def store_results
    p results
    redis_store
    file_store
  end
  
  def load_results
    load_from_redis || load_from_file || {}
  end


  private
  def file_store
    File.open('./results.yml', 'w') do |out|
      YAML.dump(results, out)
    end
  end

  def load_from_file
    res = YAML.load_file('./results.yml')
    redis_store(res)
  rescue
    false
  end
  
  def redis_store(res=results)
    redis.set 'results', res.to_yaml
  end
  
  def load_from_redis
    if defined?(Redis) and res = redis.get('results')
      YAML.load(res)
    end
  rescue
    false
  end
  
  def redis
    @redis ||= begin
      REDIS
    end
  end
end

default_timezone = 'America/Phoenix'

get '/' do
  @results = WhereIsKeavy.new.load_results
  @timezone = TZInfo::Timezone.get(@results[:timezone] || default_timezone)
  erb :index
end