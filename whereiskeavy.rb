require 'rubygems'
require 'sinatra'
require 'foursquare2'
require 'oauth2'
require 'tzinfo'
require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'json'

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

class Weather
  def initialize(location)
    @location = location
  end

  def report
    Nokogiri::XML(open("http://www.google.com/ig/api?weather=#{@location}"))
  end

  def temp_c
    report.css("weather current_conditions temp_c").attr('data').value
  end

  def temp_f
    report.css("weather current_conditions temp_f").attr('data').value
  end

  def icon
    report.css("weather current_conditions icon").attr('data').value
  end
end

class WhereIsKeavy
  OAUTH_TOKEN = ENV['OAUTH_TOKEN']

  def results
    foursquare = Foursquare.new(OAUTH_TOKEN)
    weather = Weather.new(foursquare.location['city'])
    {
      :timezone => foursquare.timezone,
      :lat_lng => foursquare.lat_lng,
      :location_str => foursquare.location_str,
      :temp_c => weather.temp_c,
      :temp_f => weather.temp_f,
      :icon => weather.icon
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