#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class Admin::FormFieldMappingInput < Types::BaseInputObject
    argument :record_type, Forms::Enums::RelatedRecordType, required: false
    argument :field_name, String, required: false
    argument :custom_field_key, String, required: false
  end
end
