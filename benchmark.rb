require 'benchmark/ips'
require 'ice_nine'
require_relative 'lib/leto'

obj = (0..9).to_h { |n| [n, [{ false => true, sym: ('a'..'z').to_a.shuffle }]] }

Benchmark.ips do |x|
  x.report('Leto.deep_freeze')    { Leto.deep_freeze(obj) }
  x.report('IceNine.deep_freeze') { IceNine.deep_freeze(obj) }
  x.compare!
end; nil
