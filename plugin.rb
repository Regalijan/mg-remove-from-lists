# frozen_string_literal: true

# name: mg-remove-from-lists
# about: Removes email address from mailgun suppression lists on user destroy
# version: 0.1
# author: Wolftallemo
# url: https://github.com/Wolftallemo/mg-remove-from-lists

require 'cgi'
require 'base64'

after_initialize do
  DiscourseEvent.on(:user_destroyed) do |user|
    emails = user.user_emails.pluck(:email)

    unless SiteSetting.mailgun_api_key && SiteSetting.notification_email
      return
    end

    lists = %w[bounces complaints unsubscribes whitelists]

    emails.each do |email|
      lists.each do |list|
        uri = URI("https://api.mailgun.net/v3/#{SiteSetting.notification_email.split("@")[1]}/#{list}/#{CGI.escape(email)}")
        req = Net::HTTP::Delete.new(uri)

        req.basic_auth("api", SiteSetting.mailgun_api_key)

        Net::HTTP.start(uri.hostname, uri.port) {|http|
          http.request(req)
        }
      end
    end
  end
end
