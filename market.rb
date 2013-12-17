require 'btce'
require 'ruby-debug'

class Float
  def precision(number = 3)
    "%.#{number}f" % self
  end
end

class Fixnum
  def precision(number = 3)
    "%.#{number}f" % self
  end
end

class Market
  def initialize
    trap("INT") do
      if !$http_block
        $got_signal = true
      else
        $got_signal = true
      end
    end

    previous_10_sells = []
    loop do
      begin
        $http_block = true
        depth = Btce::PublicAPI.get_pair_operation_json "btc_usd", "depth" #[[28.6, 44.08847817], [28.7, 63.72908396]]
        $http_block = false
        sells = depth["asks"]
        first_30_sells = sells[0..30]
        last_30_amounts = first_30_sells.sum{|ask| ask.last }
        last_30_total = first_30_sells.sum{|ask| ask.first * ask.last }
        last_150_amounts = sells.sum{|ask| ask.last }
        last_150_total = sells.sum{|ask| ask.last }
        last_150_total_price = sells.sum{|ask| ask.last * ask.first }
        range = sells.first[0] - sells.last[0]
        string1 = "sell: #{(last_30_total / last_30_amounts).precision(3)}(#{last_30_amounts.precision(3)}) #{(last_150_total_price / last_150_amounts).precision(3) }(#{last_150_total.precision(3)}) #{sells.first[0].precision(3)} " 
        buys = depth["bids"]
        first_30_buys = buys[0..30]
        last_30_amounts = first_30_buys.sum{|bid| bid.last }
        last_30_total = first_30_buys.sum{|bid| bid.first * bid.last }
        last_150_amounts = buys.sum{|bid| bid.last }
        last_150_total = buys.sum{|bid| bid.last }
        last_150_total_price = buys.sum{|bid| bid.last * bid.first }
        range = buys.first[0] - buys.last[0]
        if $got_signal
          debugger
          $got_signal = false
        end
        puts string1 + "  /  buy: #{(last_30_total / last_30_amounts).precision(3)}(#{last_30_amounts.precision(3)}) #{(last_150_total_price / last_150_amounts).precision(3) } (#{last_150_total.precision(3) }) #{buys.first[0].precision(3)}" 
      rescue
        puts "error"
      ensure
        sleep 1
      end
    end
  end
end

Market.new
