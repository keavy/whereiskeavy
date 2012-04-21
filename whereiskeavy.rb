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

  def results
    foursquare = Foursquare.new(OAUTH_TOKEN)
    weather = GoogleWeather.new(foursquare.lat_lng)

    {
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
    File.open('./results.yml', 'w') do |out|
      YAML.dump(results, out)
    end
  end

  def load_results
    YAML.load_file('./results.yml')
  rescue
    {}
  end
end

get '/' do
  @results = WhereIsKeavy.new.load_results
  @timezone = TZInfo::Timezone.get(@results[:timezone])
  erb :index
end