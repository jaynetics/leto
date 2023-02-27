RSpec.describe Leto do
  describe '::dig' do
    it 'calls Leto::Path#resolve' do
      expect(Leto::Path)
        .to receive(:new).with(start: :OBJ, steps: :STEPS)
        .and_return(path = spy)
      expect(path).to receive(:resolve)
      Leto.dig(:OBJ, :STEPS)
    end
  end
end
