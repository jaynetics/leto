module Leto
  def self.deep_freeze(obj, include_modules: false)
    call(obj) do |el|
      el.freeze if el.respond_to?(:freeze) &&
                   !el.frozen? &&
                   (include_modules || !el.is_a?(Module))
    end
  end

  def self.deep_print(obj, print_method: :inspect, indent: 4, show_path: true)
    call(obj) do |el, path|
      puts "#{' ' * path.count * indent}#{el.send(print_method)}" \
           "#{"  @ #{path.inspect}" if show_path}" \
           [0..78]
    end
    nil
  end

  def self.deep_eql?(obj1, obj2)
    call(obj1).to_a == call(obj2).to_a
  end

  def self.shared_mutable_state?(obj1, obj2)
    shared_mutables(obj1, obj2).any?
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
    shared_objects(obj1, obj2, filter: method(:mutable?))
  end

  def self.shared_objects(obj1, obj2, filter: nil)
    objects_with_path1 = call(obj1).map { |el, path| [el, path] }
    objects_with_path2 = call(obj2).map { |el, path| [el, path] }
    objects_with_path1.each.with_object([]) do |(el1, path1), acc|
      next if filter && !filter.call(el1)

      objects_with_path2.reject do |el2, path2|
        acc << [el1, path1, path2] if el1.equal?(el2)
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
    Integer,
    NilClass,
    Symbol,
    TrueClass,
  ].freeze
end
