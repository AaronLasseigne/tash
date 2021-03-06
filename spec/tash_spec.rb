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

        it "copies over the transform strategy from the provided #{described_class}" do
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
          n[:b] = 2.0
          n[:a] = 1.0
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

  describe '#compare_by_identity' do
    it 'returns itself' do
      expect(tash.compare_by_identity).to be tash
    end
  end

  describe '#deconstruct_keys' do
    context 'when given nil' do
      it 'returns an empty hash' do
        tash[:A] = 1
        tash[:b] = 2

        expect(tash.deconstruct_keys(nil)).to eql({})
      end
    end

    context 'when given keys' do
      it 'transforms the keys' do
        tash[:A] = 1
        tash[:b] = 2

        result =
          case tash
          in { A: a, B: 2 }
            a
          else
            nil
          end

        expect(result).to eq tash[:a]
      end
    end
  end

  describe '#default' do
    context 'without a key' do
      it 'returns the default value' do
        tash.default = :default
        expect(tash.default).to be :default
      end
    end

    context 'with a key' do
      it 'returns the default value for that key' do
        tash[:Foo] = 0
        tash.default_proc = ->(t, k) { t[k] = "No key #{k}" }

        expect(tash.default(:FOO)).to eql 'No key foo'
      end
    end

    context 'with too many arguments' do
      it 'throws an ArgumentError' do
        expect { tash.default(1, 2) }.to raise_error ArgumentError
      end
    end
  end

  describe '#default_proc=' do
    it 'provides the tash and transformed key to the block' do
      tash.default_proc = ->(t, k) { t.is_a?(described_class) && k == :does_not_exist }

      expect(tash[:DOES_NOT_EXIST]).to be true
    end

    it 'sets the proc to what is given (does not ruin comparisons by overwriting it)' do
      prok = ->(t, k) { t.is_a?(described_class) && k == :does_not_exist }
      tash.default_proc = prok

      expect(tash.default_proc).to be prok
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

  describe '#delete_if' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.delete_if).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'deletes the transformed keys that return false from the block' do
        tash[:A] = 1
        tash[:b] = 2
        tash[:c] = 3

        tash.delete_if do |_, v|
          v > 1
        end

        expect(tash).to eql described_class[a: 1]
      end

      it 'returns itself' do
        result = tash.delete_if { false }

        expect(result).to be tash
      end
    end
  end

  describe '#dig' do
    it 'returns the value if the transformed key is found' do
      tash[:Foo] = described_class[Bar: 2, &:downcase]

      expect(tash.dig(:foo, :bar)).to be 2
    end

    it 'returns nil if no transformed key is found' do
      tash[:Foo] = described_class[Bar: 2, &:downcase]

      expect(tash.dig(:foo, :baz)).to be_nil
    end

    it 'calls into other objects that accept dig' do
      tash[:foo] = %i[a b c]

      expect(tash.dig(:foo, 2)).to be :c
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

  describe '#each_key' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.each_key).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'enumerates each key-value pair' do
        tash[:A] = 1
        tash[:b] = 2

        output = []
        tash.each_key do |k|
          output << k
        end

        expect(output).to eql %i[a b]
      end

      it 'returns itself' do
        result = tash.each_key do |k|
          # noop
        end

        expect(result).to be tash
      end
    end
  end

  describe '#each_value' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.each_value).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'enumerates each key-value pair' do
        tash[:A] = 1
        tash[:b] = 2

        output = []
        tash.each_value do |v|
          output << v
        end

        expect(output).to eql [1, 2]
      end

      it 'returns itself' do
        result = tash.each_value do |v|
          # noop
        end

        expect(result).to be tash
      end
    end
  end

  describe '#eql?' do
    it "fails if the object is not a #{described_class}" do
      expect(tash.eql?(1)).to be false
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

      expect(tash1.eql?(tash2)).to be false
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

      expect(tash1.eql?(tash2)).to be false
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

      expect(tash1.eql?(tash2)).to be false
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

      expect(tash1.eql?(tash2)).to be true
    end
  end

  when_ruby_above('2.7') do
    describe '#except' do
      it "removes keys given from the #{described_class} and returns a new one" do
        tash[:A] = 1
        tash[:b] = 2

        result = tash.except(:a)

        expect(result).to be_a_kind_of described_class
        expect(result).to eq described_class[b: 2]
      end
    end
  end

  describe '#fetch' do
    it 'throws an error if passed too many args' do
      expect { tash.fetch(:does_not_exist, 1, 2) }.to raise_error ArgumentError
    end

    context 'without a block' do
      it 'fetches the value for the transformed key' do
        tash[:A] = 1

        expect(tash.fetch(:a)).to be 1
      end

      it 'throws a KeyError if the transformed key does not exist' do
        expect { tash.fetch(:does_not_exist) }.to raise_error KeyError
      end

      context 'with a default_value' do
        it 'returns knows keys' do
          tash[:A] = 1

          expect(tash.fetch(:a, 2)).to be 1
        end

        it 'uses the default_value if the key does not exist' do
          expect(tash.fetch(:does_not_exist, 1)).to be 1
        end
      end
    end

    context 'with a block' do
      it 'provides the transformed key to the block' do
        expect(tash.fetch(:DOES_NOT_EXIST) { |k| k == :does_not_exist }).to be true
      end

      it 'fetches the value for the transformed key' do
        tash[:A] = 1

        expect(tash.fetch(:a) { |k| k }).to be 1
      end

      it 'overrides a default value' do
        expect(tash.fetch(:does_not_exist, 1) { 2 }).to be 2
      end
    end
  end

  describe '#fetch_values' do
    context 'without a block' do
      it 'gets the values for the keys requested' do
        tash[:A] = 1
        tash[:b] = 2

        expect(tash.fetch_values(:A)).to eql [1]
      end
    end

    context 'with a block' do
      it 'provides the transformed key to the block' do
        expect(tash.fetch_values(:DOES_NOT_EXIST) { |k| k == :does_not_exist }).to eql [true]
      end

      it 'gets the values for the keys requested' do
        tash[:A] = 1
        tash[:b] = 2

        expect(tash.fetch_values(:DOES_NOT_EXIST, :A) { 3 }).to eql [3, 1]
      end
    end
  end

  describe '#invert' do
    it 'flips the keys and values while running the values through the transform' do
      tash[:a] = 'A'
      tash[:b] = 'B'

      result = tash.invert

      expect(result).to be_a_kind_of described_class
      expect(result).to eq described_class['a' => :a, 'b' => :b]
    end
  end

  describe '#keep_if' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.keep_if).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'keeps the transformed keys that return true from the block' do
        tash[:A] = 1
        tash[:b] = 2
        tash[:c] = 3

        tash.keep_if do |_, v|
          v > 1
        end

        expect(tash).to eql described_class[b: 2, c: 3]
      end

      it 'returns itself' do
        result = tash.keep_if { true }

        expect(result).to be tash
      end
    end
  end

  describe '#key?' do
    it 'transforms the key' do
      tash[:A] = 1

      expect(tash.key?(:a)).to be true
    end
  end

  describe '#merge' do
    context 'with no arguments' do
      it 'returns a copy of self' do
        tash[:A] = 1
        tash[:b] = 2

        tash2 = tash.merge

        expect(tash2).to eq tash
        expect(tash2).to_not be tash
      end

      it 'copies over the transform strategy' do
        tash[:A] = 1
        tash[:b] = 2

        tash2 = tash.merge
        tash2[:C] = 3

        expect(tash2[:c]).to be 3
      end

      it 'does not execute the block' do
        expect { tash.merge { raise StandardError } }.to_not raise_error StandardError
      end
    end

    context 'without a block' do
      it 'merges all tash and hashes in order' do
        tash[:A] = 0
        tash[:b] = 1
        tash[:C] = 2
        t1 = described_class[d: 3, B: 4]
        h = { E: 5, d: 6 }

        result = tash.merge(t1, h)

        expect(result).to be_a_kind_of described_class
        expect(result).to eq described_class[a: 0, b: 4, c: 2, d: 6, e: 5]
      end
    end

    context 'with a block' do
      it 'handles collisions by calling the block' do
        tash[:A] = 0
        tash[:b] = 1
        tash[:C] = 2
        t1 = described_class[d: 3, B: 4]
        h = { E: 5, d: 6 }

        result = tash.merge(t1, h) { |_, old_v, new_v| old_v + new_v }

        expect(result).to be_a_kind_of described_class
        expect(result).to eq described_class[a: 0, b: 5, c: 2, d: 9, e: 5]
      end

      it 'provides the transformed key to the block' do
        tash[:a] = 1

        expect(tash.merge(A: 2) { |k| k == :a }[:a]).to be true
      end
    end
  end

  describe '#merge!' do
    context 'with no arguments' do
      it 'returns itself' do
        tash2 = tash.merge!

        expect(tash2).to be tash
      end

      it 'does not execute the block' do
        expect { tash.merge! { raise StandardError } }.to_not raise_error StandardError
      end
    end

    context 'without a block' do
      it 'merges all tash and hashes in order' do
        tash[:A] = 0
        tash[:b] = 1
        tash[:C] = 2
        t1 = described_class[d: 3, B: 4]
        h = { E: 5, d: 6 }

        expect(tash.merge!(t1, h)).to be tash
        expect(tash).to eq described_class[a: 0, b: 4, c: 2, d: 6, e: 5]
      end
    end

    context 'with a block' do
      it 'handles collisions by calling the block' do
        tash[:A] = 0
        tash[:b] = 1
        tash[:C] = 2
        t1 = described_class[d: 3, B: 4]
        h = { E: 5, d: 6 }

        expect(tash.merge!(t1, h) { |_, old_v, new_v| old_v + new_v }).to be tash
        expect(tash).to eq described_class[a: 0, b: 5, c: 2, d: 9, e: 5]
      end

      it 'provides the transformed key to the block' do
        tash[:a] = 1

        expect(tash.merge!(A: 2) { |k| k == :a }[:a]).to be true
      end
    end
  end

  describe '#reject' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.reject).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it "select the #{described_class} and returns a new one" do
        tash[:A] = 1
        tash[:b] = 2

        result = tash.reject { |_k, v| v.even? }

        expect(result).to be_a_kind_of described_class
        expect(result).to eq described_class[a: 1]
      end
    end
  end

  describe '#reject!' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.reject!).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'returns nil if no change occurs' do
        expect(tash.reject! { true }).to be_nil
      end

      it "select the #{described_class} and returns a new one" do
        tash[:A] = 1
        tash[:b] = 2

        result = tash.reject! { |_k, v| v.even? }

        expect(result).to be tash
        expect(tash).to eq described_class[a: 1]
      end
    end
  end

  describe '#replace' do
    context 'with a hash' do
      it 'is the same tash' do
        expect(tash.replace({})).to be tash
      end

      it 'replaces the contents' do
        tash[:A] = 1
        tash[:b] = 2
        tash[:c] = 3

        tash.replace({ D: 4, e: 5 })

        expect(tash.size).to be 2
        expect(tash[:d]).to be 4
        expect(tash[:e]).to be 5
      end
    end

    context 'with a tash' do
      it 'is the same tash' do
        expect(tash.replace(described_class.new)).to be tash
      end

      it 'replaces the contents' do
        tash[:A] = 1
        tash[:b] = 2
        tash[:c] = 3

        tash.replace(described_class[D: 4, e: 5])

        expect(tash.size).to be 2
        expect(tash[:D]).to be 4
        expect(tash[:e]).to be 5
      end

      it 'replaces the transform block' do
        tash[:A] = 1
        tash[:b] = 2
        tash[:c] = 3

        tash.replace(described_class[D: 4, e: 5, &:upcase])

        expect(tash.keys).to eql %i[D E]
      end
    end
  end

  describe '#select' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.select).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it "selects key-value pairs from self and returns a new #{described_class}" do
        tash[:A] = 1
        tash[:b] = 2

        result = tash.select { |_k, v| v.even? }

        expect(result).to be_a_kind_of described_class
        expect(result).to eq described_class[b: 2]
      end
    end
  end

  describe '#select!' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.select!).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'returns nil if no change occurs' do
        expect(tash.select! { true }).to be_nil
      end

      it 'selects key-value pairs from self and returns self' do
        tash[:A] = 1
        tash[:b] = 2

        result = tash.select! { |_k, v| v.even? }

        expect(result).to be tash
        expect(tash).to eq described_class[b: 2]
      end
    end
  end

  describe '#slice' do
    it 'returns a new Tash containing the selected keys' do
      tash[:A] = 1
      tash[:b] = 2
      tash[:C] = 3

      result = tash.slice(:B, :c)

      expect(result).to be_a_kind_of described_class
      expect(result).to eq described_class[b: 2, c: 3]
    end
  end

  describe '#to_h' do
    context 'without a block' do
      it 'returns a hash' do
        expect(tash.to_h).to be_a_kind_of Hash
      end

      it 'copies the contents' do
        tash[:A] = 1
        tash[:b] = 2

        expect(tash.to_h).to eql({ a: 1, b: 2 })
      end

      it 'does not return the internal hash' do
        h = tash.to_h
        h[:a] = 1

        expect(tash).to be_empty
      end
    end

    context 'with a block' do
      it 'returns a hash based on the block' do
        tash[:A] = 1
        tash[:b] = 2

        expect(tash.to_h { |k, v| [v, k] }).to eql({ 1 => :a, 2 => :b })
      end

      it 'does not return the internal hash' do
        h = tash.to_h { |k, v| [v, k] }
        h[:c] = 3

        expect(tash).to be_empty
      end
    end
  end

  describe '#to_hash' do
    it 'returns a hash' do
      expect(tash.to_hash).to be_a_kind_of Hash
    end

    it 'copies the contents' do
      tash[:A] = 1
      tash[:b] = 2

      expect(tash.to_hash).to eql({ a: 1, b: 2 })
    end

    it 'does not return the internal hash' do
      h = tash.to_hash
      h[:a] = 1

      expect(tash).to be_empty
    end
  end

  describe '#to_proc' do
    it 'returns a lambda' do
      expect(tash.to_proc).to be_a_kind_of Proc
      expect(tash.to_proc).to be_lambda
    end

    it 'maps a transformed key to its value' do
      tash[:A] = 1
      tash[:b] = 2

      p = tash.to_proc

      expect(p.call(:a)).to be 1
      expect(p.call(:B)).to be 2
      expect(p.call(:c)).to be_nil
    end

    it 'uses the original hash' do
      p = tash.to_proc

      expect(p.call(:a)).to be_nil

      tash[:a] = 1

      expect(p.call(:a)).to be 1
    end
  end

  describe '#transform_proc' do
    it 'returns nil when there is none' do
      expect(described_class.new.transform_proc).to be_nil
    end

    it 'returns the proc when there is one' do
      p = proc { |k| k.to_s }
      tash = described_class.new(&p)

      expect(tash.transform_proc).to be p
    end
  end

  describe '#transform_values' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.transform_values).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it "transforms the values and returns a new #{described_class}" do
        tash[:A] = 1
        tash[:b] = 2

        result = tash.transform_values { |v| v * 100 }

        expect(result).to be_a_kind_of described_class
        expect(result).to eq described_class[a: 100, b: 200]
      end
    end
  end

  describe '#transform_values!' do
    context 'without a block' do
      it 'returns an enumerator' do
        expect(tash.transform_values!).to be_a_kind_of Enumerator
      end
    end

    context 'with a block' do
      it 'transforms the values and returns self' do
        tash[:A] = 1
        tash[:b] = 2

        result = tash.transform_values! { |v| v * 100 }

        expect(result).to be tash
        expect(result).to eq described_class[a: 100, b: 200]
      end
    end
  end

  describe '#values_at' do
    it 'returns a new Tash containing the selected keys' do
      tash[:A] = 1
      tash[:b] = 2
      tash[:C] = 3

      result = tash.values_at(:B, :c, :d)

      expect(result).to eq [2, 3, nil]
    end
  end
end
