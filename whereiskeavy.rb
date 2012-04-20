require 'rubygems'
require 'sinatra'
require 'foursquare2'
require 'oauth2'
require 'active_support/time'
require 'yaml'

config = YAML.load_file('config/config.yml')
OAUTH_TOKEN = config['oauth_token']

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

get '/' do
  foursquare = Foursquare.new(OAUTH_TOKEN)
  @text = foursquare.text
  @location = [foursquare.lat_lng, foursquare.text]
  @timezone = foursquare.timezone
  erb :index
end