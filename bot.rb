require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

client = Slack::Web::Client.new

client.auth_test

client.chat_postMessage(channel: '#random', text: 'Hello World', as_user: true)