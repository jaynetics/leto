module Leto
  def self.deep_freeze(obj, include_modules: false)
    call(obj) do |el|
      el.freeze if el.respond_to?(:freeze) &&
                   !el.frozen? &&
                   (include_modules || !el.is_a?(Module))
    end
  end

  def self.deep_print(obj, print_method: :inspect, indent: 4, show_path: true)
    trace(obj) do |el, path|
      puts "#{' ' * path.count * indent}#{el.send(print_method)}" \
           "#{"  @ #{path.inspect}" if show_path}" \
           [0..78]
    end
    nil
  end

  def self.deep_eql?(obj1, obj2)
    call(obj1).to_a == call(obj2).to_a
  end

  def self.deep_dup(obj, include_modules: false)
    return obj if IMMUTABLE_CLASSES.include?(obj.class) || !duplicable?(obj) ||
                  (!include_modules && obj.is_a?(Module))

    copy = obj.dup

    trace(obj, max_depth: 1).each do |el, path|
      method, *args = path.steps[0]
      case method
      when :instance_variable_get
        copy.instance_variable_set(*args, deep_dup(el, include_modules: include_modules))
      when :[]
        copy[*args] = deep_dup(el, include_modules: include_modules)
      when :send # Data
        copy = copy.with(args[0] => deep_dup(el, include_modules: include_modules))
      when :begin
        return Range.new(deep_dup(obj.begin), deep_dup(obj.end), obj.exclude_end?)
      end
    end

    copy
  end

  def self.shared_mutable_state?(obj1, obj2)
    each_shared_object(obj1, obj2, filter: method(:mutable?)).any?
  end

  # returns [[shared_object, path1, path2], ...], e.g.:
  # str1 = 'foo'.dup
  # str2 = 'bar'.dup
  # shared_mutables([str1, str2], [str2, str1]) # =>
  # [
  #   ["foo", [[:[], 0]], [[:[], 1]]],
  #   ["bar", [[:[], 1]], [[:[], 0]]]
  # ]
  def self.shared_mutables(obj1, obj2)
    each_shared_object(obj1, obj2, filter: method(:mutable?)).to_a
  end

  def self.shared_objects(obj1, obj2, filter: nil)
    each_shared_object(obj1, obj2, filter: filter).to_a
  end

  def self.each_shared_object(obj1, obj2, filter: nil)
    block_given? or return enum_for(__method__, obj1, obj2, filter: filter)

    obj2_els_with_path = trace(obj2).to_a
    trace(obj1).each do |el1, path1|
      next if filter && !filter.call(el1)

      obj2_els_with_path.reject do |el2, path2|
        yield(el1, path1, path2) if el1.equal?(el2)
      end
    end
  end

  def self.mutable?(obj)
    !IMMUTABLE_CLASSES.include?(obj.class) && !obj.frozen?
  end
  private_class_method :mutable?

  IMMUTABLE_CLASSES = [
    FalseClass,
    Float,
    if defined?(Integer)
      Integer
    else
      Fixnum # rubocop:disable Lint/UnifiedInteger for Ruby < 2.4
    end,
    NilClass,
    Symbol,
    TrueClass,
  ].freeze

  def self.duplicable?(obj)
    !NON_DUPLICABLE_CLASSES.include?(obj.class) && obj.respond_to?(:dup)
  end
  private_class_method :duplicable?

  require 'singleton'

  NON_DUPLICABLE_CLASSES = [
    Method,
    Singleton,
    UnboundMethod
  ].freeze
end
