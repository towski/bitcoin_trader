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

THRESHOLD = 0.05
TIME_THRESHOLD = 60 * 2

class Market
  def alarm(currency_pair, text)
    now = Time.now
    if @alarms[currency_pair]  
      if (now - @alarms[currency_pair]) < (5*60)
        return 
      else
        @alarms[currency_pair] = nil
      end
    end
    @alarms[currency_pair] = now
    puts currency_pair + " " + text
    system "curl -d apikey=a5f0446505fd867d2ea71625eb0c117a24d27c146753a28f -d application=btc-e -d event=\"market change\" -d description=\"#{currency_pair} #{text}\" https://www.notifymyandroid.com/publicapi/notify > /tmp/notify_output 2>&1"
    system 'ding'
  end

  def initialize
    @history = {}
    @alarms = {}
    trap("INT") do
      if !$http_block
        debugger
      else
        $got_signal = true
      end
    end
    Btce::API::CURRENCY_PAIRS.each do |currency_pair|
      @history[currency_pair] = []
    end
    loop do
      begin
        Btce::API::CURRENCY_PAIRS.each do |currency_pair|
          next if currency_pair == "trc_btc"
          $http_block = true
          ticker_json = Btce::PublicAPI.get_pair_operation_json currency_pair, "ticker"
          $http_block = false
          if $got_signal
            debugger
            $got_signal = false
          end
          loaded = Time.now
          ticker = ticker_json["ticker"]
          new_price = ticker["last"]
          #  {"ticker"=>{"high"=>1032, "low"=>927, "avg"=>979.5, "vol"=>27712734.09422, "vol_cur"=>28152.06481, "last"=>1015.85, "buy"=>1015.86, "sell"=>1015.85, "updated"=>1385763979, "server_time"=>1385763979}} 
          current_array = @history[currency_pair]
          increasing_prices = 0
          decreasing_prices = 0
          above_first_price = 0
          first_price = current_array.last ? current_array.last.first : 0
          previous_price = new_price
          current_array.each do |previous_pair|
            price = previous_pair.first
            if previous_price > price
              increasing_prices += 1 
            elsif previous_price < price
              decreasing_prices += 1
            end
            if price > first_price
              above_first_price += 1
            end
            previous_price = price
            previous_time = previous_pair.last
            time_difference = loaded - previous_time
            next if time_difference > TIME_THRESHOLD
            comparison = new_price.to_f / price
            if comparison < (1.0 - THRESHOLD) || comparison > (1.0 + THRESHOLD)
              alarm currency_pair, "changed"
            end
          end
          if increasing_prices > 20 && above_first_price > 25
            alarm currency_pair, "consistently increased"
          end
          if decreasing_prices > 30
            alarm currency_pair, "consistently dropped"
          end
          current_array.unshift [ticker["last"], loaded]
          @history[currency_pair] = current_array.take(40)
        end 
      rescue Timeout::Error => e
        puts "timeout"
      rescue => e
        debugger
        puts "error"
      ensure
        sleep 1
      end
    end
  end
end

Market.new
