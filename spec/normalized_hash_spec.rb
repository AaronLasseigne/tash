# frozen_string_literal: true

RSpec.describe Nash do
  subject(:nash) { described_class.new(&:downcase) }

  describe '.new' do
    context 'without a block' do
      it 'operates like a Hash' do
        nash = described_class.new
        nash[:A] = 1

        expect(nash[:A]).to be 1
      end
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

  describe '#clear' do
    it 'emptys the nash' do
      nash[:A] = 1
      nash[:b] = 2

      expect(nash.clear).to be_empty
    end

    it 'returns itself' do
      expect(nash.clear).to be nash
    end
  end

  describe '#each' do
    context 'without a block' do
      it 'returns an enumerator' do
        nash[:A] = 1
        nash[:b] = 2

        expect(nash.each).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'enumerates each key and value pair' do
        nash[:A] = 1
        nash[:b] = 2

        output = []
        nash.each do |k, v|
          output << [k, v]
        end

        expect(output).to eql [
          [:a, 1],
          [:b, 2]
        ]
      end

      it 'returns itself' do
        result = nash.each do |k, v|
          # noop
        end

        expect(result).to be nash
      end
    end
  end

  describe '#filter' do
    context 'without a block' do
      it 'returns an enumerator' do
        nash[:A] = 1
        nash[:b] = 2

        expect(nash.filter).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it "filters the #{described_class} and returns a new one" do
        nash[:A] = 1
        nash[:b] = 2

        result = nash.filter { |_k, v| v.even? }
        comparison = described_class.new(&:downcase)
        comparison[:b] = 2

        expect(result).to be_a_kind_of described_class
        expect(result).to eq comparison
      end

      it 'dups the IR data so the values are no longer tied together' do
        nash[:A] = 1
        nash[:b] = 2

        result = nash.filter { |_k, v| v.even? }

        nash[:b] = 3

        expect(nash[:b]).to be 3
        expect(result[:b]).to be 2
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
    it 'displays like a regular hash using the normalized keys' do
      nash[:A] = 1
      nash[:b] = 2

      expect(nash.inspect).to eq '{:a=>1, :b=>2}'
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
    it 'returns a hash with the normalized keys' do
      nash[:A] = 1
      nash[:b] = 2

      result = nash.to_hash

      expect(result).to be_a_kind_of Hash
      expect(result).to eql({ a: 1, b: 2 })
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
