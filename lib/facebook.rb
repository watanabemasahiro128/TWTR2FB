# frozen_string_literal: true

module Facebook
  class Client
    def initialize(email: nil, password: nil)
      @email = email
      @password = password
    end

    def login(driver: nil)
      driver.get('https://m.facebook.com/')
      sleep 10
      return driver if driver.find_elements(:name, 'login').length.zero?

      login_account_buttons = driver.find_elements(:class, '_mDeviceLoginHomepage__userNameAndBadge')
      if login_account_buttons.length.positive?
        login_account_buttons[0].click
        sleep 10
        return driver
      end

      driver.find_element(:name, 'email').send_keys(@email)
      sleep 1
      driver.find_element(:name, 'pass').send_keys(@password)
      sleep 1
      driver.find_element(:name, 'login').click
      sleep 10
      return driver unless driver.current_url.start_with?('https://m.facebook.com/login/save-device/')

      driver.find_element(:xpath, '//button[@value="OK"]').click
      sleep 10
      driver
    end

    def post(driver: nil, message: nil)
      driver.navigate.to('https://m.facebook.com/')
      sleep 10
      8.times do
        driver.action.key_down(:tab).perform
        sleep 1
      end
      driver.action.key_down(:enter).perform
      sleep 1
      driver.find_element(:xpath, '//textarea[@id="uniqid_1"]').send_keys(message)
      driver.action.move_to_location(0, 0).click.perform
      sleep 1
      driver.action.key_down(:tab).perform
      sleep 1
      driver.action.key_down(:enter).perform
      sleep 10
      driver
    end
  end
end
