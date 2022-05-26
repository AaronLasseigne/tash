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
    @internal = {}
  end

  def normalize(key)
    @normalization.call(key)
  end

  def_delegators :@internal,
    :length,
    :size

  def [](key)
    @internal.dig(normalize(key), VALUE)
  end

  def each
    if block_given?
      @internal.each do |normalized_key, internal_representation|
        yield [internal_representation[KEY], internal_representation[VALUE], normalized_key]
      end
    else
      to_enum(:each)
    end
  end
  alias each_pair each

  def has_key?(key) # rubocop:disable Naming/PredicateName
    !!@internal.dig(normalize(key), KEY)
  end
  alias key? has_key?
  alias include? has_key?
  alias member? has_key?

  def inspect
    to_hash.to_s
  end

  def store(key, value)
    @internal[normalize(key)] = [key, value]
    value
  end
  alias []= store

  def to_hash
    @internal.values.to_h
  end
end
