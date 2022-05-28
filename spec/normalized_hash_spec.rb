# frozen_string_literal: true

RSpec.describe Nash do
  subject(:nash) { described_class.new(&:downcase) }

  describe '#normalize' do
    it 'returns a normalized version of the key' do
      expect(nash.normalize(:A)).to be :a
    end
  end

  describe '#==' do
    it "fails if the object is not a #{described_class}" do
      expect(nash == 1).to be false
    end

    it 'fails if the normalized keys are different' do
      nash1 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
        end
      nash2 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:C] = 2
        end

      expect(nash1 == nash2).to be false
    end

    it 'fails if the values are different' do
      nash1 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
        end
      nash2 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 3
        end

      expect(nash1 == nash2).to be false
    end

    it 'fails if one is only a subset of the other' do
      nash1 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
          n[:C] = 3
        end
      nash2 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
        end

      expect(nash1 == nash2).to be false
    end

    it 'succeeds if it has the same normalized keys and values' do
      nash1 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
        end
      nash2 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:b] = 2
          n[:a] = 1
        end

      expect(nash1 == nash2).to be true
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

        expect(nash.each).to be_a_kind_of Enumerator
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

  describe '#filter' do
    context 'without a block' do
      it 'returns an enumerator' do
        nash[:ONE] = 1
        nash[:Two] = 2

        expect(nash.filter).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it "filters the #{described_class} and returns a new one" do
        nash[:ONE] = 1
        nash[:Two] = 2

        result = nash.filter { |_k, v, _nk| v.even? }
        comparison = described_class.new(&:downcase)
        comparison[:Two] = 2

        expect(result).to be_a_kind_of described_class
        expect(result).to eq comparison
      end
    end
  end

  describe '#has_key?' do
    it 'normalizes the key' do
      nash[:A] = 1

      expect(nash.has_key?(:a)).to be true # rubocop:disable Style/PreferredHashMethods
    end
  end

  describe '#inspect' do
    it 'displays like a regular hash using the original keys' do
      nash[:A] = 1
      nash[:b] = 2

      expect(nash.inspect).to eq '{:A=>1, :b=>2}'
    end
  end

  describe '#keys' do
    it 'returns the original keys' do
      nash[:A] = 1
      nash[:b] = 2

      expect(nash.keys).to eq %i[A b]
    end
  end

  describe '#store' do
    it 'sets a key' do
      nash.store(:a, 1)

      expect(nash[:a]).to be 1
    end

    it 'returns the set value' do
      expect(nash.store(:a, 1)).to be 1
    end

    it 'normalizes the key' do
      nash.store(:A, 1)

      expect(nash[:a]).to be 1
    end
  end

  describe '#to_hash' do
    it 'returns a hash with the original keys' do
      nash[:A] = 1
      nash[:b] = 2

      result = nash.to_hash

      expect(result).to eql({ A: 1, b: 2 })
      expect(result).to be_a_kind_of Hash
    end
  end

  describe '#values' do
    it 'returns the value' do
      nash[:A] = 1
      nash[:b] = 2

      expect(nash.values).to eq [1, 2]
    end
  end
end
