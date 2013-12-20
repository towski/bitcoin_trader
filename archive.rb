require_relative 'application'

insert_sql = "INSERT INTO old_trades (id, date, price, amount, tid, price_currency, item, trade_type) SELECT * FROM trades where date < now() - interval 360 minute ON DUPLICATE KEY UPDATE old_trades.tid=old_trades.tid;"
delete_sql = "DELETE FROM trades where date < now() - interval 360 minute"

connection = ActiveRecord::Base.connection

connection.execute(insert_sql)
connection.execute(delete_sql)
