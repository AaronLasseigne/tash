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
    :compare_by_identity,
    :default=,
    :empty?,
    :flatten,
    :hash,
    :inspect,
    :keys,
    :size,
    :to_a,
    :to_hash,
    :value?,
    :values

  alias has_value? value?
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
  # @param other [Object]
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

  # Sets `self` to consider only identity in comparing keys; two keys are
  # considered the same only if they are the same object.
  #
  # @example Before being set
  #   s0 = 'x'
  #   s1 = 'x'
  #   t = Tash.new
  #   t.compare_by_identity? # => false
  #   t[s0] = 0
  #   t[s1] = 1
  #   t # => {"x"=>1}
  #
  # @example After being set
  #   t = Tash.new
  #   t.compare_by_identity # => {}
  #   t.compare_by_identity? # => true
  #   t[s0] = 0
  #   t[s1] = 1
  #   t # => {"x"=>0, "x"=>1}
  #
  # @return [self]
  def compare_by_identity
    @ir.compare_by_identity
    self
  end

  # @!method compare_by_identity?
  #   Returns `true` if {#compare_by_identity} has been called, `false`
  #   otherwise.
  #
  #   @return [Boolean]

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

  # If a block given, calls the block with each key-value pair; deletes each
  # entry for which the block returns a truthy value.
  #
  # @param block [Proc] receives a transformed key and value
  #
  # @example Without block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   e = t.delete_if # => #<Enumerator: {:foo=>0, :bar=>1, :baz=>2}:delete_if>
  #   e.each { |key, value| value > 0 } # => {:foo=>0}
  #
  # @example With block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.delete_if { |key, value| value > 0 } # => {:foo=>0}
  #
  # @return [Enumerator, self]
  def delete_if(&block)
    return to_enum(:delete_if) unless block

    @ir.delete_if(&block)
    self
  end

  # Finds and returns the object in nested objects that is specified by
  # transformed `key` and `identifiers`. The nested objects may be instances of
  # various classes. This method will use the default values for keys that are
  # not present.
  #
  # @param key [Object]
  # @param *identifiers [Object]
  #
  # @example Nested Tashes
  #   t = Tash[Foo: Tash[Bar: 2, &:downcase], &:downcase]
  #   t.dig(:foo) # => {:bar=>2}
  #   t.dig(:foo, :bar) # => 2
  #   t.dig(:foo, :bar, :BAZ) # => nil
  #
  # @example Nested Arrays
  #   t = Tash[foo: [:a, :b, :c]]
  #   t.dig(:foo, 2) # => :c
  #
  # @example Default values
  #   t = Tash[foo: Tash[bar: [:a, :b, :c]]]
  #   t.dig(:hello) # => nil
  #   t.default_proc = -> (tash, _key) { tash }
  #   t.dig(:hello, :world) # => t
  #   t.dig(:hello, :world, :foo, :bar, 2) # => :c
  #
  # @return [Object]
  def dig(key, *identifiers)
    @ir.dig(transform(key), *identifiers)
  end

  # Calls the given block with each key-value pair. Returns a new Enumerator if
  # no block is given.
  #
  # @param block [Proc] receives a transformed key and the value
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

  # Calls the given block with each key.
  #
  # @param block [Proc] receives a transformed key
  #
  # @example Without block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.each_key # => #<Enumerator: {:foo=>0, :bar=>1, :baz=>2}:each_key>
  #
  # @example With block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.each_key {|key| puts key}
  #   #=> foo
  #   #=> bar
  #   #=> baz
  #
  # @return [Enumerator, self]
  def each_key(&block)
    return to_enum(:each_key) unless block

    @ir.each_key(&block)
    self
  end

  # Calls the given block with each value.
  #
  # @param block [Proc] receives a value
  #
  # @example Without block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.each_value # => #<Enumerator: {:foo=>0, :bar=>1, :baz=>2}:each_value>
  #
  # @example With block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.each_value {|value| puts value}
  #   #=> 0
  #   #=> 1
  #   #=> 2
  #
  # @return [Enumerator, self]
  def each_value(&block)
    return to_enum(:each_value) unless block

    @ir.each_value(&block)
    self
  end

  # @!method empty?
  #   Returns `true` if there are no tash entries, `false` otherwise.
  #
  #   @example
  #     Tash[].empty? # => true
  #     Tash[foo: 0, bar: 1, baz: 2].empty? # => false
  #
  #   @return [true or false]

  # Returns `true` if all of the following are true:
  #
  #   * object is a Tash object.
  #   * tash and object have the same keys (regardless of order).
  #   * For each key `key`, `tash[key] eql? other[key]`.
  #
  # Otherwise, returns `false`.
  #
  # @param other [Object]
  #
  # @example
  #   t1 = Tash[foo: 0, bar: 1, baz: 2]
  #   t2 = Tash[foo: 0, bar: 1, baz: 2]
  #   t1.eql? t2 # => true
  #   h3 = Tash[baz: 2, bar: 1, foo: 0]
  #   t1.eql? h3 # => true
  #
  # @return [true or false]
  def eql?(other)
    return false unless other.is_a?(self.class)

    @ir.eql?(other.to_hash)
  end

  # Returns a new Tash excluding entries for the given `keys`. Any given keys
  # that are not found are ignored. The transformation proc is copied to the
  # new Tash.
  #
  # @param *keys [Array<Object>]
  #
  # @example
  #   t = Tash[a: 100, b: 200, c: 300]
  #   t.except(:a) #=> {:b=>200, :c=>300}
  #
  # @return [Tash]
  def except(*keys)
    new_from_self(@ir.except(*keys))
  end

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

  # Returns a new Array containing the values associated with the given keys
  # *keys. When a block is given, calls the block with each missing transformed
  # key, treating the block's return value as the value for that key.
  #
  # @param *keys [Array<Object>]
  # @param block [Proc] receives a transformed `key`
  #
  # @example Without a block
  #   t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #   t.fetch_values(:baz, :foo) # => [2, 0]
  #
  # @example With a block
  #   t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #   values = t.fetch_values(:bar, :foo, :bad, :bam) {|key| key.to_s}
  #   values # => [1, 0, "bad", "bam"]
  #
  # @return [Array]
  def fetch_values(*keys, &block)
    @ir.fetch_values(*keys.map { |k| transform(k) }, &block)
  end

  # @!method flatten
  #   Returns a new Array object that is a 1-dimensional flattening of `self`.
  #
  #   @param level [Integer]
  #
  #   @example
  #     t = Tash[foo: 0, bar: [:bat, 3], baz: 2]
  #     t.flatten # => [:foo, 0, :bar, [:bat, 3], :baz, 2]
  #
  #   @example level > 1
  #     t = Tash[foo: 0, bar: [:bat, [:baz, [:bat, ]]]]
  #     t.flatten(1) # => [:foo, 0, :bar, [:bat, [:baz, [:bat]]]]
  #     t.flatten(2) # => [:foo, 0, :bar, :bat, [:baz, [:bat]]]
  #     t.flatten(3) # => [:foo, 0, :bar, :bat, :baz, [:bat]]
  #     t.flatten(4) # => [:foo, 0, :bar, :bat, :baz, :bat]
  #
  #   @example negative levels flatten everything
  #     t = Tash[foo: 0, bar: [:bat, [:baz, [:bat, ]]]]
  #     t.flatten(-1) # => [:foo, 0, :bar, :bat, :baz, :bat]
  #     t.flatten(-2) # => [:foo, 0, :bar, :bat, :baz, :bat]
  #
  #   @example level == 0 is the same as to_a
  #     t = Tash[foo: 0, bar: [:bat, 3], baz: 2]
  #     t.flatten(0) # => [[:foo, 0], [:bar, [:bat, 3]], [:baz, 2]]
  #     t.flatten(0) == t.to_a # => true
  #
  #   @return [Array]

  # @!method hash
  #   Returns the Integer hash-code for the hash. Two Hash objects have the
  #   same hash-code if their content is the same (regardless or order).
  #
  #   @example
  #     t1 = Tash[foo: 0, bar: 1, baz: 2]
  #     t2 = Tash[baz: 2, bar: 1, foo: 0]
  #     t2.hash == t1.hash # => true
  #     t2.eql? h1 # => true
  #
  #   @return [Integer]

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
  #   e.each { |key, value| value < 2 } # => {:foo=>0, :bar=>1}
  #
  # @example With block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.select {|key, value| value < 2 } # => {:foo=>0, :bar=>1}
  #
  # @return [Enumerator, Tash]
  def select(&block)
    return to_enum(:select) unless block

    new_from_self(@ir.select(&block))
  end
  alias filter select

  # Returns `self`, whose entries are those for which the block returns a truthy
  # value. When given a block, it returns `nil` if no entries are removed.
  #
  # @example Without block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   e = t.select! # => #<Enumerator: {:foo=>0, :bar=>1, :baz=>2}:select!>
  #   e.each { |key, value| value < 2 } # => {:foo=>0, :bar=>1}
  #
  # @example With block
  #   t = Tash[foo: 0, bar: 1, baz: 2]
  #   t.select! {|key, value| value < 2 } # => {:foo=>0, :bar=>1}
  #
  # @return [Enumerator, self or nil]
  def select!(&block)
    return to_enum(:select!) unless block

    self if @ir.select!(&block)
  end
  alias filter! select!

  # @!method size
  #   Returns the count of entries in `self`.
  #
  #   @example
  #     Tash[foo: 0, bar: 1, baz: 2].size # => 3
  #
  #   @return [Integer]

  # @!method to_a
  #   Returns a new Array of 2-element Array objects; each nested Array
  #   contains a key-value pair from `self`.
  #
  #   @example
  #     t = Tash[Foo: 0, Bar: 1, Baz: 2, &:downcase]
  #     t.to_a # => [[:foo, 0], [:bar, 1], [:baz, 2]]
  #
  #   @return [Array]

  # @!method to_hash
  #   Returns tash as a Hash.
  #
  #   @return [Hash]

  # Returns the transform proc for `self`.
  #
  # @example
  #   t = Tash.new
  #   t.transform_proc # => nil
  #   t = Tash.new(&:to_s)
  #   t.transform_proc.class # => Proc
  #   t.transform_proc.call(:a) # => "a"
  #
  # @return [Proc or nil]
  def transform_proc
    @transformation
  end

  # @!method value?
  #   Returns `true` if `value` is a value in `self`, otherwise `false`.
  #
  #   @return [Boolean]

  # @!method values
  #   Returns a new Array containing all values in `self`.
  #
  #   @example
  #     t = Tash[foo: 0, bar: 1, baz: 2]
  #     t.values # => [0, 1, 2]
  #
  #   @return [Array]

  # Without this comment, the last entry (i.e. #values) will not show up in the docs.

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
