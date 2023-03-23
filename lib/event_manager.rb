# frozen_string_literal: true

puts 'Event Manager Initialized!'

lines = File.readlines('event_attendees.csv')
lines.each do |line|
  columns = line.split(',')
  name = columns[2]
  puts name
end
