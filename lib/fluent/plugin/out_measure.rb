module Fluent
  class MeasureOutput < Output
    Plugin.register_output('measure', self)

    PRINT_FORMAT_EACH = "summary + %10d in %5ds = %10.3f/s Avg : %s"
    PRINT_FORMAT_ALL  = "summary = %10d in %5ds = %10.3f/s Avg"

    config_param :path, :string, :default => nil
    config_param :verbose, :bool, :default => true
    config_param :expire, :integer, :default => 60 * 30

    # This method is called before starting.
    def configure(conf)
      super
      @enabled_path = @path.nil? ? false : FileTest.exist?(File.dirname(@path))
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

    def printer(message)
      if @enabled_path
        File.open(@path, 'a') {|f| f.write "#{Time.now} [measure]: #{message}\n" }
      else
        $log.info message
      end
    end

    def print_measure(counter = @counter)
      interval = 60
      s_time = Time.now
      next_time = s_time + interval - s_time.sec

      loop do
        $log.debug "next measure time [#{next_time}]"
        timer(next_time) do
          latency = next_time.to_i - s_time.to_i
          $log.debug "measure range [#{s_time} - #{next_time - 1}]"

          # measure in unit of tag
          tags_total_val = Hash.new
          latency.times do |i|
            k = s_time.to_i + i
            counter[k].each{|tag, value|
              tags_total_val[tag] = 0 unless tags_total_val.has_key?(tag)
              tags_total_val[tag] += value
            } unless counter[k].nil?
          end

          # sum of measure results
          total_val = 0
          tags_total_val.each{|tag, value|
            total_val += value
            printer "#{sprintf(PRINT_FORMAT_EACH, value, latency, value.quo(latency).to_f, tag)}" if @verbose
          }
          printer "#{sprintf(PRINT_FORMAT_ALL, total_val, latency, total_val.quo(latency).to_f)}"
        end
        s_time = next_time
        next_time += interval
      end
    end

    def expire_measure_history(expire = @expire, counter = @counter)
      interval = 60
      s_time = Time.now
      next_time = s_time + interval - s_time.sec + 10

      loop do
        $log.debug "next buffer clean time [#{next_time}]"
        timer(next_time) do
          t = next_time - expire
          $log.debug "expire time less than [#{t}]"

          # clean buffer
          counter.delete_if {|key, val| key < t.to_i }
        end
        next_time += interval
      end
    end

    # This method is called when starting.
    def start
      super
      @counter   = Hash.new
      @t_measure = Thread.new { print_measure }
      @t_expire  = Thread.new { expire_measure_history }
    end

    # This method is called when shutting down.
    def shutdown
      Thread::kill(@t_measure) unless @t_measure.nil?
      Thread::kill(@t_expire)  unless @t_expire.nil?
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
