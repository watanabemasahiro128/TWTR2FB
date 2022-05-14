# frozen_string_literal: true

require 'json'
require 'dotenv'
require 'selenium-webdriver'
require 'sentry-ruby'
require_relative 'lib/twitter'
require_relative 'lib/facebook'

Dotenv.load("#{__dir__}/.env")
TWITTER_BEARER_TOKEN = ENV.fetch('TWITTER_BEARER_TOKEN')
TWITTER_USER_ID = ENV.fetch('TWITTER_USER_ID')
FACEBOOK_EMAIL = ENV.fetch('FACEBOOK_EMAIL')
FACEBOOK_PASSWORD = ENV.fetch('FACEBOOK_PASSWORD')
SENTRY_DSN = ENV.fetch('SENTRY_DSN')

Sentry.init do |config|
  config.dsn = SENTRY_DSN
  config.traces_sample_rate = 1.0
end

begin
  twitter_client = Twitter::Client.new(twitter_bearer_token: TWITTER_BEARER_TOKEN)
  tweets = twitter_client.tweets(twitter_user_id: TWITTER_USER_ID).slice(0, 10)
  if File.exist?("#{__dir__}/posted_tweet_ids.json")
    posted_tweet_ids = File.open("#{__dir__}/posted_tweet_ids.json", 'r') { |file| JSON.parse(file.read)['ids'] }
    tweets.reject! { |tweet| posted_tweet_ids.include?(tweet[:id]) }
  end

  return if tweets.empty?

  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    'goog:chromeOptions' => {
      'args' => [
        'headless',
        'disable-gpu',
        'lang=ja-JP',
        'user-agent=Mozilla/5.0 (X11; CrOS aarch64 13597.84.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.106 Safari/537.36',
        "user-data-dir=#{__dir__}/user_data"
      ]
    }
  )
  driver = Selenium::WebDriver.for(:chrome, capabilities:)
  driver.manage.timeouts.implicit_wait = 10

  facebook_client = Facebook::Client.new(email: FACEBOOK_EMAIL, password: FACEBOOK_PASSWORD)
  driver = facebook_client.login(driver:)
  tweets.each { |tweet| driver = facebook_client.post(driver:, message: tweet[:text]) }

  posted_tweet_ids += tweets.map { |tweet| tweet[:id] }
  File.open("#{__dir__}/posted_tweet_ids.json", 'w') { |file| JSON.dump({ ids: posted_tweet_ids }, file) }

  driver.quit
  Sentry.capture_message('Success', level: :info)
rescue StandardError => e
  Sentry.capture_exception(e)
end
