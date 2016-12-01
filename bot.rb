require 'slack-ruby-client'
require './librus/librus'
require 'nokogiri'
require 'curb'
require 'reverse_markdown'
require 'digest'
require 'json'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

$client = Slack::Web::Client.new

$client.auth_test

$librus = Librus.new
$librus.login ENV['LIBRUS_LOGIN'], ENV['LIBRUS_PASSWORD'] do |success|
  exit 1 unless success
end

$seen = []

file = File.read('seen.json')
$seen = JSON.parse(file)

def check_librus
	$librus.get_announcements do |success, announcements|
    attachments = []
    announcements.each do |announcement|
      hash = Digest::SHA1.base64digest "#{announcement['title']}:#{announcement[:author]}:#{announcement[:content]}"
      md_content = ReverseMarkdown.convert(announcement[:content])

      attachment = {
          'fallback': "#{announcement[:title]} \n#{announcement[:author]} \n#{md_content}",
          'title': announcement[:title],
          'author_name': announcement[:author],
          'text': md_content
      }

      if not $seen.include? hash
        attachments.push attachment
        $seen.push hash
      end
    end


    if not attachments.empty?
      $client.chat_postMessage(channel: '#librus-announcements', attachments: attachments, as_user: true)
    end

    File.open("seen.json", "w") do |f|
      f.write($seen.to_json)
    end
  end
end

while true
	check_librus
	sleep 600
end