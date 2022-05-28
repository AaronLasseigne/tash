# frozen_string_literal: true

require 'forwardable'

require_relative 'tash/version'

# A Tash is a hash with transformed keys.
class Tash
  extend Forwardable
  include Enumerable

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

  def initialize(&transformation)
    @transformation = transformation
    @ir = {} # internal representation - @ir[transformed key] = value
  end

  def_delegators :@ir,
    :<,
    :<=,
    :>,
    :>=,
    :empty?,
    :inspect,
    :keys,
    :length,
    :size,
    :to_hash,
    :values

  def ==(other)
    return false unless other.is_a?(self.class)

    @ir == other.to_hash
  end

  def [](key)
    @ir[transform(key)]
  end

  def clear
    @ir.clear
    self
  end

  def each(&block)
    return to_enum(:each) unless block

    @ir.each(&block)
    self
  end
  alias each_pair each

  def filter(&block)
    return to_enum(:filter) unless block

    filtered_ir = @ir.filter(&block)

    self.class.new(&@transformation).tap { |tash| tash.ir = filtered_ir.dup }
  end
  alias select filter

  def has_key?(key) # rubocop:disable Naming/PredicateName
    @ir.key?(transform(key))
  end
  alias key? has_key?
  alias include? has_key?
  alias member? has_key?

  def store(key, value)
    @ir.store(transform(key), value)
  end
  alias []= store

  protected

  attr_writer :ir

  private

  def transform(key)
    return key unless @transformation

    @transformation.call(key)
  end
end
