# Light wrapper around Array, mostly for nicer display.
module Leto
  class Path
    include Enumerable

    attr_reader :start, :steps

    def initialize(start:, steps: [])
      @start = start
      @steps = steps
    end

    def each(&block)
      steps.each(&block)
    end

    def +(other)
      self.class.new(start: start, steps: steps + other.to_a)
    end

    def resolve
      steps.inject(start) do |obj, (method, *args)|
        obj&.send(method, *args) or break obj
      rescue StandardError => e
        warn "#{__method__}: #{e.class} #{e.message}"
      end
    end

    def ==(other)
      other.to_a == steps
    end

    def inspect
      start_str = start.inspect
      start_str = "#{start_str[0..38]}…#{start_str[-1]}" if start_str.size > 40
      [
        "#<#{self.class} #{start_str}",
        steps.map do |method, *args|
          args_str = args.map(&:inspect).join(', ')
          if method == :[]
            "[#{args_str}]"
          else
            ".#{method}#{"(#{args_str})" unless args_str.empty?}"
          end
        end,
        ">"
      ].join
    end
    alias to_s inspect
  end
end
