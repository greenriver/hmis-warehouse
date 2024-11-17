###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HasPiiAttributes
  extend ActiveSupport::Concern

  included do
    class_attribute :pii_attributes_config, default: {}, instance_reader: false
  end

  PII_TYPES = {
    # Level 1 - Direct Identifiers
    first_name: { level: 1 },
    last_name: { level: 1 },
    middle_name: { level: 1 },
    full_name: { level: 1 },
    ssn: { level: 1 },

    # Level 2 - Strong Quasi-Identifiers
    dob: { level: 2 },
    email: { level: 2 },
    phone: { level: 2 },
    geo_street: { level: 2 },
    geo_postal_code: { level: 2 },

    # Level 3 - Demographic Quasi-Identifiers
    age: { level: 3 },
    geo_locality: { level: 3 },    # city/town is less sensitive than street
    geo_admin_1: { level: 3 },     # state/province
    geo_admin_2: { level: 3 },     # county/district

    # Level 4 - Contextual Identifiers
    free_text: { level: 4 }, # case notes - sensitivity varies by content
    url: { level: 4 }, # depends on content/context
  }.freeze

  class_methods do
    # declare an attribute as potentially containing PII
    # attribute: is the column name on the table
    # as: type of data, default inferred from field name
    # level: sensitivity level 1-4, where 1 is the most sensitive. Default inferred from type
    # required: can the field be set to nil without breaking the app logic or db constraints
    def pii_attr(attribute, as: nil, level: nil, required: false)
      # the attribute and type are often the same
      type = (as || attribute.to_s.underscore).to_sym
      raise ArgumentError, "unknown pii data type '#{type}'" unless PII_TYPES.key?(type)

      level ||= PII_TYPES.dig(type, :level)
      raise ArgumentError, "unknown pii sensitivity level '#{level}'" unless level&.between?(1, 4)

      # note, classes are sometimes re-evaluated so pii_attr() may invoked multiple times
      attribute = attribute.to_sym
      pii_attributes_config[attribute] = {
        name: attribute,
        type: type,
        required: required,
        level: level,
      }
    end

    def stores_pii?
      pii_attributes_config.present?
    end
  end
end
