require 'helper'

class MeasureOutputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
  ]
  # CONFIG = %[
  #   path #{TMP_DIR}/out_file_test
  #   compress gz
  #   utc
  # ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::MeasureOutput, tag).configure(conf)
  end

  def test_timer_by_numeric
    o = Fluent::MeasureOutput.new
    @expected = Time.now + 1
    o.timer(1) { @actual = Time.now }
    assert_equal(@expected.to_i, @actual.to_i)
  end

  def test_timer_by_time
    o = Fluent::MeasureOutput.new
    @expected = Time.now + 1
    o.timer(@expected) { @actual = Time.now }
    assert_equal(@expected.to_i, @actual.to_i)
  end

  def test_timer_by_string
    o = Fluent::MeasureOutput.new
    @expected = Time.now + 1
    o.timer(@expected.to_s) { @actual = Time.now }
    assert_equal(@expected.to_i, @actual.to_i)
  end

  def test_timer_by_other
    o = Fluent::MeasureOutput.new
    assert_raise RuntimeError do
      o.timer(Hash.new) { }
    end
  end

  def test_request_totals
    o = Fluent::MeasureOutput.new
    base_time = Time.now
    counter = Hash.new
    5.times do |i|
      time_i = base_time.to_i - i
      counter[time_i] = Hash.new
      ['piyo', 'hoge', 'fuga'].each {|tag| counter[time_i][tag] = i + 1}
    end

    expected = {"piyo"=>2, "hoge"=>2, "fuga"=>2}
    actual = o.request_totals(1, base_time, counter)
    assert_equal expected, actual
  end

  def test_clean_measure_buffer
    o = Fluent::MeasureOutput.new
    base_time = Time.now
    counter = Hash.new
    5.times do |i|
      time_i = base_time.to_i - i
      counter[time_i] = Hash.new
      ['piyo', 'hoge', 'fuga'].each {|tag| counter[time_i][tag] = i + 1}
    end

    expected = {
      base_time.to_i => {"piyo"=>1, "hoge"=>1, "fuga"=>1},
      (base_time - 1).to_i => {"piyo"=>2, "hoge"=>2, "fuga"=>2}
    }
    o.clean_measure_buffer(base_time, counter, 1)
    assert_equal expected, counter
  end
end
