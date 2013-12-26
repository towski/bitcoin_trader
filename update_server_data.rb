require_relative 'application'

@trader = Btce::TradeAPI.new_from_keyfile

@dir = ARGV[0]

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

def write_file_for_time(start_date, end_date, filename, today = false)
  file = File.open("%s/%s" % [@dir, filename], "w")
  first_sell = Sell.where("date < ?", start_date).order("date desc").where(:pair => "btc_usd").first
  first_buy = Buy.where("date > ?", first_sell.date).order("date asc").where(:pair => "btc_usd").first
  if today
    last_sell = Sell.where("date < ?", end_date).order("date desc").where(:pair => "btc_usd").first
  else
    last_buy = Buy.where("date < ?", end_date).order("date desc").where(:pair => "btc_usd").first
    last_sell = Sell.where("date < ?", last_buy.date).order("date desc").where(:pair => "btc_usd").first
  end
  buy_amount = Buy.where("date between ? and ?", first_buy.date, last_sell.date).where(:pair => "btc_usd").sum("rate * amount")
  sell_amount = Sell.where("date between ? and ?", first_buy.date, last_sell.date).where(:pair => "btc_usd").sum("rate * amount")
  change = sell_amount > buy_amount ? (sell_amount / buy_amount) - 1 : (-buy_amount / sell_amount) + 1
  file.write((change * 100).round(2))
  file.close
end

write_file_for_time(Time.now.utc.beginning_of_day, Time.now.utc.end_of_day, "today.txt", true)
write_file_for_time(1.day.ago.utc.beginning_of_day, 1.day.ago.utc.end_of_day, "yesterday.txt")
write_file_for_time(2.days.ago.utc.beginning_of_day, 2.days.ago.utc.end_of_day, "before_yesterday.txt")
write_file_for_time(1.week.ago.utc.beginning_of_day, Time.today.utc.beginning_of_day, "week.txt")
