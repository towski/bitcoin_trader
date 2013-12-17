class MyTrade < ActiveRecord::Base
  def self.calculate_gains_for coin, time, time2
    self.all 
  end

  def price_amount
    price * amount
  end
end
