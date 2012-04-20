require 'spec_helper'

describe 'WhereIsKeavy' do
  include Rack::Test::Methods

  describe "Homepage" do
    before do
      result = fixture_file('checkins.json')
      stub_request(:get, /api.foursquare.com/).to_return(:status => 200, :body => result, :headers => {})
    end

    it "responds" do
      get '/'
      last_response.should be_ok
    end

    it "displays location of last checkin" do
      get '/'
      last_response.body.should =~ /United States/
    end
  end
end

