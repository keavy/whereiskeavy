require 'rubygems'
require 'sinatra'
require 'foursquare2'
require 'oauth2'
require 'active_support/time'
require 'yaml'
require 'nokogiri'
require 'open-uri'

OAUTH_TOKEN = ENV['OAUTH_TOKEN']

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

  def text
    [location['city'], location['state'], location['country']].reject(&:nil?) * ', '
  end

  def lat_lng
    [location['lat'], location['lng']]
  end

  def timezone
    # timeZoneOffset
    last_checkin['timeZone']
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

get '/' do
  foursquare = Foursquare.new(OAUTH_TOKEN)
  @text = foursquare.text
  @location = [foursquare.lat_lng, foursquare.text]
  @timezone = foursquare.timezone

  weather = Weather.new('Tucson')
  @temp_c = weather.temp_c
  @temp_f = weather.temp_f
  @icon = weather.icon

  erb :index
end