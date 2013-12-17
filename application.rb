require 'btce'
require 'ruby-debug'
require 'active_record'
require_relative 'trade'
require_relative 'my_trade'

$database ||= ENV["DATABASE"] || "btce"

class Float
  def precision(number = 3)
    "%8.#{number}f" % self
  end

  def round_down x=0
    (self * 10**x).floor.to_f / 10**x
  end
end

class Fixnum
  def precision(number = 3)
    "%8.#{number}f" % self
  end
end

ActiveRecord::Base.establish_connection :database => $database, :username => "root", :adapter => "mysql2"
