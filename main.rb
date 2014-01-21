require_relative 'application'
require_relative '../channels/lib/channel'
require_relative 'save_trades'
require_relative 'seller'
require_relative 'mysql_calculations'
require_relative 'amount_updater'

$currency = ARGV[0]
unless $currency
  puts "no currency given"
  exit
end

class Main < Channel
  attr_reader :amount, :trader 

  def initialize
    super
    @subchannels = {}
    @trader = Btce::TradeAPI.new_from_keyfile
    add_save_trades
    add_amount_updater
  end

  def add_save_trades
    add_subchannel(SaveTrades.new(self)){|output|
      if output == "updates"
        calculations = MysqlCalculations.new
        results = calculations.run
        puts "Short: #{results.last}, Long: #{results.first}"
        if results.last < results.first && amount > 0.01
          add_seller
        end
      end
    }
  end

  def add_amount_updater
    add_subchannel(AmountUpdater.new(self)){|response|
      puts "amount #{response}"
      @amount = response
    }
  end

  def add_seller
    if !@seller
      @seller = Seller.new(self)
      add_subchannel(@seller){ |result|
        if result == "failed"
          puts "removing subchannel"
          remove_subchannel @seller
          @seller = nil
        end
      }
    else
      @seller
    end
  end

  def add_subchannel(channel, &block)
    @subchannels[channel] = block
  end

  def remove_subchannel(channel)
    channel.kill
    @subchannels[channel] = nil
  end

  def process
    result = self.read
    function = @subchannels[self.sender]
    begin
      instance_exec result, &function
    rescue => e
      puts "got an error #{e.inspect}"
    end
  end

  def run
    loop do
      process
    end
  end
end

Main.new
sleep
