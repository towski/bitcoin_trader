require_relative 'application'

insert_sql = "INSERT INTO old_trades (date, price, amount, tid, price_currency, item, trade_type) SELECT * FROM trades where date < now() - interval 360 minute ON DUPLICATE KEY UPDATE tid=tid;"
delete_sql = "DELETE FROM trades where date < now() - interval 360 minute"

connection = ActiveRecord::Base.connection

connection.execute(insert_sql).to_a.first.first
