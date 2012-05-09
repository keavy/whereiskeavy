require 'rubygems'
require 'sinatra'
require 'foursquare2'
require 'oauth2'
require 'tzinfo'
require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'google_weather'

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
      if config = ENV['REDISTOGO_URL'] and uri = URI.parse(config)
        Redis.new :host => uri.host, :port => uri.port, :password => uri.password
      else
        Redis.new
      end
    end
  end
end

default_timezone = 'America/Phoenix'

get '/' do
  @results = WhereIsKeavy.new.load_results
  @timezone = TZInfo::Timezone.get(@results[:timezone] || default_timezone)
  erb :index
end