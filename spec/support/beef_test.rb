#
# Copyright (c) 2006-2024 Wade Alcorn - wade@bindshell.net
# Browser Exploitation Framework (BeEF) - https://beefproject.com
# See the file 'doc/COPYING' for copying permission
#
require 'selenium-webdriver'
require 'spec_helper'
require 'capybara'
require 'capybara/rspec'
Capybara.run_server = false # we need to run our own BeEF server

class BeefTest
  def self.save_screenshot(session, dir = nil)
    outputDir = dir || BEEF_TEST_DIR
    Dir.mkdir(outputDir) unless File.directory?(outputDir)
    session.driver.browser.save_screenshot(outputDir + Time.now.strftime('%Y-%m-%d--%H-%M-%S-%N') + '.png')
  end

  def self.login(session = nil)
    session = Capybara::Session.new(:selenium_headless) if session.nil?
    session.visit(ATTACK_URL)
    
    session.has_content?('Authentication', wait: 10)
    save_screenshot(session)

    # enter the credentials
    session.execute_script("document.getElementById('pass').value = '#{CGI.escapeHTML(BEEF_PASSWD)}'\;")
    session.execute_script("document.getElementById('user').value = '#{CGI.escapeHTML(BEEF_USER)}'\;")

    # due to using JS there seems to be a race condition - this is a workaround
    session.has_content?('beef', wait: 10)

    # click the login button
    login_script = <<-JAVASCRIPT
      var loginButton;
      var buttons = document.getElementsByTagName('button');
      for (var i = 0; i < buttons.length; i++) {
        if (buttons[i].textContent === 'Login') {
          loginButton = buttons[i];
          break;
        }
      }
      if (loginButton) {
        loginButton.click();
      }
    JAVASCRIPT
    session.execute_script(login_script)

    session.has_content?('Hooked Browsers', wait: 10)
    save_screenshot(session)

    session
  end

  def self.logout(session)
    session.click_link('Logout')

    session
  end

  def self.new_attacker
    self.login
  end

  def self.new_victim
    victim = Capybara::Session.new(:selenium_headless)
    victim.visit(VICTIM_URL)
    victim
  end
end
