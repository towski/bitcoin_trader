require_relative '../application'
require 'rr'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end
