RSpec.describe Leto do
  let(:deep_object_objects) do
    [
      deep_object,
      deep_object[0],
      deep_object[0].keys[0],
      deep_object[0].values[0],
      deep_object[0].values[0].instance_variable_get(:@ivar),
      deep_object[0].values[0].instance_variable_get(:@ivar)[0],
      deep_object[0].values[0].instance_variable_get(:@ivar)[0].keys[0],
      deep_object[0].values[0].instance_variable_get(:@ivar)[0].values[0],
      deep_object[0].values[0].instance_variable_get(:@ivar)[1],
      deep_object[0].values[0].instance_variable_get(:@ivar)[1].class_variable_get(:@@cv),
      deep_object[0].values[0].instance_variable_get(:@ivar)[1]::CONSTANT,
      deep_object[0].values[0][:foo],
      deep_object[0].values[0][:foo].begin,
      deep_object[0].values[0][:foo].end,
    ]
  end

  describe '::call' do
    it "it yields all associated objects" do
      expect { |block| Leto.call(deep_object, &block) }
        .to yield_successive_args(*deep_object_objects)
    end

    it "can be called without a block" do
      enum = Leto.call(deep_object)
      expect(enum).to be_an Enumerator
      expect(enum.to_a).to eq deep_object_objects
    end

    it "is unfazed by circularity" do
      obj = Object.new
      obj.instance_variable_set(:@obj, obj)
      expect(Leto.call(obj).to_a).to eq [obj]
    end

    it 'supports Data', if: defined?(Data) && Data.respond_to?(:define) do
      model = Data.define(:foo, :bar)
      record = model.new(23, [42])
      expect(Leto.call(record).to_a).to eq [record, 23, [42], 42]
    end
  end

  describe '::trace' do
    it 'yields the (sub-)objects along with their pathes' do
      expect { |block| Leto.trace(['foo'], &block) }.to yield_successive_args(
        [["foo"], []],
        ["foo",   [[:[], 0]]]
      )
    end

    it 'can be called without a block' do
      result = Leto.trace(['foo']).to_a
      expect(result).to eq [
        [["foo"], []],
        ["foo",   [[:[], 0]]]
      ]
    end
  end
end
