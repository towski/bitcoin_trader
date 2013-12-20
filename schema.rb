require_relative 'application'

class CreateMyTrades < ActiveRecord::Migration
  def change
    create_table(:my_trades) do |t|
      t.datetime :date,  :null => false
      t.float :price,  :null => false
      t.float :amount,  :null => false
      t.integer :tid
      t.string :price_currency
      t.string :item
      t.string :trade_type
    end
  end
end

class CreateTrades < ActiveRecord::Migration
  def change
    create_table(:trades) do |t|
      t.datetime :date,  :null => false
      t.float :price,  :null => false
      t.float :amount,  :null => false
      t.integer :tid,  :null => false
      t.string :price_currency
      t.string :item
      t.string :trade_type
    end

    add_index :trades, :tid, :unique => true
  end
end

class CreateOldTrades < ActiveRecord::Migration
  def change
    create_table(:old_trades) do |t|
      t.datetime :date,  :null => false
      t.float :price,  :null => false
      t.float :amount,  :null => false
      t.integer :tid,  :null => false
      t.string :price_currency
      t.string :item
      t.string :trade_type
    end

    add_index :old_trades, :tid, :unique => true
  end
end

unless ActiveRecord::Base.connection.table_exists? 'my_trades'
  CreateMyTrades.migrate :up
end

unless ActiveRecord::Base.connection.table_exists? 'trades'
  CreateTrades.migrate :up
end

unless ActiveRecord::Base.connection.table_exists? 'old_trades'
  CreateOldTrades.migrate :up
end
