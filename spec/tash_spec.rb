# frozen_string_literal: true

RSpec.describe Tash do
  subject(:tash) { described_class.new(&:downcase) }

  describe '.[]' do
    it 'fails if the number of inputs is odd' do
      expect do
        described_class[:a]
      end.to raise_error(ArgumentError).with_message("odd number of arguments for #{described_class}")
      expect do
        described_class[:a, 1, :b]
      end.to raise_error(ArgumentError).with_message("odd number of arguments for #{described_class}")
    end

    context 'without a block' do
      it "returns a new empty #{described_class}" do
        tash = described_class[]

        expect(tash).to be_a_kind_of described_class
        expect(tash.size).to be 0
      end

      context "with a #{described_class}" do
        it "returns a #{described_class} containing the keys of the other class" do
          tash[:A] = 1
          tash[:b] = 2

          tash2 = described_class[tash]

          expect(tash2).to eq tash
          expect(tash2).to_not be tash
        end

        it "copies over the transformation strategy from the provided #{described_class}" do
          tash[:A] = 1
          tash[:b] = 2

          tash2 = described_class[tash]
          tash2[:C] = 3

          expect(tash2[:c]).to be 3
        end
      end

      it 'works with a Hash' do
        hash = { A: 1, b: 2 }

        tash = described_class[hash]

        expect(tash).to be_a_kind_of described_class
        expect(tash[:A]).to be 1
        expect(tash[:b]).to be 2
        expect(tash.size).to be 2
      end

      it 'works with an even number of inputs' do
        tash = described_class[:A, 1, :b, 2]

        expect(tash).to be_a_kind_of described_class
        expect(tash[:A]).to be 1
        expect(tash[:b]).to be 2
        expect(tash.size).to be 2
      end
    end

    context 'with a block' do
      it "returns a new empty #{described_class}" do
        tash = described_class[&:downcase]

        expect(tash).to be_a_kind_of described_class
        expect(tash).to be_empty

        tash[:A] = 1

        expect(tash[:a]).to be 1
      end

      it "treats the #{described_class} like a Hash using to_hash" do
        tash[:A] = 1
        tash[:b] = 2

        tash2 = described_class[tash, &:downcase]

        expect(tash2[:a]).to be 1
        expect(tash2[:b]).to be 2
        expect(tash2.size).to be 2
      end

      it 'works with a Hash' do
        hash = { A: 1, b: 2 }

        tash = described_class[hash, &:downcase]

        expect(tash[:a]).to be 1
        expect(tash[:b]).to be 2
        expect(tash.size).to be 2
      end

      it 'works with an even number of inputs' do
        tash = described_class[:A, 1, :b, 2, &:downcase]

        expect(tash).to be_a_kind_of described_class
        expect(tash[:a]).to be 1
        expect(tash[:b]).to be 2
        expect(tash.size).to be 2
      end
    end
  end

  describe '.new' do
    context 'without a block' do
      it 'operates like a Hash' do
        tash = described_class.new
        tash[:A] = 1

        expect(tash[:A]).to be 1
      end
    end
  end

  describe '#==' do
    it "fails if the object is not a #{described_class}" do
      expect(tash == 1).to be false
    end

    it 'fails if the keys are different' do
      tash1 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
        end
      tash2 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:C] = 2
        end

      expect(tash1 == tash2).to be false
    end

    it 'fails if the values are different' do
      tash1 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
        end
      tash2 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 3
        end

      expect(tash1 == tash2).to be false
    end

    it 'fails if one is only a subset of the other' do
      tash1 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
          n[:C] = 3
        end
      tash2 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
        end

      expect(tash1 == tash2).to be false
    end

    it 'succeeds if it has the same keys and values' do
      tash1 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:A] = 1
          n[:B] = 2
        end
      tash2 = described_class
        .new(&:downcase)
        .tap do |n|
          n[:b] = 2
          n[:a] = 1
        end

      expect(tash1 == tash2).to be true
    end
  end

  describe '#[]' do
    it 'returns the set value' do
      tash[:one] = 1

      expect(tash[:one]).to be 1
    end

    it 'transforms the key' do
      tash[:one] = 1

      expect(tash[:ONE]).to be 1
    end
  end

  describe '#[]=' do
    it 'sets a key' do
      tash[:a] = 1

      expect(tash[:a]).to be 1
    end

    it 'returns the set value' do
      expect(tash[:a] = 1).to be 1
    end

    it 'transforms the key' do
      tash[:A] = 1

      expect(tash[:a]).to be 1
    end
  end

  describe '#assoc' do
    it 'returns nil if no key is found' do
      expect(tash.assoc(:a)).to be_nil
    end

    it 'returns a key-value pair if the key is found' do
      tash[:a] = 1

      expect(tash.assoc(:a)).to eql [:a, 1]
    end

    it 'transforms the key' do
      tash[:A] = 1

      expect(tash.assoc(:a)).to eql [:a, 1]
    end
  end

  describe '#clear' do
    it 'emptys the tash' do
      tash[:A] = 1
      tash[:b] = 2

      expect(tash.clear).to be_empty
    end

    it 'returns itself' do
      expect(tash.clear).to be tash
    end
  end

  describe '#compact' do
    it 'removes keys with nil values' do
      tash[:A] = 1
      tash[:b] = nil

      result = tash.compact

      expect(result).to be_a_kind_of described_class
      expect(result).to eq described_class[a: 1]
    end
  end

  describe '#compact!' do
    it 'returns self if compaction occurred' do
      tash[:A] = 1
      tash[:b] = nil

      expect(tash.compact!).to eq described_class[a: 1]
    end

    it 'returns nil if compaction did not occur' do
      tash[:A] = 1
      tash[:b] = 2

      expect(tash.compact!).to be_nil
    end
  end

  describe '#delete' do
    context 'without a block' do
      it 'returns the value related to the transformed key if found' do
        tash[:A] = 1

        expect(tash.delete(:a)).to be 1
      end

      it 'returns nil if the key is not found' do
        expect(tash.delete(:does_not_exist)).to be_nil
      end
    end

    context 'with a block' do
      it 'provides the transformed key to the block' do
        expect(tash.delete(:DOES_NOT_EXIST) { |k| k == :does_not_exist }).to be true
      end

      it 'returns the value related to the transformed key if found' do
        tash[:A] = 1

        expect(tash.delete(:a) { 2 }).to be 1
      end

      it 'returns the value of the block if the transformed key is not found' do
        expect(tash.delete(:does_not_exist) { 1 }).to be 1
      end
    end
  end

  describe '#each' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.each).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'enumerates each key-value pair' do
        tash[:A] = 1
        tash[:b] = 2

        output = []
        tash.each do |k, v|
          output << [k, v]
        end

        expect(output).to eql [
          [:a, 1],
          [:b, 2]
        ]
      end

      it 'returns itself' do
        result = tash.each do |k, v|
          # noop
        end

        expect(result).to be tash
      end
    end
  end

  describe '#select' do
    context 'without a block' do
      it 'returns an enumerator' do
        tash[:A] = 1
        tash[:b] = 2

        expect(tash.select).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it "select the #{described_class} and returns a new one" do
        tash[:A] = 1
        tash[:b] = 2

        result = tash.select { |_k, v| v.even? }

        expect(result).to be_a_kind_of described_class
        expect(result).to eq described_class[b: 2]
      end
    end
  end

  describe '#key?' do
    it 'transforms the key' do
      tash[:A] = 1

      expect(tash.key?(:a)).to be true
    end
  end
end
