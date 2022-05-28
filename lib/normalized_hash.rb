# frozen_string_literal: true

require 'forwardable'

require_relative 'normalized_hash/version'

# A Nash is a hash with normalized keys.
class Nash
  class Error < StandardError; end

  extend Forwardable
  include Enumerable

  def self.[](*objects, &normalization) # rubocop:disable Metrics/PerceivedComplexity
    if objects.empty?
      new(&normalization)
    elsif objects.size == 1 && !normalization && objects.first.is_a?(self)
      objects.first.dup
    elsif objects.size == 1 && objects.first.respond_to?(:to_hash)
      from_hash(objects.first.to_hash, &normalization)
    elsif objects.size.even?
      from_array(objects, &normalization)
    else
      raise ArgumentError, "odd number of arguments for #{name}"
    end
  end

  def self.from_hash(hash, &normalization)
    hash.each_with_object(new(&normalization)) do |(k, v), nash|
      nash[k] = v
    end
  end
  private_class_method :from_hash

  def self.from_array(array, &normalization)
    array.each_slice(2).with_object(new(&normalization)) do |(k, v), nash|
      nash[k] = v
    end
  end
  private_class_method :from_array

  def initialize(&normalization)
    @normalization = normalization
    @ir = {} # internal representation - @ir[normalized key] = value
  end

  def_delegators :@ir,
    :empty?,
    :inspect,
    :keys,
    :length,
    :size,
    :to_hash,
    :values

  def ==(other)
    return false unless other.is_a?(self.class)
    return false unless size == other.size

    other.all? do |k, v|
      @ir.key?(k) && @ir[k] == v
    end
  end

  def [](key)
    @ir[normalize(key)]
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

    self.class.new(&@normalization).tap { |nash| nash.ir = filtered_ir.dup }
  end
  alias select filter

  def has_key?(key) # rubocop:disable Naming/PredicateName
    @ir.key?(normalize(key))
  end
  alias key? has_key?
  alias include? has_key?
  alias member? has_key?

  def store(key, value)
    @ir.store(normalize(key), value)
  end
  alias []= store

  protected

  attr_writer :ir

  private

  def normalize(key)
    return key unless @normalization

    @normalization.call(key)
  end
end
