require 'slack-ruby-client'
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

$seen = []

file = File.read('seen.json')
$seen = JSON.parse(file)

def check_librus
	c = Curl::Easy.perform("https://synergia.librus.pl/ogloszenia") do |curl| 
	  curl.headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.82 Safari/537.36"
	  curl.headers["Accept-Language"] = "en-US,en;q=0.8,pl;q=0.6"
	  curl.headers["Cache-Control"] = "no-cache"
	  curl.headers["Cookie"] = ENV['LIBRUS_COOKIE']
	  curl.headers["Referer"] = "https://synergia.librus.pl/uczen_index/twoje_uslugi"
	  curl.verbose = false 
	end

	page = Nokogiri::HTML(c.body_str)
	titles = page.css("form[name=formOgloszenia] > table > thead > tr > td")
	contents  = page.css('form[name=formOgloszenia] tr.line1 td')

	attachments = []
	titles.reverse.each_with_index do |title, i|
		n = titles.length - 1 - i
		title = title.text.strip
		author = contents[2*n].text.strip
		content = ReverseMarkdown.convert(contents[2*n+1].inner_html)
		hash = Digest::SHA256.base64digest title+':'+author+':'+content
		attachment = {
			"fallback": title + "  \n" + author + "  \n" + content,
			"title": title,
			"author_name": author,
			"text": content
		}
		if not $seen.include? hash
			attachments.push attachment
			$seen.push hash
		end
	end


	if not attachments.empty?
		$client.chat_postMessage(channel: '#librus-announcements', attachments: attachments, as_user: true)
	end

	File.open("seen.json","w") do |f|
	  f.write($seen.to_json)
	end
end

while true
	check_librus
	sleep 600
end