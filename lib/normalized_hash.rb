# frozen_string_literal: true

require 'forwardable'

require_relative 'normalized_hash/version'

# A Nash is a hash with normalized keys.
class Nash
  class Error < StandardError; end

  extend Forwardable
  include Enumerable

  KEY   = 0
  VALUE = 1
  private_constant :KEY, :VALUE

  def initialize(&block)
    @normalization = block
    @ir = {} # internal representation - @ir[normalized key] = [original key, value]
  end

  def normalize(key)
    @normalization.call(key)
  end

  def_delegators :@ir,
    :clear,
    :length,
    :size

  def ==(other)
    return false unless other.is_a?(self.class)
    return false unless size == other.size

    other.all? do |_k, v, nk|
      @ir.key?(nk) && @ir[nk][VALUE] == v
    end
  end

  def [](key)
    @ir.dig(normalize(key), VALUE)
  end

  def each
    return to_enum(:each) unless block_given?

    @ir.each do |normalized_key, data|
      yield [data[KEY], data[VALUE], normalized_key]
    end
  end
  alias each_pair each

  def filter
    return to_enum(:filter) unless block_given?

    @ir.each.with_object(self.class.new(&@normalization)) do |(normalized_key, data), acc|
      key = data[KEY]
      value = data[VALUE]

      acc[key] = value if yield [key, value, normalized_key]
    end
  end
  alias select filter

  def has_key?(key) # rubocop:disable Naming/PredicateName
    !!@ir.dig(normalize(key), KEY)
  end
  alias key? has_key?
  alias include? has_key?
  alias member? has_key?

  def inspect
    to_hash.to_s
  end

  def keys
    @ir.values.map { |data| data[KEY] }
  end

  def store(key, value)
    @ir[normalize(key)] = [key, value]
    value
  end
  alias []= store

  def to_hash
    @ir.values.to_h
  end

  def values
    @ir.values.map { |data| data[VALUE] }
  end
end
