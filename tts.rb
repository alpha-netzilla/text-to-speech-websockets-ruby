#!/usr/bin/ruby

require 'eventmachine'
require 'rubygems'
require 'websocket-client-simple'
require 'json'
require 'uri'
require 'net/http'


params = {
	"accept" => "audio/wav",
	"text" => "Free Comment"
}

voice = "ja-JP_EmiVoice"

file_out = "./output.wav"



token = ''
uri = URI.parse("https://stream.watsonplatform.net/authorization/api/v1/token?url=https://stream.watsonplatform.net/text-to-speech/api")

Net::HTTP.start(uri.host, uri.port,:use_ssl => uri.scheme == 'https') do |http|
	request = Net::HTTP::Get.new(uri)
	request.basic_auth 'insert username', 'insert password'
	token = http.request(request)
end

watson_url = "wss://stream.watsonplatform.net/text-to-speech/api/v1/synthesize?voice=voice&recognize?watson-token=#{token.body}"



init_message = params.to_json
ws = ''

EM.run {
	fw = open(file_out, "w")
	ws = WebSocket::Client::Simple.connect watson_url
	file_sent = false
 
	ws.on :message do |event|
		#puts "debug message: #{event}"
		#data = JSON.parse(event.data)
		if event.type == :text
			puts "MESSAGE: #{event}#"
		elsif event.type == :binary
			#fw.puts(event)
			#puts "BIN: #{event}#"
			fw.print(event)
		elsif event.type == :close
			ws.on({:type => close})
		end
	end
 
	ws.on :open do
		puts "OPEN"
		ws.send(init_message)
	end

	ws.on :close do |e|
		puts "CLOSE #{if e!=nil then (e) end}"
		fw.close
		exit 1
	end

	ws.on :error do |e|
		puts "ERROR (#{e.inspect})"
		fw.close
		exit 1
	end
}

ws.close
