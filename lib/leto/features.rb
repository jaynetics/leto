# feature detection code for ruby
module Leto
  def self.data_feature?
    defined?(Data) && Data.respond_to?(:define)
  end

  def self.set_feature?
    defined?(Set) && Set.respond_to?(:[])
  end
end
