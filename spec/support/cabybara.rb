# frozen_string_literal: true

require 'selenium/webdriver'

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu') # Recommended for Windows
  options.add_argument('--no-sandbox') # Recommended for CI environments

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end

  # Optional: Allow switching to headful mode for debugging
  config.before(:each, :js, type: :system) do
    if ENV['SELENIUM_HEADFUL']
      driven_by :selenium_chrome
    else
      driven_by :selenium_chrome_headless
    end
  end
end
