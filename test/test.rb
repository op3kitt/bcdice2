#--*-coding:utf-8-*--

require 'test-unit'

class TestSample < Test::Unit::TestCase
  class << self
    def startup
    end

    def shutdown
    end
  end

  def setup
  end

  def cleanup
  end

  def teardown
  end

  def test_true
    assert_true(1==1)
  end

  def test_equal
    assert_equal('value', 'value')
  end
end