module Leto
  def self.dig(obj, steps)
    Leto::Path.new(start: obj, steps: steps).resolve
  end
end
