class EMA < ActiveRecord::Base
  def self.calculate_latest(period, interval)
    ema = EMA.where(:period => period, :intervals => interval).order("date desc").first
    date = ema ? ema.date : period.minutes.ago
    k = 2.0 / (interval + 1)
    sql = "select sum(price * amount) / sum(amount)  from trades where item = 'btc' and date between '%s' and UTC_TIMESTAMP()"
    current_price = ActiveRecord::Base.connection.execute(sql % date).to_a.first.first
    new_ema = ema ? current_price ? current_price * k + ema.value * (1 - k) : ema.value : current_price
    current_time = Time.now.utc 
    if ema
      if current_time > date + (period * 60)
        EMA.create :period => period, :intervals => interval, :date => current_time, :value => new_ema
      end
    else
      ma_x_minutes_ago = "select sum(average) / count(*) from (select sum(price * amount) / sum(amount) as average, date, ROUND(UNIX_TIMESTAMP(date)/(%s * 60)) AS timekey from trades where item = 'btc' and date between DATE_SUB(UTC_TIMESTAMP() - INTERVAL %s minute, INTERVAL %s minute) and UTC_TIMESTAMP() - INTERVAL %s minute group by timekey) as average_table;"
      new_ema = ActiveRecord::Base.connection.execute(ma_x_minutes_ago % [period, 0, (period * intervals), 0]).to_a.first.first
      EMA.create :period => period, :intervals => interval, :date => current_time, :value => new_ema
    end
    new_ema
  end

  def self.loopero(time)
    money = 4000
    amount = 0
    bought = false
    trades = 0
    ema = start(time.utc, 3, 24)
    short_ema = start(time.utc, 3, 7)
    loop do
      puts ema
      puts "short: #{short_ema}"
      time += 3 * 60
      ema = next_ema(ema, 3, 24, time)
      short_ema = next_ema(short_ema, 3, 7, time)
      if short_ema > ema + 2.0 && !bought
        puts "bought"
        bought = true
        sql = "select price from old_trades where item = 'btc' and date < '%s' order by date desc limit 1"
        current_price = ActiveRecord::Base.connection.execute(sql % time.utc).to_a.first.first
        amount = money / current_price
        money = 0
      elsif short_ema < ema and bought
        puts "sold"
        bought = false
        sql = "select price from old_trades where item = 'btc' and date < '%s' order by date desc limit 1"
        current_price = ActiveRecord::Base.connection.execute(sql % time.utc).to_a.first.first
        money = amount * current_price
        amount = 0
        trades += 1
      end
      break if time > Time.now
    end
    puts "amount"
    puts amount
    sql = "select price from old_trades where item = 'btc' and date < '%s' order by date desc limit 1"
    current_price = ActiveRecord::Base.connection.execute(sql % time.utc).to_a.first.first
    puts current_price
    puts "money"
    puts money
    puts "trades"
    puts trades
  end

  def self.start(time, period, intervals)
    ma_x_minutes_ago = "select sum(average) / count(*) from (select sum(price * amount) / sum(amount) as average, date, ROUND(UNIX_TIMESTAMP(date)/(%s * 60)) AS timekey from old_trades where item = 'btc' and date between DATE_SUB('%s', INTERVAL %s minute) and '%s' group by timekey) as average_table;"
    sql = ma_x_minutes_ago % [period, time, (period * intervals), time]
    new_ema = ActiveRecord::Base.connection.execute(sql).to_a.first.first
  end

  def self.next_ema(previous_ema, period, interval, end_time)
    sql = "select price from old_trades where item = 'btc' and date < '%s' order by date desc limit 1"
    current_price = ActiveRecord::Base.connection.execute(sql % end_time.utc).to_a.first.first
    k = 2.0 / (interval + 1)
    new_ema = current_price * k + previous_ema * (1 - k)
  end
end
