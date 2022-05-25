# frozen_string_literal: true

RSpec.describe Nash do
  subject(:nash) { described_class.new(&:downcase) }

  describe '#normalize' do
    it 'returns a normalized version of the key' do
      expect(nash.normalize(:One)).to be :one
    end
  end

  describe '#store' do
    it 'sets a key' do
      nash.store(:one, 1)

      expect(nash[:one]).to be 1
    end

    it 'returns the set value' do
      expect(nash.store(:one, 1)).to be 1
    end

    it 'normalizes the key' do
      nash.store(:ONE, 1)

      expect(nash[:one]).to be 1
    end
  end

  describe '#[]' do
    it 'returns the set value' do
      nash[:one] = 1

      expect(nash[:one]).to be 1
    end

    it 'normalizes the key' do
      nash[:one] = 1

      expect(nash[:ONE]).to be 1
    end
  end

  describe '#to_hash' do
    it 'returns a hash with the original keys' do
      nash[:ONE] = 1
      nash[:Two] = 2

      result = nash.to_hash

      expect(result).to eql({ ONE: 1, Two: 2 })
      expect(result).to be_kind_of Hash
    end
  end

  describe '#inspect' do
    it 'displays like a regular hash using the original keys' do
      nash[:ONE] = 1
      nash[:Two] = 2

      expect(nash.inspect).to eq '{:ONE=>1, :Two=>2}'
    end
  end
end
