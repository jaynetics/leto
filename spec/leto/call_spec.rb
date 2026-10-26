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

    it 'supports Hash#default' do
      hash = Hash.new(:my_default)
      expect(Leto.call(hash).to_a).to eq [hash, :my_default]
      Leto.trace(hash) { |el, path| expect(path.resolve).to equal el }
    end

    it 'supports Hash#default_proc' do
      hash = Hash.new { :my_default }
      expect(Leto.call(hash).to_a).to match [hash, instance_of(Proc)]
      Leto.trace(hash) { |el, path| expect(path.resolve).to equal el }
    end

    it 'supports Data', if: Leto.data_feature? do
      model = Data.define(:foo, :bar)
      record = model.new(23, [42])
      expect(Leto.call(record).to_a).to eq [record, 23, [42], 42]
      Leto.trace(record) { |el, path| expect(path.resolve).to equal el }
    end

    it 'supports Set', if: Leto.set_feature? do
      set = Set[['nested'], Set[42]]
      expect(Leto.call(set).to_a).to eq [set, ['nested'], 'nested', Set[42], 42]
      Leto.trace(set) { |el, path| expect(path.resolve).to equal el }
    end

    require 'ostruct'
    it 'supports OpenStruct' do
      os = OpenStruct.new(foo: 'bar') # rubocop:disable Style/OpenStructUse
      expect(Leto.call(os).to_a).to eq [os, { foo: 'bar' }, :foo, 'bar']
      Leto.trace(os) { |el, path| expect(path.resolve).to equal el }
    end

    it 'supports Complex' do
      complex = Complex(1, 2)
      expect(Leto.call(complex).to_a).to eq [complex, 1, 2]
      Leto.trace(complex) { |el, path| expect(path.resolve).to equal el }
    end

    it 'supports Rational' do
      rational = Rational(1, 2)
      expect(Leto.call(rational).to_a).to eq [rational, 1, 2]
      Leto.trace(rational) { |el, path| expect(path.resolve).to equal el }
    end

    it 'supports custom Time zones', if: RUBY_VERSION.to_f >= 2.6 do
      timezone_class = Class.new do
        def local_to_utc(time); time end
        def utc_to_local(time); time end
      end
      zone = timezone_class.new
      zone.instance_variable_set(:@name, 'custom')
      time = Time.new(2020, 1, 1, 0, 0, 0, zone)
      expect(Leto.call(time).to_a).to eq [time, zone, 'custom']
      Leto.trace(time) { |el, path| expect(path.resolve).to equal el }
    end

    it 'supports Time without a zone' do
      time = Time.new(2020, 1, 1, 0, 0, 0, '+02:00')
      expect(Leto.call(time).to_a).to eq [time]
    end

    describe 'Exception support' do
      it 'supports Exception' do
        exception = RuntimeError.new('message')
        exception.set_backtrace(['trace'])
        expect(Leto.call(exception).to_a).to eq [
          exception, exception.message, exception.backtrace, 'trace'
        ]
        Leto.trace(exception) { |el, path| expect(path.resolve).to equal el }
      end

      it 'supports exception causes and backtrace locations' do
        begin
          raise 'cause'
        rescue RuntimeError
          raise 'outer'
        end
      rescue RuntimeError => e
        objects = Leto.call(e).to_a
        expect(objects).to include(e.cause)
        expect(objects).to include(*e.backtrace_locations)
        Leto.trace(e) { |el, path| expect(path.resolve).to equal el }
      end

      it 'supports NameError' do
        exception = NameError.new('message', :name, receiver: ['receiver'])
        expect(Leto.call(exception).to_a).to eq [
          exception, exception.message, :name, exception.receiver, 'receiver'
        ]
        Leto.trace(exception) { |el, path| expect(path.resolve).to equal el }
      end

      it 'supports NoMethodError' do
        exception = NoMethodError.new('message', :name, ['arg'], receiver: [])
        expect(Leto.call(exception).to_a).to eq [
          exception, exception.message, :name, exception.receiver,
          exception.args, 'arg'
        ]
        Leto.trace(exception) { |el, path| expect(path.resolve).to equal el }
      end

      it 'supports KeyError' do
        exception = KeyError.new('message', key: ['key'], receiver: {})
        expect(Leto.call(exception).to_a).to eq [
          exception, exception.message, exception.receiver, exception.key, 'key'
        ]
        Leto.trace(exception) { |el, path| expect(path.resolve).to equal el }
      end

      it 'supports UncaughtThrowError' do
        exception = UncaughtThrowError.new(:tag, ['value'], 'message')
        expect(Leto.call(exception).to_a).to eq [
          exception, exception.message, :tag, exception.value, 'value'
        ]
        Leto.trace(exception) do |el, path|
          # UncaughtThrowError formats a new message string on every call.
          if path.steps == [[:message]]
            expect(path.resolve).to eq el
          else
            expect(path.resolve).to equal el
          end
        end
      end

      it 'supports NoMatchingPatternKeyError', if: defined?(NoMatchingPatternKeyError) do
        exception = NoMatchingPatternKeyError.new('message', matchee: [], key: :key)
        expect(Leto.call(exception).to_a).to eq [
          exception, exception.message, :key, exception.matchee
        ]
        Leto.trace(exception) { |el, path| expect(path.resolve).to equal el }
      end

      it 'supports exceptions without optional fields' do
        [Exception, NameError, NoMethodError, KeyError].each do |klass|
          exception = klass.new('message')
          expect(Leto.call(exception).to_a).to eq [exception, exception.message]
        end
      end

      it 'supports exception status, signals, and error numbers' do
        [SystemExit.new(2, 'exit'), SignalException.new('TERM'), Errno::ENOENT.new].each do |exception|
          method = %i[status signo errno].find { |name| exception.respond_to?(name) }
          expect(Leto.call(exception).to_a).to include(exception.send(method))
          Leto.trace(exception) { |el, path| expect(path.resolve).to equal el }
        end
      end
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
