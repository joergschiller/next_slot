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
  arena_biontech: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=2495719&agenda_ids=397766-397800-402408-397776&insurance_sector=public&practice_ids=158431&destroy_temporary=true&limit=4",
  messe_biontech: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=2495719&agenda_ids=397846-404659-457443-457453-457477-457487-457405-457406-457416-457418-457426-457400-457404-457407-457409-457412-457414-457419-457420-457427-457448-457457-457463-457483-457410-457425-457428-457436-457415-457439-457408-397845-457504-457511-457421-457432-457435-457489-457493-397844-457411-457497-457424-457429-457430-457442-457470&insurance_sector=public&practice_ids=158434&destroy_temporary=true&limit=4",
  erikahess_moderna: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=2537716&agenda_ids=457956-457952-457975-457943-457979-457947-457951-457954-457902-457959-457903-457976-457966-457901-457913-457970-457941-457945-457946-457955-457953-457968-457971-457920-457973-457977-457960-457961-457963-457964-457906-457936-457967-457944-457910&insurance_sector=public&practice_ids=158437&destroy_temporary=true&limit=4",
  velodrom_biontech: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=2495719&agenda_ids=404654-457215-457319-397973-457227-457204-457296-397974-457312-457229-457280-457218-397972-457208-457210-457212-457213-457216-457299-457274-457278-457283-457288-457291-457304-457306-457315-457321-457206-457310&insurance_sector=public&practice_ids=158435&destroy_temporary=true&limit=4",
  tegel_biontech: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=2495719&agenda_ids=457297-397842-457268-457515-457500-397841-457512-457324-457341-457460-457513-457285-457293-457250-457251-457252-457264-457271-457279-457290-457292-457323-457329-457336-457337-457413-457335-457399-457514-457350-397843-404656-457510-457326-457330-457333-457334-457338-457346-457349-457358-457327-457253-457254-457255-457256-457265-457263-457266-457267-457294-457303-457275-457276-457277-457281-457286-457287-457289-457295-457300-457301-457309-457317-457331-457343-457363-457282&insurance_sector=public&practice_ids=158436&destroy_temporary=true&limit=4",
  tegel_moderna: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=2537716&agenda_ids=465584-465619-465575-465527-465534-465598-465601-465651-465543-466146-465630-465532-465526-465609-465615-465653-466127-466144-466128-466129-466130-466131-466132-466133-466134-466135-466136-466137-466138-466139-466140-466141-466143-466145-466147-466148-466149-466150-466151-466152-466153-466154-465678-465550-465553-465594-465701-465555-465558-465580-465582-465592&insurance_sector=public&practice_ids=158436&destroy_temporary=true&limit=4",
  tempelhof_moderna: "https://www.doctolib.de/availabilities.json?start_date=#{Date.today.iso8601}&visit_motive_ids=2537716&agenda_ids=467901-467933-467894-467897-467898-467899-467895-467896-467900-467908-467912-467893-467903-467905-467906-467907-467910-467911-467934-467935-467936-467937-467938-467939-467940&insurance_sector=public&practice_ids=158433&destroy_temporary=true&limit=4",
}

dates = URLS.map do |key, url|
  location, vaccine = key.to_s.split('_')

  location.capitalize!
  vaccine.capitalize!

  print "Checking #{location} for appointments with #{vaccine}:"

  next_slot = with_spinning_rod { HTTParty.get(url).parsed_response['next_slot'] }

  date = next_slot ? Date.parse(next_slot) : nil

  if date
    puts "next appointment is on #{date}".green
  else
    puts "no appointment available".red
  end

  { location: location, vaccine: vaccine, next_slot: date }
end

earliest = dates
             .select { _1[:next_slot] }
             .sort_by { _1[:next_slot] }
             .first

puts ''

if earliest
  puts "Earliest appointment is available in #{earliest[:location].yellow} with #{earliest[:vaccine].yellow} on #{earliest[:next_slot].to_s.yellow}."
  puts ''
  puts 'Book your appointment at https://www.doctolib.de/institut/berlin/ciz-berlin-berlin'.light_black
else
  puts 'No appointment available.'.red
end
