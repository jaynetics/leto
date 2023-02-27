RSpec.describe Leto::Path do
  describe '#resolve' do
    it 'returns the sub-object at the given path' do
      obj, path = Leto.trace(deep_object).to_a.last
      expect(obj).to eq 'z'
      expect(path).to be_a Leto::Path
      expect(path.resolve).to equal obj
    end

    it 'returns the start object if there are no steps ' do
      expect(Leto::Path.new(start: :foo, steps: []).resolve).to eq :foo
    end
  end

  it 'has nice inspect/to_s output' do
    path = Leto::Path.new(start: :OBJ, steps: [[:[], 0], [:foo, :bar, :baz]])
    expect(path.inspect).to eq '#<Leto::Path :OBJ[0].foo(:bar, :baz)>'
  end
end
