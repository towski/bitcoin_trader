class MysqlCalculations 
  def run
    ma_x_minutes_ago = "select sum(average) / count(*) from (select avg(price) as average, date, ROUND(UNIX_TIMESTAMP(date)/(%s * 60)) AS timekey from trades where item = '#{$currency}' and date between DATE_SUB(UTC_TIMESTAMP() - INTERVAL %s minute, INTERVAL %s minute) and UTC_TIMESTAMP() - INTERVAL %s minute group by timekey) as average_table;"
    ma3 = ActiveRecord::Base.connection.execute(ma_x_minutes_ago % [3, 0, (3 * 24), 0]).to_a.first.first
    short_ma3 = ActiveRecord::Base.connection.execute(ma_x_minutes_ago % [3, 0, (3 * 7), 0]).to_a.first.first
    [ma3, short_ma3]
  end
end
