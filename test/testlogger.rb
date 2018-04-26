#--*-coding:utf-8-*--

require 'test-unit'
require 'Logger'

class TestLogger < Test::Unit::TestCase
  class << self
    def startup
    end

    def shutdown
    end
  end

  def setup
      @logger = Logger.new(nil)
  end

  def cleanup
  end

  def teardown
  end

  def test_fatal
    assert_nothing_raised do
      @logger.fatal([])
    end
  end

  def test_error
    assert_nothing_raised do
      @logger.error([])
    end
  end

  def test_warn
    assert_nothing_raised do
      @logger.warn([])
    end
  end

  def test_debug
    assert_nothing_raised do
      @logger.debug([])
    end
  end

  def test_info
    assert_nothing_raised do
      @logger.info([])
    end
  end

  def test_fatal_o
    assert_raise do
      @logger.__fatal([])
    end
  end

  def test_error_o
    assert_raise do
      @logger.__error([])
    end
  end

  def test_warn_o
    assert_raise do
      @logger.__warn([])
    end
  end

  def test_debug_o
    assert_raise do
      @logger.__debug([])
    end
  end

  def test_info_o
    assert_raise do
      @logger.__info([])
    end
  end


end
