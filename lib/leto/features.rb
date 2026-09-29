# feature detection code for ruby
module Leto
  def self.data_feature?
    defined?(Data) && Data.respond_to?(:define)
  end

  # Pre-Ruby-4.0, Hash-backed Sets are traversed through their
  # @hash instance variable and don't need custom handling.
  def self.set_feature?
    defined?(Set) && Set.respond_to?(:[]) && !Set[].instance_variable_defined?(:@hash)
  end
end
