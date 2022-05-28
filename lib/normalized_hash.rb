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
    return key unless @normalization

    @normalization.call(key)
  end

  def_delegators :@ir,
    :clear,
    :keys,
    :length,
    :size

  def ==(other)
    return false unless other.is_a?(self.class)
    return false unless size == other.size

    other.all? do |k, v|
      @ir.key?(k) && @ir[k][VALUE] == v
    end
  end

  def [](key)
    @ir.dig(normalize(key), VALUE)
  end

  def each
    return to_enum(:each) unless block_given?

    @ir.each do |normalized_key, data|
      yield [normalized_key, data[VALUE], data[KEY]]
    end
  end
  alias each_pair each

  def filter
    return to_enum(:filter) unless block_given?

    filtered_ir = @ir.filter do |normalized_key, data|
      key = data[KEY]
      value = data[VALUE]

      yield [key, value, normalized_key]
    end

    self.class.new(&@normalization).tap { |nash| nash.ir = filtered_ir }
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

  def store(key, value)
    @ir[normalize(key)] = [key, value]
    value
  end
  alias []= store

  def to_hash
    @ir.transform_values { |data| data[VALUE] }
  end

  def values
    @ir.values.map { |data| data[VALUE] }
  end

  protected

  attr_writer :ir
end
