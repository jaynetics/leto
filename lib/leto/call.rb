module Leto
  LEAKY_PROCESS_TMS = RUBY_VERSION.to_f <= 2.7

  def self.call(obj, &block)
    return enum_for(__method__, obj) unless block_given?

    seen = {}.tap(&:compare_by_identity)
    seen[Process::Tms] = true if LEAKY_PROCESS_TMS
    path = block.arity == 2 ? Path.new(start: obj) : nil
    traverse(obj, path, seen, block)
    obj
  end

  def self.traverse(obj, path, seen, block)
    return if seen[obj]

    seen[obj] = true

    path ? block.call(obj, path) : block.call(obj)

    obj.instance_variables.each do |ivar_name|
      traverse(
        obj.instance_variable_get(ivar_name),
        path&.+([[:instance_variable_get, ivar_name]]),
        seen, block
      )
    end

    case obj
    when Hash
      obj.keys.each_with_index do |k, i|
        traverse(k, path&.+([[:keys], [:[], i]]), seen, block)
        traverse(obj[k], path&.+([[:[], k]]), seen, block)
      end
    when Module
      obj.class_variables.each do |cvar_name|
        traverse(
          obj.class_variable_get(cvar_name),
          path&.+([[:class_variable_get, cvar_name]]),
          seen, block
        )
      end
      obj.constants.each do |const_name|
        traverse(
          obj.const_get(const_name),
          path&.+([[:const_get, const_name]]),
          seen, block
        )
      end
    when Range
      traverse(obj.begin, path&.+([[:begin]]), seen, block)
      traverse(obj.end,   path&.+([[:end]]), seen, block)
    when Struct
      obj.members.each do |member|
        traverse(obj[member], path&.+([[:[], member]]), seen, block)
      end
    when Enumerable
      obj.each_with_index do |el, idx|
        traverse(el, path&.+([[:[], idx]]), seen, block)
      end
    end
  end
  private_class_method :traverse
end
