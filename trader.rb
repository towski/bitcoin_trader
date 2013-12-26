require_relative 'application'

$currency = ARGV[0]
unless $currency
  puts "no currency given"
  exit
end

$threshold = ARGV[1]
unless $threshold
  puts "no threshold given"
  exit
end
$threshold = $threshold.to_f

$money = ARGV[2]
unless $money
  $money = 0 
end

class Trader
  attr_reader :trader

  def initialize
    @trader = Btce::TradeAPI.new_from_keyfile
    @index = 0
    @money = $money.to_f
    get_amount
    @bought = @amount > 0.00009 && @money == 0 ? true : false
    puts "bought #{@bought} #{@amount}"
    @buy_total = 0.0
    @last_price = 0.0
    trap("INT") do
      $got_signal = true
    end
    @last_transaction_at = nil
  end

  def get_amount
    @amount = @trader.get_info["return"]["funds"][$currency].round_down(4) 
  end

  def data_old?
    trade = Trade.where(:item => "btc").order("date desc").limit(1).first
    current = Time.now.utc
    if trade.date < (current - (10 * 60))
      puts "Data old"
      return true
    else
      puts "Data fresh"
      return false
    end
  end

  def start_watching
    loop do
      begin
        ma_x_minutes_ago = "select sum(average) / count(*) from (select avg(price) as average, date, ROUND(UNIX_TIMESTAMP(date)/(%s * 60)) AS timekey from trades where item = '#{$currency}' and date between DATE_SUB(UTC_TIMESTAMP() - INTERVAL %s minute, INTERVAL %s minute) and UTC_TIMESTAMP() - INTERVAL %s minute group by timekey) as average_table;"
        ma3 = ActiveRecord::Base.connection.execute(ma_x_minutes_ago % [1, 0, (1 * 24), 0]).to_a.first.first
        short_ma3 = ActiveRecord::Base.connection.execute(ma_x_minutes_ago % [1, 0, (1 * 7), 0]).to_a.first.first
        if @index % 50 == 0
          puts "status: %s %s %s %s" % [@last_price, @amount.round(4), @money, Time.now]
          puts "long term: %s" % ma3.round(4)
          puts "short term: %s" % short_ma3.round(4) 
        end
        wait_period = @last_transaction_at ? Time.now - @last_transaction_at < (3 * 60)  : false
        if (short_ma3) < ma3 && @bought && !wait_period #ma2 < ma1 && ma3 < ma2 && @bought
          #if ma2 - ma3 > $threshold
            @bought = false
            sell unless data_old?
            puts "sell %s %s" % [ma3, Time.now]
          #end
        end
        if (short_ma3) > (ma3 + $threshold) && !@bought && !wait_period #ma3 > ma2 && ma2 > ma1 && !@bought
          #if ma3 - ma2 > $threshold
            @bought = true
            buy unless data_old?
            puts "buy %s %s" % [ma3, Time.now]
          #end
        end
        @index += 1
        if $got_signal
          debugger
          $got_signal = false
        end
      rescue SocketError => e
        puts "Socket error"
      rescue => e
        if e.message != "Server returned invalid data."
          debugger
        end
      ensure
        sleep 1
      end
    end
  end

  def buy_trade
    depth = Btce::PublicAPI.get_pair_operation_json "#{$currency}_usd", "depth" #[[28.6, 44.08847817], [28.7, 63.72908396]]
    buys = depth["bids"]
    top_price = buys.first.first
    @our_price = (top_price + 0.001).round(3)
    @last_price = @our_price
    new_amount = (@money / @our_price).round_down(4)
    puts "buying #{new_amount} #{@our_price}"
    @trader.trade(:pair => "#{$currency}_usd", :type => "buy", :rate => @our_price, :amount => new_amount)
  end

  def buy
    result = buy_trade
    if result["success"] != 1
      puts "failed to make trade #{result.inspect}"
      return
    end
    order_complete = false
    tries = 0
    while !order_complete
      begin
        results = @trader.order_list
        if results["return"].nil?
          get_amount
          MyTrade.create :amount => @amount, :price => @our_price, :item => $currency, :trade_type => "buy", :date => Time.now
          @money = 0
          @last_transaction_at = Time.now
          order_complete = true
          puts "successfully bought at #{@our_price}"
        else 
          tries += 1
          if tries > 15
            puts "cancelling order and reselling"
            cancel = @trader.cancel_order(:order_id => result["return"]["order_id"])
            if cancel["success"] != 1
              puts "failed to make trade #{cancel.inspect}"
              exit
            end
            old_amount = @amount
            get_amount
            amount_bought = @amount - old_amount
            puts "old amount #{old_amount} current amount #{@amount} amount_bought #{amount_bought}"
            if amount_bought > 0.000001
              MyTrade.create :amount => amount_bought, :price => @our_price, :item => $currency, :trade_type => "sell", :date => Time.now
              @money = @money - @money * @amount
              puts "current amount #{@amount}, current money #{@money}"
            end
            result = buy_trade
            tries = 0
          else
            puts "waiting for order to complete"
          end
        end
      rescue => e
        if e.message != "Server returned invalid data."
          debugger
        end
      end
      if $got_signal
        debugger
        $got_signal = false
      end
      sleep 2
    end
    puts "done"
  end

  def sell_trade
    depth = Btce::PublicAPI.get_pair_operation_json "#{$currency}_usd", "depth" #[[28.6, 44.08847817], [28.7, 63.72908396]]
    sells = depth["asks"]
    top_price = sells.first.first
    @our_price = (top_price - 0.001).round(3)
    get_amount
    @last_price = @our_price
    puts "selling #{@amount} #{@our_price}"
    @trader.trade(:pair => "#{$currency}_usd", :type => "sell", :rate => @our_price, :amount => @amount)
  end

  def sell
    result = sell_trade
    if result["success"] != 1
      puts "failed to make trade #{result.inspect}"
      return
    end
    order_complete = false
    tries = 0
    while !order_complete
      begin
        results = @trader.order_list
        if results["return"].nil? #|| results["return"].size == 0
          MyTrade.create :amount => @amount, :price => @our_price, :item => $currency, :trade_type => "sell", :date => Time.now
          @money += @our_price * @amount
          get_amount
          @last_transaction_at = Time.now
          order_complete = true
          puts "successfully sold at #{@our_price}, current amount is #{@amount}"
        else 
          tries += 1
          if tries > 15
            puts "cancelling order and reselling"
            cancel = @trader.cancel_order(:order_id => result["return"]["order_id"])
            if cancel["success"] != 1
              puts "failed to make trade #{cancel.inspect}"
              exit
            end
            old_amount = @amount
            get_amount
            amount_sold = old_amount - @amount 
            puts "old amount #{old_amount} current amount #{@amount} amount_sold #{amount_sold}"
            if amount_sold > 0.000001
              MyTrade.create :amount => amount_sold, :price => @our_price, :item => $currency, :trade_type => "sell", :date => Time.now
              @money += @our_price * amount_sold
              puts "current money amount #{@money}"
            end
            result = sell_trade
            tries = 0
          else
            puts "waiting for order to complete"
          end
        end
      rescue => e
        if e.message != "Server returned invalid data."
          debugger
        end
      end
      if $got_signal
        debugger
        $got_signal = false
      end
      sleep 2
    end
  end
end

trader = Trader.new
trader.start_watching
