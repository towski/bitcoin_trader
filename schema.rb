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

class CreateTransactions < ActiveRecord::Migration
  def change
    create_table(:transactions) do |t|
      t.datetime :date,  :null => false
      t.float :rate,  :null => false
      t.float :amount,  :null => false
      t.integer :order_id,  :null => false
      t.integer :tid,  :null => false
      t.boolean :is_your_order
      t.string :pair
      t.string :type
    end

    add_index :transactions, :tid, :unique => true
  end
end

class CreateEMAs < ActiveRecord::Migration
  def change
    create_table(:emas) do |t|
      t.datetime :date,  :null => false
      t.float :value,  :null => false
      t.integer :period,  :null => false
      t.integer :intervals,  :null => false
      t.string :pair
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

unless ActiveRecord::Base.connection.table_exists? 'transactions'
  CreateTransactions.migrate :up
end

unless ActiveRecord::Base.connection.table_exists? 'emas'
  CreateEMAs.migrate :up
end

unless ActiveRecord::Base.connection.table_exists? 'trades'
  CreateTrades.migrate :up
end

unless ActiveRecord::Base.connection.table_exists? 'old_trades'
  CreateOldTrades.migrate :up
end
