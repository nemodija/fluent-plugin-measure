module Fluent
  class MeasureOutput < Output
    Plugin.register_output('measure', self)

    PRINT_FORMAT_EACH = "summary + %10d in %5ds = %10.3f/s Avg : %s"
    PRINT_FORMAT_ALL  = "summary = %10d in %5ds = %10.3f/s Avg"

    config_param :path, :string, :default => nil
    config_param :verbose, :bool, :default => true

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

    def print_measure(s_time = Time.now)
      interval = 60
      next_time = s_time + interval
      loop do
        timer(next_time) do
          tmp_index = @date_index
          total_val = 0
          @date_index = next_time.strftime("%s")
          @counter[tmp_index].each{|key, value|
            total_val += value
            printer "#{sprintf(PRINT_FORMAT_EACH, value, interval, value.quo(interval).to_f, key)}" if @verbose
          }
          printer "#{sprintf(PRINT_FORMAT_ALL, total_val, interval, total_val.quo(interval).to_f)}"
          @counter.delete(tmp_index)
        end
        next_time += interval
      end
    end

    # This method is called when starting.
    def start
      super
      s_time = Time.now
      @date_index = s_time.strftime("%s")
      @counter = Hash.new

      @thread = Thread.new do
        print_measure s_time
      end
    end

    # This method is called when shutting down.
    def shutdown
      Thread::kill(@thread) unless @thread.nil?
      super
    end

    def emit(tag, es, chain)
      chain.next
      es.each do |time, record|
        @counter[@date_index] = Hash.new unless @counter.has_key?(@date_index)
        @counter[@date_index][tag] = 0 unless @counter[@date_index].has_key?(tag)
        @counter[@date_index][tag] += 1
      end
    end
  end
end
