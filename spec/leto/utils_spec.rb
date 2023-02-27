RSpec.describe Leto do
  specify '::deep_freeze' do
    obj = { 'a'.dup => ['b'.dup, ('c'.dup)..('d'.dup)] }

    Leto.deep_freeze(obj)

    expect(obj).to be_frozen
    expect(obj.keys.first).to be_frozen
    expect(obj['a']).to be_frozen
    expect(obj['a'][0]).to be_frozen
    expect(obj['a'][1]).to be_frozen
    expect(obj['a'][1].begin).to be_frozen
    expect(obj['a'][1].end).to be_frozen
  end

  specify '::deep_print' do
    expect { Leto.deep_print(deep_object) }.to output.to_stdout
  end

  specify '::deep_eql?' do
    expect(Leto.deep_eql?(deep_object, deep_object)).to eq true

    obj1 = struct_class.new(:foobar)
    obj2 = struct_class.new(:foobar)
    expect(Leto.deep_eql?(obj1, obj2)).to eq true

    obj1.instance_variable_set(:@different, :thingy)
    expect(Leto.deep_eql?(obj1, obj2)).to eq false
  end

  specify '::deep_dup' do
    klass = Struct.new(:foo) { attr_accessor(:bar) }
    orig = klass.new(['foo', { bar: ['baz', 'BEG'..'END'] }])
    orig.bar = 'qux'
    orig_cv = ['x', 'y', 'z']
    klass.class_variable_set(:@@cv, orig_cv) # rubocop:disable Style/ClassVars

    copy = Leto.deep_dup(orig)

    expect(copy.class).to equal klass
    expect(klass.class_variable_get(:@@cv)).to equal orig_cv

    expect_dup = ->(proc) do
      expect(proc.call(copy)).to eq(proc.call(orig))
      expect(proc.call(copy)).not_to equal(proc.call(orig))
    end

    expect_dup.call(->(orig_or_copy) { orig_or_copy })
    expect_dup.call(->(orig_or_copy) { orig_or_copy.foo })
    expect_dup.call(->(orig_or_copy) { orig_or_copy.foo[0] })
    expect_dup.call(->(orig_or_copy) { orig_or_copy.foo[1] })
    expect_dup.call(->(orig_or_copy) { orig_or_copy.foo[1].values[0] })
    expect_dup.call(->(orig_or_copy) { orig_or_copy.foo[1].values[0][0] })
    expect_dup.call(->(orig_or_copy) { orig_or_copy.foo[1].values[0][1] })
    expect_dup.call(->(orig_or_copy) { orig_or_copy.foo[1].values[0][1].begin })
    expect_dup.call(->(orig_or_copy) { orig_or_copy.foo[1].values[0][1].end })

    recursive = []
    recursive << recursive
    copy = Leto.deep_dup(recursive)
    expect(copy).to eq recursive
    expect(copy).not_to equal recursive
  end

  specify '::shared_mutable_state?' do
    obj1 = struct_class.new(:foobar)
    obj2 = struct_class.new(:foobar)
    obj1.instance_variable_set(:@immutable, :thingy)
    expect(Leto.shared_mutable_state?(obj1, obj2)).to eq false

    string = 'stringy'.dup
    obj1.instance_variable_set(:@mutable1, string)
    expect(Leto.shared_mutable_state?(obj1, obj2)).to eq false

    obj2.instance_variable_set(:@mutable2, string)
    expect(Leto.shared_mutable_state?(obj1, obj2)).to eq true
  end

  specify '::shared_mutables' do
    immutable = :immutable
    expect(Leto.shared_mutables([immutable], [immutable])).to eq []

    str1 = 'str1'.dup
    str2 = 'str2'.dup
    expect(Leto.shared_mutables(str1, str1)).to eq [
      ["str1", [], []]
    ]
    expect(Leto.shared_mutables([str1, str2], [str2, str1])).to eq [
      ["str1", [[:[], 0]], [[:[], 1]]],
      ["str2", [[:[], 1]], [[:[], 0]]]
    ]
  end

  specify '::shared_objects' do
    expect(Leto.shared_objects(1, 2)).to eq []
    expect(Leto.shared_objects(2, 2)).to eq [
      [2, [], []]
    ]
    expect(Leto.shared_objects([1, 2], [2, 3])).to eq [
      [2, [[:[], 1]], [[:[], 0]]]
    ]
  end
end
