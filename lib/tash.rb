# frozen_string_literal: true

require 'forwardable'

require_relative 'tash/version'

# A Tash is a hash with transformed keys.
class Tash
  extend Forwardable
  include Enumerable

  # Returns a new Tash object populated with the given objects, if any. If
  # a Tash is passed with no block it returns a duplicate with the
  # transformation code from the original. If a Tash is passed with a block
  # it is treated as a Hash.
  #
  # @param *objects [Array<Objects>] A Tash, Hash, or even number of objects
  #
  # @example Empty
  #   Tash[] # => {}
  #
  # @example Given a Tash with no block
  #   t = Tash[FOO: 1, BAR: 2, &:downcase]
  #   t2 = Tash[t]
  #   t2[:BAZ] = 3
  #   t2 # => {:foo=>1, :bar=>2, :baz=>3}
  #
  # @example Given a Hash
  #   Tash[FOO: 1, BAR: 2, &:downcase] # => {:foo=>1, :bar=>2}
  #
  # @example Given an even number of objects
  #   Tash[:FOO, 1, :BAR, 2, &:downcase] # => {:foo=>1, :bar=>2}
  #
  # @return [Tash]
  def self.[](*objects, &transformation) # rubocop:disable Metrics/PerceivedComplexity
    if objects.empty?
      new(&transformation)
    elsif objects.size == 1 && !transformation && objects.first.is_a?(self)
      objects.first.dup
    elsif objects.size == 1 && objects.first.respond_to?(:to_hash)
      from_hash(objects.first.to_hash, &transformation)
    elsif objects.size.even?
      from_array(objects, &transformation)
    else
      raise ArgumentError, "odd number of arguments for #{name}"
    end
  end

  def self.from_hash(hash, &transformation)
    hash.each_with_object(new(&transformation)) do |(k, v), tash|
      tash[k] = v
    end
  end
  private_class_method :from_hash

  def self.from_array(array, &transformation)
    array.each_slice(2).with_object(new(&transformation)) do |(k, v), tash|
      tash[k] = v
    end
  end
  private_class_method :from_array

  # Returns a new empty Tash object.
  #
  # @param transformation [Proc] receives a key and transforms it as desired
  #   before using the key
  #
  # @example
  #   Tash.new { |key| key.to_s.downcase }
  #
  # @return [Tash]
  def initialize(&transformation)
    @transformation = transformation
    @ir = {} # internal representation - @ir[transformed key] = value
    @default_proc = nil
  end

  def_delegators :@ir,
    :<,
    :<=,
    :>,
    :>=,
    :default=,
    :empty?,
    :inspect,
    :keys,
    :size,
    :to_hash,
    :values

  alias length size

  # @!method < other
  #   Returns `true` if tash is a proper subset of other, `false` otherwise.
  #
  #   @param other [Tash, Hash]
  #
  #   @example
  #     t1 = Tash[foo: 0, bar: 1]
  #     t2 = Tash[foo: 0, bar: 1, baz: 2]
  #     t1 < t2 # => true
  #     t2 < t1 # => false
  #     t1 < t1 # => false
  #
  #   @return [true or false]

  # @!method <= other
  #   Returns `true` if tash is a subset of other, `false` otherwise.
  #
  #   @param other [Tash, Hash]
  #
  #   @example
  #     t1 = Tash[foo: 0, bar: 1]
  #     t2 = Tash[foo: 0, bar: 1, baz: 2]
  #     t1 <= t2 # => true
  #     t2 <= t1 # => false
  #     t1 <= t1 # => true
  #
  #   @return [true or false]

  # Returns `true` if all of the following are true:
  #
  #   * object is a Tash object.
  #   * tash and object have the same keys (regardless of order).
  #   * For each key `key`, `tash[key] == other[key]`.
  #
  # Otherwise, returns `false`.
  #
  # @param other [Tash, Hash]
  #
  # @example
  #   t1 = Tash[foo: 0, bar: 1, baz: 2]
  #   t2 = Tash[foo: 0, bar: 1, baz: 2]
  #   t1 == t2 # => true
  #   h3 = Tash[baz: 2, bar: 1, foo: 0]
  #   t1 == h3 # => true
  #
  # @return [true or false]
  def ==(other)
    return false unless other.is_a?(self.class)

    @ir == other.to_hash
  end

  # @!method > other
  #   Returns `true` if tash is a proper superset of other, `false` otherwise.
  #
  #   @param other [Tash, Hash]
  #
  #   @example
  #     t1 = Tash[foo: 0, bar: 1, baz: 2]
  #     t2 = Tash[foo: 0, bar: 1]
  #     t1 > t2 # => true
  #     t2 > t1 # => false
  #     t1 > t1 # => false
  #
  #   @return [true or false]

  # @!method >= other
  #   Returns `true` if tash is a superset of other, `false` otherwise.
  #
  #   @param other [Tash, Hash]
  #
  #   @example
  #     t1 = Tash[foo: 0, bar: 1, baz: 2]
  #     t2 = Tash[foo: 0, bar: 1]
  #     t1 >= t2 # => true
  #     t2 >= t1 # => false
  #     t1 >= t1 # => true
  #
  #   @return [true or false]

  # Returns the value associated with the given `key` after transformation, if
  # found.
  #
  # @param key [Object]
  #
  # @example
  #   t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #   t[:FOO] # => 0
  #
  # @example Not found key with a default value
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.default = 1_000
  #   t[:nosuch] # => 1_000
  #
  # @return [value]
  def [](key)
    @ir[transform(key)]
  end

  # Associates the given `value` with the given `key` after transformation. If
  # the given post transformation `key` exists, replaces its value with the
  # given `value`; the ordering is not affected. If post transformation `key`
  # does not exist, adds the transformed `key` and `value`; the new entry is
  # last in the order.
  #
  # @param key [Object]
  # @param value [Object]
  #
  # @example
  #   t = Tash[Foo: 0, Bar: 1, &:downcase]
  #   t[:FOO] = 2 # => 2
  #   t.store(:bar, 3) # => 3
  #   t[:Bat] = 4 # => 4
  #   t # => {:foo=>2, :bar=>3, :bat=>4}
  #
  # @return [value]
  def []=(key, value)
    @ir[transform(key)] = value
  end
  alias store []=

  # If the given transformed `key` is found, returns a 2-element Array
  # containing that key and its value. Returns `nil` if the tranformed key
  # `key` is not found.
  #
  # @return [Array<K,V> or nil]
  def assoc(key)
    @ir.assoc(transform(key))
  end

  # Removes all tash entries.
  #
  # @return [self]
  def clear
    @ir.clear
    self
  end

  # Returns a copy of `self` with all `nil`-valued entries removed.
  #
  # @example
  #   t = Tash[foo: 0, bar: nil, baz: 2, bat: nil]
  #   t1 = t.compact
  #   t1 # => {:foo=>0, :baz=>2}
  #
  # @return [Tash]
  def compact
    new_from_self(@ir.compact)
  end

  # Returns `self` with all its `nil`-valued entries removed.
  #
  # @example
  #   t = Tash[foo: 0, bar: nil, baz: 2, bat: nil]
  #   t.compact! # => {:foo=>0, :baz=>2}
  #
  # @return [self or nil]
  def compact!
    self if @ir.compact!
  end

  # @overload default
  # @overload default(key)
  #
  # Returns the default value for the given transformed `key`. The returned
  # value will be determined either by the default proc or by the default
  # value.
  #
  # @param key [Object]
  #
  # @example
  #   t = Tash.new
  #   t.default # => nil
  #
  # @example With a key
  #   t = Tash[Foo: 0]
  #   t.default_proc = proc { |tash, key| tash[k] = "No key #{key}" }
  #   t[:foo] = "Hello"
  #   t.default(:FOO) # => "No key foo"
  #
  # @return [Object]
  def default(*key)
    case key.size
    when 0
      @ir.default
    when 1
      @ir.default(transform(key.first))
    else
      @ir.default(*key)
    end
  end

  # @!method default=
  #   Sets the default value to `value`.
  #
  #   @example
  #     t = Tash.new
  #     t.default # => nil
  #     t.default = false # => false
  #     t.default # => false
  #
  #   @return [Object]

  # Returns the default proc for `self`.
  #
  # @example
  #   t = Tash.new
  #   t.default_proc # => nil
  #   t.default_proc = proc { |tash, key| "Default value for #{key}" }
  #   t.default_proc.class # => Proc
  #
  # @return [Proc or nil]
  def default_proc # rubocop:disable Style/TrivialAccessors (I want it to show as a method in the docs.)
    @default_proc
  end

  # @overload default_proc=(proc)
  #
  # Sets the default proc for `self` to `proc`. The `proc` is provided with the
  # tash and a transformed `key`.
  #
  # @example
  #   t = Tash.new
  #   t.default_proc # => nil
  #   t.default_proc = proc { |tash, key| "Default value for #{key}" }
  #   t.default_proc.class # => Proc
  #   t.default_proc = nil
  #   t.default_proc # => nil
  #
  # @return [Proc]
  def default_proc=(prok)
    @default_proc = prok

    @ir.default_proc = proc { |_, k| prok.call(self, transform(k)) }
  end

  # Deletes the entry for the given transformed `key` and returns its
  # associated value.
  #
  # @param key [Object]
  # @param block [Proc] receives a transformed key
  #
  # @example
  #   t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #   t.delete(:bar) # => 1
  #   t.delete(:bar) # => nil
  #   t # => {:foo=>0, :baz=>2}
  #
  # @example With a block and a `key` found.
  #   t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #   t.delete(:baz) { |key| raise 'Will never happen'} # => 2
  #   t # => {:foo=>0, :bar=>1}
  #
  # @example With a block and no `key` found.
  #   t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #   t.delete(:nosuch) { |key| "Key #{key} not found" } # => "Key nosuch not found"
  #   t # => {:foo=>0, :bar=>1, :baz=>2}
  #
  # @return [value or nil, Object]
  def delete(key, &block)
    @ir.delete(transform(key), &block)
  end

  # Calls the given block with each key-value pair. Returns a new Enumerator if
  # no block is given.
  #
  # @example Without block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.each # => #<Enumerator: {:foo=>0, :bar=>1, :baz=>2}:each>
  #
  # @example With block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.each {|key, value| puts "#{key}: #{value}"}
  #   #=> foo: 0
  #   #=> bar: 1
  #   #=> baz: 2
  #
  # @return [Enumerator, self]
  def each(&block)
    return to_enum(:each) unless block

    @ir.each(&block)
    self
  end
  alias each_pair each

  # @!method empty?
  #   Returns `true` if there are no tash entries, `false` otherwise.
  #
  #   @example
  #     Tash[].empty? # => true
  #     Tash[foo: 0, bar: 1, baz: 2].empty? # => false
  #
  #   @return [true or false]

  # @overload fetch(key)
  # @overload fetch(key, default_value)
  #
  # Returns the value for the given `key`, if found. Raises `KeyError` if
  # neither `default_value` nor a block was given.
  #
  # @note This method does not use the values of either `default` or
  #   `default_proc`.
  #
  # @param key [Object]
  # @param default_value [Object]
  # @param block [Proc] receives a transformed `key`
  #
  # @example
  #   t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #   t.fetch(:bar) # => 1
  #
  # @example With a default
  #   Tash.new.fetch(:nosuch, :default) # => :default
  #
  # @example With a default block
  #   Tash.new.fetch(:NOSUCH) {|key| "No key #{key}"} # => "No key nosuch"
  #
  # @raise [KeyError] When `key` is not found and no default is provided.
  #
  # @return [Object]
  def fetch(key, *default_value, &block)
    @ir.fetch(transform(key), *default_value, &block)
  end

  # @!method inspect
  #   Returns a new String containing the tash entries.
  #
  #   @example
  #     t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #     t.inspect # => "{:foo=>0, :bar=>1, :baz=>2}"
  #
  #   @return [String]

  # Returns `true` if `key` after transformation is a key in `self`, otherwise
  # `false`.
  #
  # @param key [Object]
  #
  # @example
  #   t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #   t.key?(:FOO) # => true
  #   t.key?(:bat) # => false
  #
  # @return [true or false]
  def key?(key)
    @ir.key?(transform(key))
  end
  alias has_key? key?
  alias include? key?
  alias member? key?

  # @!method keys
  #   Returns a new Array containing all keys in `self`.
  #
  #   @example
  #     t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #     t.keys # => [:foo, :bar, :baz]
  #
  #   @return [Array]

  # Returns a new Tash object whose entries are those for which the block
  # returns a truthy value. Returns a new Enumerator if no block given.
  #
  # @example Without block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   e = t.select # => #<Enumerator: {:foo=>0, :bar=>1, :baz=>2}:select>
  #
  # @example With block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.select {|key, value| value < 2 } # => {:foo=>0, :bar=>1}
  #
  # @return [Enumerator, Tash]
  def select(&block)
    return to_enum(:select) unless block

    new_from_self(@ir.select(&block).dup)
  end
  alias filter select

  # @!method size
  #   Returns the count of entries in `self`.
  #
  #   @example
  #     Tash[foo: 0, bar: 1, baz: 2].size # => 3
  #
  #   @return [Integer]

  # @!method to_hash
  #   Returns tash as a Hash.
  #
  #   @return [Hash]

  # @!method values
  #   Returns a new Array containing all values in `self`.
  #
  #   @example
  #     t = Tash[foo: 0, bar: 1, baz: 2]
  #     t.values # => [0, 1, 2]
  #
  #   @return [Array]

  protected

  attr_writer :ir

  private

  def transform(key)
    return key unless @transformation

    @transformation.call(key)
  end

  def new_from_self(new_ir)
    self.class.new(&@transformation).tap { |tash| tash.ir = new_ir }
  end
end
