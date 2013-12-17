require 'btce'
require 'ruby-debug'
require 'active_record'

class Float
  def precision(number = 3)
    "%8.#{number}f" % self
  end
end

class Fixnum
  def precision(number = 3)
    "%8.#{number}f" % self
  end
end

class Trade < ActiveRecord::Base
end

ActiveRecord::Base.establish_connection :database => "btce", :username => "root", :adapter => "mysql2"

$currency = ARGV[0]
unless $currency
  puts "no currency given"
  exit
end

class Trader
  def initialize
    tids = []
    since = 0
    buy_total = 0.0
    sell_total = 0.0
    loop do
      begin
        json = Btce::PublicAPI.get_pair_operation_json "#{$currency}_usd", "trades"
        json.reject!{|trade| tids.include? trade["tid"] }
        sleep 3 && next if json.size == 0
        json.map!{|trade| trade.update("date" => Time.at(trade["date"])) }
        json.each do |trade_json|
          begin
            Trade.create trade_json
            puts "saved #{$currency}"
          rescue => e
            puts "duplicate entry"
          end
        end
        tids += json.map{|trade| trade["tid"] }
        #buys = json.select{|trade| trade["trade_type"] == "bid" }
        #sells = json.select{|trade| trade["trade_type"] == "ask" }
        #largest_buy = json.max_by{|buy| buy["amount"] }
        #largest_price = json.max_by{|buy| buy["price"] }
        #sell_amount = sells.sum{|trade| trade["amount"] }
        #sell_total += sell_amount
        #buy_amount = buys.sum{|trade| trade["amount"] }
        #buy_total += buy_amount
        #trade_price = json.sum{|trade| trade["amount"] * trade["price"] }
        #puts "sells: #{sells.size} (#{sell_amount.precision(3)}) [#{sell_total.precision(3)}]  /   buys: #{buys.size} (#{buy_amount.precision(3)}) [#{buy_total.round(3)}]"
      rescue => e
        puts e.inspect
      ensure
        sleep 3
      end
    end
  end
end

Trader.new
