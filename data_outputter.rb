require_relative 'application'

filename = ARGV[0]

file = File.open(filename, "w")
file << "date price"
MyTrade.find_each(:conditions => "date > now() - interval 2 day") do |trade|
  file << "#{trade.date.strftime("%Y-%m-%d-%H:%M:%S")} #{trade.price}\n"
end
file.close
