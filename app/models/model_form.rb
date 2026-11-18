###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# for making arbitrary "models" for use in forms which may or may not actually be tied to
# any database table (pattern borrowed from Theron)
#
# `attribute` keeps the Virtus declaration style and default semantics descendants rely on.
# A default applies only to an attribute that was never assigned (assigning nil counts), and it
# is written without calling a custom writer. Eager defaults run after mass assignment, so they
# can read assigned values.
class ModelForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  extend  ActiveModel::Naming

  Boolean = Types::Boolean

  AttributeDefault = Struct.new(:value, :lazy)
  private_constant :AttributeDefault

  UNCLONED_DEFAULTS = [NilClass, TrueClass, FalseClass, Numeric, Symbol].freeze
  private_constant :UNCLONED_DEFAULTS

  class_attribute :model_form_defaults, instance_accessor: false, instance_predicate: false, default: {}.freeze

  def self.attribute(name, type = nil, default: nil, lazy: false)
    name = name.to_s
    super(name, Types.lookup(type))
    self.model_form_defaults = model_form_defaults.merge(name => AttributeDefault.new(default, lazy)).freeze
  end

  def initialize(...)
    super
    self.class.model_form_defaults.each do |name, default|
      apply_model_form_default(name, default) unless default.lazy || model_form_assigned?(name)
    end
  end

  # ActiveModel freezes the attribute set, so unresolved lazy defaults are resolved first.
  def freeze
    self.class.model_form_defaults.each do |name, default|
      apply_model_form_default(name, default) if default.lazy && !model_form_assigned?(name)
    end
    super
  end

  # Reader output, keyed by symbol.
  def attributes
    self.class.attribute_names.to_h { |name| [name.to_sym, public_send(name)] }
  end

  def to_h = attributes
  def to_hash = attributes

  # YAML stores assigned attribute values and other instance variables as flat keys, matching
  # documents written when attributes were plain instance variables.
  def encode_with(coder)
    self.class.attribute_names.each do |name|
      coder[name] = @attributes.fetch_value(name) if model_form_assigned?(name)
    end
    (instance_variables - [:@attributes]).each do |ivar|
      coder[ivar.to_s.delete_prefix('@')] = instance_variable_get(ivar)
    end
  end

  def init_with(coder)
    @attributes = self.class._default_attributes.deep_dup
    coder.map.each do |key, value|
      # Skip so a stored key can't replace the attribute set, which encode_with never writes.
      next if key == 'attributes'

      if self.class.attribute_types.key?(key)
        _write_attribute(key, value)
      else
        instance_variable_set("@#{key}", value)
      end
    end
  end

  private

  def attribute(name)
    default = self.class.model_form_defaults[name]
    apply_model_form_default(name, default) if default&.lazy && !model_form_assigned?(name)
    super
  end

  # Keeps respond_to? and method_missing from building #attributes, which calls every reader.
  def attribute_method?(name)
    self.class.attribute_types.key?(name.to_s)
  end

  def model_form_assigned?(name)
    @attributes[name].came_from_user?
  end

  def apply_model_form_default(name, default)
    _write_attribute(name, model_form_default_value(name, default.value))
  end

  def model_form_default_value(name, value)
    if value.respond_to?(:call)
      value.call(self, name)
    elsif value.is_a?(Symbol)
      respond_to_without_attributes?(value, true) ? send(value) : value
    elsif UNCLONED_DEFAULTS.any? { |klass| value.is_a?(klass) }
      value
    else
      value.clone
    end
  end
end
