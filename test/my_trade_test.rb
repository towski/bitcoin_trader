$database = "btce_test"
load File.dirname(__FILE__) + "/../application.rb"
require 'test/unit'
class MyTradeTest < Test::Unit::TestCase
  def test_something
    date1 = Date.yesterday
    date2 = Date.today
    MyTrade.create :date => date1, :price => 1, :amount => 1, :trade_type => "buy", :item => "btc"
    MyTrade.create :date => date2, :price => 1.2, :amount => 1, :trade_type => "buy", :item => "btc"
    gains = MyTrade.calculate_gains_for 'ltc', Date.yesterday, Date.today
    assert_equal gains, 30
  end
end
