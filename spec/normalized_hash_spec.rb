# frozen_string_literal: true

RSpec.describe Nash do
  subject(:nash) { described_class.new(&:downcase) }

  describe '#normalize' do
    it 'returns a normalized version of the key' do
      expect(nash.normalize(:One)).to be :one
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

  describe '#each' do
    context 'without a block' do
      it 'returns an enumerator' do
        nash[:ONE] = 1
        nash[:Two] = 2

        expect(nash.each).to be_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'enumerates each original key, value, normalized key group' do
        nash[:ONE] = 1
        nash[:Two] = 2

        output = []
        nash.each do |k, v, nk|
          output << [k, v, nk]
        end

        expect(output).to eql [
          [:ONE, 1, :one],
          [:Two, 2, :two]
        ]
      end
    end
  end

  describe '#has_key?' do
    it 'normalizes the key' do
      nash[:ONE] = 1

      expect(nash.has_key?(:one)).to be true # rubocop:disable Style/PreferredHashMethods
    end
  end

  describe '#inspect' do
    it 'displays like a regular hash using the original keys' do
      nash[:ONE] = 1
      nash[:Two] = 2

      expect(nash.inspect).to eq '{:ONE=>1, :Two=>2}'
    end
  end

  describe '#keys' do
    it 'returns the original keys' do
      nash[:ONE] = 1
      nash[:Two] = 2

      expect(nash.keys).to eq %i[ONE Two]
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

  describe '#to_hash' do
    it 'returns a hash with the original keys' do
      nash[:ONE] = 1
      nash[:Two] = 2

      result = nash.to_hash

      expect(result).to eql({ ONE: 1, Two: 2 })
      expect(result).to be_kind_of Hash
    end
  end
end
