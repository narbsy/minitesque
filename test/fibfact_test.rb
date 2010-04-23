require 'minitest/unit'

class FibFactTest < MiniTest::Unit::TestCase
  def setup
    @fib = FibFact.new
  end

  def test_fib_small
    assert_equal 0, @fib.fib(0)
    assert_equal 1, @fib.fib(1)
  end
  
  def test_fib_large
    assert_equal 55, @fib.fib(10)
  end
end
