require 'test/unit'
require_relative 'test_helper'
require_relative '../seller'
require 'ruby-debug'

$currency = "btc"

class SellerTest < Test::Unit::TestCase
  def test_channel
    trader = Btce::TradeAPI.new_from_keyfile
    stub(trader).trade { {"success" => 0} }
    seller = Seller.new(trader)
    assert_equal 'failed', seller.read
  end
end
