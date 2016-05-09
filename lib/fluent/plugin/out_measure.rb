require 'logger'

module Fluent
  class MeasureOutput < Output
    Plugin.register_output('measure', self)

    PRINT_FORMAT_EACH = "summary + %10d in %5ds = %10.3f/s Avg : %s"
    PRINT_FORMAT_ALL  = "summary = %10d in %5ds = %10.3f/s Avg"

    attr_accessor :logger

    config_param :path, :string, :default => nil
    config_param :verbose, :bool, :default => true
    config_param :expire, :integer, :default => 60 * 30

    # This method is called before starting.
    def configure(conf)
      super
      @logger = $log
      if !@path.nil?
        @logger = Logger.new("#{@path}", 'daily')
        @logger.formatter = proc{|severity, datetime, progname, message|
          "#{datetime} [measure]: #{message}\n"
        }
      end
    end

    def timer(arg, &proc)
      x = case arg
      when Numeric then arg
      when Time    then arg - Time.now
      when String  then Time.parse(arg) - Time.now
      else raise   end
      sleep x if block_given?
      yield
    end

    def print_measure_result(latest_time, next_time, counter = @counter, verbose = @verbose)
      time_range = next_time.to_i - latest_time.to_i
      # measure results in unit of tag
      tags_total = request_totals time_range, next_time, counter
      # sum of measure results
      total = 0
      tags_total.each{|tag, value|
        total += value
        @logger.info "#{sprintf(PRINT_FORMAT_EACH, value, time_range, value.quo(time_range).to_f, tag)}" if verbose
      }
      @logger.info "#{sprintf(PRINT_FORMAT_ALL, total, time_range, total.quo(time_range).to_f)}"
    end

    def request_totals(time_range, base_time, counter = @counter)
      rt = Hash.new
      time_range.times do |i|
        k = base_time.to_i - (i + 1)
        counter[k].each{|tag, value|
          rt[tag] = 0 unless rt.has_key?(tag)
          rt[tag] += value
        } unless counter[k].nil?
      end
      return rt
    end

    def clean_measure_buffer(base_time, counter = @counter, expire = @expire)
      t = base_time - expire
      # clean buffer
      counter.delete_if {|key, val| key < t.to_i }
    end

    # This method is called when starting.
    def start
      super
      @counter = Hash.new
      @t_print = Thread.new {
        interval = 60
        latest_time = Time.now
        next_time = latest_time + interval - latest_time.sec
        loop do
          timer(next_time) do
            print_measure_result latest_time, next_time
          end
          latest_time = next_time
          next_time += interval
        end
      }
      @t_clean = Thread.new {
        interval = 60
        latest_time = Time.now
        next_time = latest_time + interval - latest_time.sec + 10
        loop do
          timer(next_time) do
            clean_measure_buffer next_time
          end
          latest_time = next_time
          next_time += interval
        end
      }
    end

    # This method is called when shutting down.
    def shutdown
      Thread::kill(@t_print) unless @t_print.nil?
      Thread::kill(@t_clean) unless @t_clean.nil?
      super
    end

    def emit(tag, es, chain)
      chain.next
      es.each do |time, record|
        t = Time.now.to_i
        @counter[t] = Hash.new unless @counter.has_key?(t)
        @counter[t][tag] = 0 unless @counter[t].has_key?(tag)
        @counter[t][tag] += 1
      end
    end
  end
end
