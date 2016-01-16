require "csv"
require 'sunlight/congress'
require 'erb'
require 'date'
require 'pp'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  return zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number (phone_num)

  phone_num = phone_num.to_s.gsub(/[^0-9]/, "").rjust(10,"0")
  if (phone_num.length == 11 && phone_num[0] == "1")
    phone_num = phone_num[1..10]
  elsif ((phone_num.length == 11 && phone_num[0] != "1") || phone_num.length > 11)
    phone_num = "0000000000"
  end
  #puts phone_num
end


def legislators_by_zipcode(zipcode)
  return Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def determine_popular_hours(hours)
  popular_hours = Hash.new(0)
  hours.each do |hour|
    popular_hours[hour] += 1
  end
  sorted_pop_hours = popular_hours.sort_by {|hour, count| count}.reverse
  puts "Most popular sign-up hours"
  puts "Hour\t\tNumber of sign-ups"
  sorted_pop_hours.each do |data|
    puts "#{data[0]}\t\t\t#{data[1]}"
  end
  #pp sorted_pop_hours
end

def determine_popular_days(days)
  day_of_week = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]
  popular_days = Hash.new(0)
  days.each do |day|
    popular_days[day_of_week[day]] += 1
  end
  sorted_pop_days = popular_days.sort_by {|day, count| count}.reverse
  puts "\nMost popular sign-up days"
  puts "Day\t\tNumber of sign-ups"
  sorted_pop_days.each do |data|
    if data[0].to_s.length > 7
         puts "#{data[0]}\t\t#{data[1]}"
    else
      puts "#{data[0]}\t\t\t#{data[1]}"
    end
  end
end

puts "EventManager ititialized";
hours = Array.new
days = Array.new

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode= clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  time = DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M")
  hours << time.hour
  days << time.wday

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)

end
determine_popular_hours(hours)
determine_popular_days(days)
