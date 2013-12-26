require_relative 'application'

dir = ARGV[0]

buy_file = File.open("%s/buys.tsv" % dir, "w")
sell_file = File.open("%s/sells.tsv" % dir, "w")
buy_file << "date\tprice\n"
sell_file << "date\tprice\n"
Transaction.find_each(:conditions => "date > now() - interval 2 day and type = 'buy'") do |trade|
  buy_file << "#{trade.date.strftime("%Y-%m-%d-%H:%M:%S")}\t#{trade.rate}\n"
end
Transaction.find_each(:conditions => "date > now() - interval 2 day and type = 'sell'") do |trade|
  sell_file << "#{trade.date.strftime("%Y-%m-%d-%H:%M:%S")}\t#{trade.rate}\n"
end
buy_file.close
sell_file.close
