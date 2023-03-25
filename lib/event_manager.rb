# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  clean_num = phone_number.gsub(/[()-. ]/, '')
  case clean_num.length
  when 10
    clean_num
  when 11
    clean_num[1..] if clean_num[0] == '1'
  else
    '0000000000'
  end
end

def find_hour(reg_date)
  Time.parse(reg_date[-5..].gsub(' ', '0')).hour
end

def find_peak_hours(reg_hours)
  peak_hours = reg_hours.reduce(Hash.new(0)) do |hour, instance|
    hour[instance] += 1
    hour
  end

  peak_hrs_srtd = peak_hours.sort_by { |_key, value| value }

  "The peak registration hours are #{peak_hrs_srtd[-1][0]}00, #{peak_hrs_srtd[-2][0]}00, & #{peak_hrs_srtd[-3][0]}00."
end

def find_date(reg_date)
  clean_date = reg_date[0..-7].split('/').map { |num| num.rjust(2, '0') }.join('-').insert(-3, '20')

  Date.strptime(clean_date, '%m-%d-%Y')
end

def peak_weekday(dates)
  weekday_arr = dates.map { |date| Date::DAYNAMES[date.wday] }

  weekday_hash = weekday_arr.reduce(Hash.new(0)) do |day, instance|
    day[instance] += 1
    day
  end

  days_sorted = weekday_hash.sort_by { |_key, value| value }

  "The peak registration days are #{days_sorted[-1][0]}, followed by #{days_sorted[-2][0]} & #{days_sorted[-3][0]}."
end

# rubocop:disable Metrics/MethodLength

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-actin/find-elected-officials'
  end
end

# rubocop:enable Metrics/MethodLength

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager Initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_hours = []
reg_dates = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  reg_hours << find_hour(row[:regdate])
  reg_dates << find_date(row[:regdate])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  # Disable save_thank_you letter method
  # save_thank_you_letter(id, form_letter)
end

puts find_peak_hours(reg_hours)
puts peak_weekday(reg_dates)
