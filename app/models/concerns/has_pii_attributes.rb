###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#
# frozen_string_literal: true

# HasPiiAttributes is a concern that provides a declarative interface for models
# to specify which attributes contain Personally Identifiable Information (PII).
# This allows for systematic handling of sensitive data across the application.
#
# Usage:
#   class Client < ApplicationRecord
#     include HasPiiAttributes
#
#     pii_attr :first_name                    # Uses defaults based on field name
#     pii_attr :last_name, required: true     # Cannot be nullified due to constraints
#     pii_attr :notes, as: :free_text        # Specify different PII type than field name
#     pii_attr :zip, as: :geo_postal_code    # Map field to a standard PII type
#   end
#
module HasPiiAttributes
  extend ActiveSupport::Concern

  included do
    # Store PII attribute configurations at the class level
    # This hash maps attribute names to their PII configuration
    class_attribute :pii_attributes_config, default: {}, instance_reader: false
  end

  # Defines the standard PII types and their sensitivity levels
  # Level 1: Direct identifiers that can uniquely identify an individual
  # Level 2: Strong quasi-identifiers that could identify in combination
  # Level 3: Demographic data that could identify in large combinations
  # Level 4: Contextual data that may contain embedded PII
  PII_TYPES = {
    # Level 1 - Direct Identifiers
    # These fields can directly and uniquely identify an individual
    first_name: { level: 1 },
    last_name: { level: 1 },
    middle_name: { level: 1 },
    full_name: { level: 1 },
    ssn: { level: 1 },

    # Level 2 - Strong Quasi-Identifiers
    # These fields can identify individuals when combined with other data
    dob: { level: 2 },
    email: { level: 2 },
    phone: { level: 2 },
    geo_street: { level: 2 },
    geo_postal_code: { level: 2 },

    # Level 3 - Demographic Quasi-Identifiers
    # These fields require more combinations to identify individuals
    age: { level: 3 },
    geo_locality: { level: 3 },    # city/town is less sensitive than street
    geo_admin_1: { level: 3 },     # state/province
    geo_admin_2: { level: 3 },     # county/district

    # Level 4 - Contextual Identifiers
    # These fields may contain embedded PII in unstructured form
    free_text: { level: 4 }, # case notes - sensitivity varies by content
    url: { level: 4 }, # depends on content/context
  }.freeze

  class_methods do
    # Declares an attribute as containing PII and specifies how it should be handled
    #
    # @param attribute [Symbol, String] the name of the database column
    # @param as [Symbol, nil] the type of PII data (defaults to attribute name)
    # @param level [Integer, nil] override the default sensitivity level for this type
    # @param required [Boolean] whether the field must maintain a non-null value
    #
    # @example Declaring a required name field
    #   pii_attr :first_name, required: true
    #
    # @example Declaring an address field with custom sensitivity
    #   pii_attr :address, as: :geo_street, level: 1
    #
    def pii_attr(attribute, as: nil, level: nil, required: false)
      attribute = attribute.to_sym
      # Infer PII type from attribute name if not specified
      type = (as || attribute.to_s.underscore).to_sym
      raise ArgumentError, "unknown pii data type '#{type}'. Valid types are: #{PII_TYPES.keys.join(', ')}" unless PII_TYPES.key?(type)

      level ||= PII_TYPES.dig(type, :level)
      raise ArgumentError, "unknown pii sensitivity level '#{level}'. Must be between 1 and 4" unless level&.between?(1, 4)

      pii_attributes_config[attribute] = {
        name: attribute,
        type: type,
        required: required,
        level: level,
      }
    end

    # Checks if this model has declared any PII attributes
    #
    # @return [Boolean] true if the model has any PII attributes configured
    def stores_pii?
      pii_attributes_config.present?
    end

    def inherited(subclass)
      # Create a deep copy of the parent's configuration for the child class
      subclass.pii_attributes_config = pii_attributes_config.deep_dup
      super
    end
  end
end
