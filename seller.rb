class Seller < Channel
  def initialize(*params)
    @trader = params.first
    if params.size == 2
      super params.last
    else
      super self
    end
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

  def get_amount
    @amount = @trader.get_info["return"]["funds"][$currency].round_down(4) 
  end

  def run
    result = sell_trade
    if result["success"] != 1
      write_out("failed")
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
          main.write "successfully sold at #{@our_price}, current amount is #{@amount}"
        else 
          tries += 1
          if tries > 15
            puts "cancelling order and reselling"
            cancel = @trader.cancel_order(:order_id => result["return"]["order_id"])
            if cancel["success"] != 1
              puts "failed to make trade #{cancel.inspect}"
              write_out "failed"
              return
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
