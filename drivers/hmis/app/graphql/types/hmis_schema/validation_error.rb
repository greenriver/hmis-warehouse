###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ValidationError < Types::BaseObject
    # Resolves an HmisError object

    field :id, String, 'Unique ID for this error', null: true
    field :record_id, ID, 'ID of the AR record this error pertains to', null: true
    field :link_id, String, 'Link ID of form item if this error is linked to a specific item', null: true
    field :attribute, String, null: false
    field :readable_attribute, String, null: true
    field :message, String, null: false
    field :full_message, String, null: false
    field :section, String, null: true
    field :type, HmisSchema::Enums::ValidationType, null: false
    field :severity, HmisSchema::Enums::ValidationSeverity, null: false

    def attribute
      object.attribute.to_s
    end

    def type
      object.type.to_s
    end

    def severity
      object.severity.to_s
    end
  end
end
