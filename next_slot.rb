#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem "colorize"
  gem "httparty"
  gem "rake"
end

# Credits to https://rosettacode.org/wiki/Spinning_rod_animation/Text#Ruby
def with_spinning_rod
  spinning = Thread.new do
    printf("\033[?25l") # Hide cursor
    %w[| / - \\].cycle do |rod|
      print rod
      sleep 0.25
      print "\b"
    end
  ensure
    printf("\033[?25h") # Restore cursor
  end

  value = yield

  spinning.exit

  print "\b " # Clear last character
  printf("\033[?25h") # Restore cursor

  value
end

URLS = {
  messe_biontech: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=3091828&agenda_ids=457399-457317-457323-457301-457500-457252-457285-457295-457324-457341-457460-457413-457250-457251-457292-457290-457331-457277-457333-457265-457309-457293&insurance_sector=public&practice_ids=158436&limit=4",
  messe_moderna: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=3091829&agenda_ids=493322-493298-493320-493285-493317-493306-493324-493314-493308-493300&insurance_sector=public&practice_ids=195952&limit=4",
  tegel_biontech: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=3091828&agenda_ids=457399-457317-457323-457301-457500-457252-457285-457295-457324-457341-457460-457413-457250-457251-457292-457290-457331-457277-457333-457265-457309-457293&insurance_sector=public&practice_ids=158436&limit=4",
  tegel_moderna: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=3091829&agenda_ids=465532-465550-465555-465553-465527-465543-465558-465575-465534-465526&insurance_sector=public&practice_ids=191612&limit=4",
}

dates = URLS.map do |key, url|
  location, vaccine = key.to_s.split('_')

  location.capitalize!
  vaccine.capitalize!

  print "Checking #{location} for booster appointments with #{vaccine}:"

  next_slot = with_spinning_rod do
    response = HTTParty.get(url, headers: { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36' })

    raise "Request not successful:\n\n#{response.inspect}" unless response.success?

    response.parsed_response['next_slot']
  end

  date = next_slot ? Date.parse(next_slot) : nil

  if date
    puts "next booster appointment is on #{date}".green
  else
    puts "no booster appointment available".red
  end

  { location: location, vaccine: vaccine, next_slot: date }
end

earliest = dates
             .select { _1[:next_slot] }
             .sort_by { _1[:next_slot] }
             .first

puts ''

if earliest
  puts "Earliest booster appointment is available in #{earliest[:location].yellow} with #{earliest[:vaccine].yellow} on #{earliest[:next_slot].to_s.yellow}."
  puts ''
  puts 'Book your booster appointment at https://www.doctolib.de/institut/berlin/ciz-berlin-berlin'.light_black
else
  puts 'No booster appointment available.'.red
end
