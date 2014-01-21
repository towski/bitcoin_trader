class SaveTrades < Channel
  def initialize(*params)
    @tids = []
    super
  end

  def run
    loop do
      begin
        json = Btce::PublicAPI.get_pair_operation_json "#{$currency}_usd", "trades"
        json.reject!{|trade| @tids.include? trade["tid"] }
        if json.size == 0
          write_out("no updates")
          sleep 3 
          next 
        end
        json.map!{|trade| trade.update("date" => Time.at(trade["date"])) }
        json.each do |trade_json|
          begin
            Trade.create trade_json
          rescue => e
          end
        end
        @tids += json.map{|trade| trade["tid"] }
        write_out("updates")
      rescue => e
        puts e.inspect
      ensure
        sleep 3
      end
    end
  end
end
