###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::FieldMapping < Types::BaseObject
    field :record_type, Forms::Enums::RelatedRecordType, 'Type of record that this field is tied to', null: true
    field :field_name, String, 'Field name that this field is stored as', null: true
    field :custom_field_key, String, 'Key of CustomDataElement where field is stored', null: true
  end
end
