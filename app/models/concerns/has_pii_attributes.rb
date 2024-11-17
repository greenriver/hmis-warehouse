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

  PII_TYPES = [
    :first_name,
    :last_name,
    :middle_name,
    :age,
    :dob,
    :ssn,
    :geo_street, # street address or route
    :geo_locality, # town, city
    :geo_admin_1, # state, province
    :geo_admin_2, # county, district
    :geo_postal_code,
    :geo_country,
    :free_text, # case notes
    :email,
    :phone,
    :url,
  ].to_set.freeze

  class_methods do
    def pii_attr(attribute, as: nil, required: false)
      # the attribute and type are often the same
      type = (as || attribute.to_s.underscore).to_sym
      raise ArgumentError, "unknown type '#{type}'" unless type.in?(PII_TYPES)

      attribute = attribute.to_sym
      raise "pii attr '#{attribute}' is already defined" if pii_attributes_config.key?(attribute)

      pii_attributes_config[attribute] = [attribute, type, required]
    end

    def has_pii?
      pii_attributes_config.present?
    end
  end
end
