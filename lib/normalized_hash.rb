# frozen_string_literal: true

require 'forwardable'

require_relative 'normalized_hash/version'

# A Nash is a hash with normalized keys.
class Nash
  class Error < StandardError; end

  extend Forwardable
  include Enumerable

  def initialize(&block)
    @normalization = block
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
