#!/usr/bin/ruby

require "net/http"
require "uri"
require "pp"
require 'rubygems'
require 'nokogiri'
require 'gmetric'

router =  ARGV[0]
user =  ARGV[1]
pass =  ARGV[2]

uri = URI.parse("http://#{router}/RST_stattbl.htm")

http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
request.basic_auth(user, pass)
response = http.request(request)

pp response

doc = Nokogiri::HTML(response.body)

rows = doc.xpath('/html/body/table[2]/tr[3]/td/table/tr')
details = rows.collect do |row|
#	pp row
	detail = {}
	[
		[:port, 'td[1]/span[1]/text()'],
		[:status, 'td[2]/span[1]/text()'],
		[:txpkts, 'td[3]/span[1]/text()'],
		[:rxpkts, 'td[4]/span[1]/text()'],
		[:collisions, 'td[5]/span[1]/text()'],
		[:txbytespersec, 'td[6]/span[1]/text()'],
		[:rxbytespersec, 'td[7]/span[1]/text()'],
		[:uptime, 'td[8]/span[1]/text()'],
	].each do |name, xpath|
		detail[name] = row.at_xpath(xpath).to_s.strip
	end
	detail
end

#pp details
details.each do |detail|
	detail[:port].gsub!(/\//, '')
	detail[:port].gsub!(/ /, '_')

	next if detail[:port] == "Port"
	if detail[:txbytespersec] != ""  or detail[:rxbytespersec] != ""
		puts "netgear r6300 #{detail[:port]} tx bytes/s #{detail[:txbytespersec]}"
		puts "netgear r6300 #{detail[:port]} rx bytes/s #{detail[:rxbytespersec]}"
	end
	Ganglia::GMetric.send( "239.2.11.71", 8649, {
		:name => "netgear-r6300-#{detail[:port]}-tx",
		:units => 'bytes/s',
		:type => 'uint16',     # unsigned 8-bit int
		:value => detail[:txbytespersec],       # value of metric
		:tmax => 60,          # maximum time in seconds between gmetric calls
		:dmax => 300          # lifetime in seconds of this metric
	})

	Ganglia::GMetric.send( "239.2.11.71", 8649, {
		:name => "netgear-r6300-#{detail[:port]}-rx",
		:units => 'bytes/s',
		:type => 'uint16',     # unsigned 8-bit int
		:value => detail[:rxbytespersec],       # value of metric
		:tmax => 60,          # maximum time in seconds between gmetric calls
		:dmax => 300          # lifetime in seconds of this metric
	})
end

exit 0
