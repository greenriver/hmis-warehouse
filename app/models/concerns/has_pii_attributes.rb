
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
    :ssn
  ].to_set.freeze
  class_methods do
    def pii_attr(attribute, type: nil)
      # the attribute and type are often the same
      type ||= attribute.to_s.underscore.to_sym
      raise ArgumentError, "unknown type '#{type}'" unless type.in?(PII_TYPES)

      self.pii_attributes_config[attribute.to_sym] = type
    end
  end


end
