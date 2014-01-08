require_relative 'application'

@trader = Btce::TradeAPI.new_from_keyfile

@dir = ARGV[0] || '.'

last_transaction = Transaction.order("tid desc").limit(1).first

transactions = @trader.trade_history(:from_id => last_transaction.tid)["return"]

transactions.each do |key, value| 
  unixtime = value.delete("timestamp")
  value["type"][0] = value["type"][0].upcase
  begin
    puts "creating"
    Transaction.create(value.merge(:tid => key, :date => Time.at(unixtime))) 
  rescue ActiveRecord::RecordNotUnique => e
    puts "dupe"
  end
end

def write_file_for_time(start_date, end_date, filename, pair = "btc_usd", today = false)
  file = File.open("%s/%s" % [@dir, filename], "w")
  first_sell = Sell.where("date < ?", start_date).order("date desc").where(:pair => pair).first
  first_buy = Buy.where("date > ?", first_sell.date).order("date asc").where(:pair => pair).first
  if today
    last_sell = Sell.where("date < ?", end_date).order("date desc").where(:pair => pair).first
  else
    last_buy = Buy.where("date < ?", end_date).order("date desc").where(:pair => pair).first
    last_sell = Sell.where("date < ?", last_buy.date).order("date desc").where(:pair => pair).first
  end
  buy_amount = Buy.where("date between ? and ?", first_buy.date, last_sell.date).where(:pair => pair).sum("rate * amount")
  sell_amount = Sell.where("date between ? and ?", first_buy.date, last_sell.date).where(:pair => pair).sum("rate * amount")
  change = sell_amount - buy_amount
  file.write(change)
  file.close
end

write_file_for_time(Time.now.utc.beginning_of_day, Time.now.utc.end_of_day, "today_btc.txt", "btc_usd", true)
write_file_for_time(1.day.ago.utc.beginning_of_day, 1.day.ago.utc.end_of_day, "yesterday_btc.txt")
write_file_for_time(2.days.ago.utc.beginning_of_day, 2.days.ago.utc.end_of_day, "before_yesterday_btc.txt")
write_file_for_time(1.week.ago.utc.beginning_of_day, Time.today.utc.beginning_of_day, "week_btc.txt")
write_file_for_time(Time.now.utc.beginning_of_day, Time.now.utc.end_of_day, "today_ltc.txt", "ltc_usd", true)
write_file_for_time(1.day.ago.utc.beginning_of_day, 1.day.ago.utc.end_of_day, "yesterday_ltc.txt", "ltc_usd")
write_file_for_time(2.days.ago.utc.beginning_of_day, 2.days.ago.utc.end_of_day, "before_yesterday_ltc.txt", "ltc_usd")
write_file_for_time(1.week.ago.utc.beginning_of_day, Time.today.utc.beginning_of_day, "week_ltc.txt", "ltc_usd")
