class AmountUpdater < Channel
  def run
    loop do
      write_out @channel_out.trader.get_info["return"]["funds"][$currency].round_down(4) 
      sleep 20
      # todo wait for signal or timeout
    end
  end
end
