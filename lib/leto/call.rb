module Leto
  def self.call(obj, max_depth: nil, path: nil, &block)
    block_given? or return enum_for(__method__, obj, max_depth: max_depth, path: path)

    traverse(obj, path, 0, max_depth, build_seen_hash, block)
    obj
  end

  def self.trace(obj, max_depth: nil, path: nil, &block)
    block_given? or return enum_for(__method__, obj, max_depth: max_depth, path: path)

    call(obj, max_depth: max_depth, path: path || Path.new(start: obj), &block)
  end

  def self.traverse(obj, path, depth, max_depth, seen, block)
    return if seen[obj] || max_depth&.<(depth)

    seen[obj] = true
    depth += 1

    path ? block.call(obj, path) : block.call(obj)

    obj.instance_variables.each do |ivar_name|
      traverse(
        obj.instance_variable_get(ivar_name),
        path&.+([[:instance_variable_get, ivar_name]]),
        depth, max_depth, seen, block
      )
    end

    case obj
    when Hash
      obj.keys.each_with_index do |k, i|
        traverse(k, path&.+([[:keys], [:[], i]]), depth, max_depth, seen, block)
        traverse(obj[k], path&.+([[:[], k]]), depth, max_depth, seen, block)
      end
    when Module
      obj.class_variables.each do |cvar_name|
        traverse(
          obj.class_variable_get(cvar_name),
          path&.+([[:class_variable_get, cvar_name]]),
          depth, max_depth, seen, block
        )
      end
      obj.constants.each do |const_name|
        traverse(
          obj.const_get(const_name),
          path&.+([[:const_get, const_name]]),
          depth, max_depth, seen, block
        )
      end
    when Range
      traverse(obj.begin, path&.+([[:begin]]), depth, max_depth, seen, block)
      traverse(obj.end,   path&.+([[:end]]), depth, max_depth, seen, block)
    when Struct
      obj.members.each do |member|
        traverse(obj[member], path&.+([[:[], member]]), depth, max_depth, seen, block)
      end
    when Enumerable
      obj.each_with_index do |el, idx|
        traverse(el, path&.+([[:[], idx]]), depth, max_depth, seen, block)
      end
    end
  end
  private_class_method :traverse

  if RUBY_VERSION.to_f > 2.7
    def self.build_seen_hash
      {}.tap(&:compare_by_identity)
    end
  else
    # ignore leaky constants in old rubies
    def self.build_seen_hash
      hash = {}.tap(&:compare_by_identity)
      hash[::Etc::Group] = true if defined?(::Etc::Group)
      hash[::Etc::Passwd] = true if defined?(::Etc::Passwd)
      hash[::Process::Tms] = true if defined?(::Process::Tms)
      hash
    end
  end
end
