require './application'

period = ARGV[0]
interval = ARGV[1]

unless period && interval
  puts "Needs a period and an interval"
  exit 
end

loop do
  EMA.calculate_latest(period.to_i, interval.to_i)
  sleep 3 
end
