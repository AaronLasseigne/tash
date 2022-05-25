# frozen_string_literal: true

require_relative 'normalized_hash/version'

# A Nash is a hash with normalized keys.
class Nash
  class Error < StandardError; end

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

  def store(key, value)
    @internal[normalize(key)] = [key, value]
    value
  end
  alias []= store

  def [](key)
    @internal.dig(normalize(key), VALUE)
  end

  def to_hash
    @internal.values.to_h
  end

  def inspect
    to_hash.to_s
  end
end
