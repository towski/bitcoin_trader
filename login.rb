require 'btce'
require 'ruby-debug'
trader = Btce::TradeAPI.new_from_keyfile
def buy
  depth = Btce::PublicAPI.get_pair_operation_json "btc_usd", "depth" #[[28.6, 44.08847817], [28.7, 63.72908396]]
  buys = depth["bids"]
  top_price = buys.first.first
  our_price = (top_price + 0.001).round(3)
  total_amount = 0.0
  total_money = 100.0
  trader.trade(:pair => "btc_usd", :type => "buy", :rate => our_price, :amount => "0.01")
  order_complete = false
  while !order_complete
    begin
      results = trader.order_list
      if results["return"].size == 0
        total_amount += 0.01
        total_money -= 0.01 * our_price
        order_complete = true
      else 
        puts "waiting for order to complete"
      end
    rescue => e
      debugger
    end
    sleep 2
  end
  puts "done"
end

def sell
  depth = Btce::PublicAPI.get_pair_operation_json "btc_usd", "depth" #[[28.6, 44.08847817], [28.7, 63.72908396]]
  sells = depth["asks"]
  top_price = sells.first.first
  our_price = (top_price - 0.001).round(3)
  total_amount = 0.0
  total_money = 100.0
  trader.trade(:pair => "btc_usd", :type => "sell", :rate => our_price, :amount => "0.01")
  order_complete = false
  while !order_complete
    begin
      results = trader.order_list
      if results["return"].size == 0
        total_amount -= 0.01
        total_money += 0.01 * our_price
        order_complete = true
      else 
        puts "waiting for order to complete"
      end
    rescue => e
      debugger
    end
    sleep 2
  end
end
