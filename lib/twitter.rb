# frozen_string_literal: true

require 'http'
require 'json'

module Twitter
  class Client
    def initialize(twitter_bearer_token: nil)
      @twitter_bearer_token = twitter_bearer_token
    end

    def tweets(twitter_user_id: nil)
      url = "https://api.twitter.com/2/users/#{twitter_user_id}/tweets"
      response = HTTP.auth("Bearer #{@twitter_bearer_token}").get(url)
      response = JSON.parse(response.to_s, symbolize_names: true)
      tweets = response[:data].reject { |tweet| tweet[:text].start_with?('@') || tweet[:text].start_with?('RT') }
      tweets.map { |tweet| { id: tweet[:id].to_i, text: tweet[:text].gsub(/@((\w|_)+)/, '@ \1') } }
    end
  end
end
