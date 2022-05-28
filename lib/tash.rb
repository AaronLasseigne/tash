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

  def []=(key, value)
    @ir[transform(key)] = value
  end
  alias store []=

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

  def select(&block)
    return to_enum(:select) unless block

    selected_ir = @ir.select(&block)

    self.class.new(&@transformation).tap { |tash| tash.ir = selected_ir.dup }
  end
  alias filter select

  def key?(key)
    @ir.key?(transform(key))
  end
  alias has_key? key?
  alias include? key?
  alias member? key?

  protected

  attr_writer :ir

  private

  def transform(key)
    return key unless @transformation

    @transformation.call(key)
  end
end
